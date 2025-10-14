# Makefile - Cross-Platform for Python 3.11
# Works on Windows (PowerShell/CMD/Git Bash) and Unix-like systems (Linux/macOS).

# =============================================================================
#  Configuration & Cross-Platform Setup
# =============================================================================

.DEFAULT_GOAL := help

# --- User-Configurable Variables ---
PYTHON ?= python3.11
VENV   ?= .venv

# --- OS Detection for Paths and Commands ---
ifeq ($(OS),Windows_NT)
# Use the Python launcher on Windows
PYTHON         := py -3.11
# Windows settings (PowerShell-safe)
PY_SUFFIX      := .exe
BIN_DIR        := Scripts
ACTIVATE       := $(VENV)\$(BIN_DIR)\activate
NULL_DEVICE    := $$null
RM             := Remove-Item -Force -ErrorAction SilentlyContinue
RMDIR          := Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
SHELL          := powershell.exe
.SHELLFLAGS    := -NoProfile -ExecutionPolicy Bypass -Command
# Reference to environment variables for PowerShell
ENVREF         := $$env:
# Docker volume source for PS (use the .Path of $PWD)
MOUNT_SRC      := "$$PWD.Path"
else
# Unix/Linux/macOS settings
PY_SUFFIX      :=
BIN_DIR        := bin
ACTIVATE       := . $(VENV)/$(BIN_DIR)/activate
NULL_DEVICE    := /dev/null
RM             := rm -f
RMDIR          := rm -rf
SHELL          := /bin/bash
.ONESHELL:
.SHELLFLAGS    := -eu -o pipefail -c
# Reference to environment variables for POSIX sh/bash
ENVREF         := $$
# Docker volume source for POSIX shells
MOUNT_SRC      := "$$(pwd)"
endif

# --- Derived Variables ---
PY_EXE  := $(VENV)/$(BIN_DIR)/python$(PY_SUFFIX)
PIP_EXE := $(VENV)/$(BIN_DIR)/pip$(PY_SUFFIX)

# Docker Config (optional)
DOCKER_IMAGE ?= simple-env:latest
DOCKER_NAME  ?= simple-env
DOCKER_PORT  ?= 8888

.PHONY: help venv install dev update test lint fmt check shell clean distclean \
        clean-venv build-container run-container stop-container remove-container logs \
        check-python check-pyproject python-version

# =============================================================================
#  Helper Scripts (exported env vars; expanded by the shell)
# =============================================================================

export HELP_SCRIPT
define HELP_SCRIPT
import re, sys, io
print('Usage: make <target> [OPTIONS...]\\n')
print('Available targets:\\n')
mf = '$(firstword $(MAKEFILE_LIST))'
with io.open(mf, 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        m = re.match(r'^([a-zA-Z0-9_.-]+):.*?## (.*)$$', line)
        if m:
            target, help_text = m.groups()
            print('  {0:<22} {1}'.format(target, help_text))
endef

export CLEAN_SCRIPT
define CLEAN_SCRIPT
import glob, os, shutil, sys
patterns = ['*.pyc', '*.pyo', '*~', '*.egg-info', '__pycache__', 'build', 'dist', '.mypy_cache', '.pytest_cache', '.ruff_cache']
to_remove = set()
for p in patterns:
    to_remove.update(glob.glob('**/' + p, recursive=True))
for path in sorted(to_remove, key=len, reverse=True):
    try:
        if os.path.isfile(path) or os.path.islink(path):
            os.remove(path)
        elif os.path.isdir(path):
            shutil.rmtree(path)
    except OSError as e:
        print('Error removing {0}: {1}'.format(path, e), file=sys.stderr)
endef

# =============================================================================
#  Core Targets
# =============================================================================

help: ## Show this help message
ifeq ($(OS),Windows_NT)
	@& $(PYTHON) -X utf8 -c "$(ENVREF)HELP_SCRIPT"
else
	@$(PYTHON) -X utf8 -c "$(ENVREF)HELP_SCRIPT"
endif

# --- Local Python Environment ---

# Robust venv creation: handle Windows file locks (python.exe), AV/OneDrive, etc.
ifeq ($(OS),Windows_NT)
$(VENV): check-python
	@echo "Creating virtual environment at $(VENV)…"
	# Kill any running python and hard-delete locked venv (if present)
	@taskkill /F /IM python.exe 2>$$null; Start-Sleep -Milliseconds 300; if (Test-Path '$(VENV)'){ Remove-Item -Recurse -Force '$(VENV)' -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 200 }
	# Create venv with the launcher, then upgrade pip
	@& $(PYTHON) -m venv '$(VENV)'
	@& '$(VENV)\Scripts\python.exe' -m pip install --upgrade pip
	@& '$(VENV)\Scripts\python.exe' -V | % { "✅ Created $(VENV) with $$_" }
else
$(VENV): check-python
	@echo "Creating virtual environment at $(VENV)…"
	@$(PYTHON) -m venv --clear "$(VENV)" || { rm -rf "$(VENV)"; $(PYTHON) -m venv "$(VENV)"; }
	@"$(VENV)/bin/python" -m pip install --upgrade pip
	@echo "✅ Created $(VENV) with $$("$(VENV)/bin/python" -V)"
endif

venv: $(VENV) ## Create the virtual environment if it does not exist

install: venv check-pyproject ## Install project in non-editable mode
	@$(PIP_EXE) install .
	@echo "✅ Installed project into $(VENV)"

dev: venv check-pyproject ## Install project in editable mode with dev dependencies
	@$(PIP_EXE) install -e ".[dev]"
	@echo "✅ Dev environment ready in $(VENV)"

update: venv check-pyproject ## Upgrade project and its dependencies
	@$(PIP_EXE) install --upgrade -e ".[dev]"
	@echo "✅ Project and dependencies upgraded"

# --- Development & QA ---

test: venv ## Run tests with pytest
	@echo "🧪 Running tests..."
	@$(PY_EXE) -m pytest

lint: venv ## Check code style with ruff
	@echo "🔍 Linting with ruff..."
	@$(PY_EXE) -m ruff check .

fmt: venv ## Format code with ruff
	@echo "🎨 Formatting with ruff..."
	@$(PY_EXE) -m ruff format .

check: lint test ## Run all checks (linting and testing)

# --- Docker (optional helpers) ---

build-container: check-pyproject ## Build the Docker image
	@echo "Building image '$(DOCKER_IMAGE)'..."
	@docker build -t $(DOCKER_IMAGE) .

ifeq ($(OS),Windows_NT)
run-container: ## Run or restart the container in detached mode
	@docker run -d --name $(DOCKER_NAME) -p $(DOCKER_PORT):8888 -v $(MOUNT_SRC):/workspace $(DOCKER_IMAGE) > $(NULL_DEVICE) 2> $(NULL_DEVICE); if ($$LASTEXITCODE -ne 0) { docker start $(DOCKER_NAME) > $(NULL_DEVICE) 2> $(NULL_DEVICE) }
	@echo "Container is up at http://localhost:$(DOCKER_PORT)"

stop-container: ## Stop the running container
	@docker stop $(DOCKER_NAME) > $(NULL_DEVICE) 2> $(NULL_DEVICE); if ($$LASTEXITCODE -ne 0) { echo "Info: container was not running." }

remove-container: stop-container ## Stop and remove the container
	@docker rm $(DOCKER_NAME) > $(NULL_DEVICE) 2> $(NULL_DEVICE); if ($$LASTEXITCODE -ne 0) { echo "Info: container did not exist." }
else
run-container: ## Run or restart the container in detached mode
	@docker run -d --name $(DOCKER_NAME) -p $(DOCKER_PORT):8888 -v $(MOUNT_SRC):/workspace $(DOCKER_IMAGE) > $(NULL_DEVICE) || docker start $(DOCKER_NAME)
	@echo "Container is up at http://localhost:$(DOCKER_PORT)"

stop-container: ## Stop the running container
	@docker stop $(DOCKER_NAME) >$(NULL_DEVICE) 2>&1 || echo "Info: container was not running."

remove-container: stop-container ## Stop and remove the container
	@docker rm $(DOCKER_NAME) >$(NULL_DEVICE) 2>&1 || echo "Info: container did not exist."
endif

logs: ## View the container logs (Ctrl-C to exit)
	@docker logs -f $(DOCKER_NAME)

# --- Utility ---

python-version: check-python ## Show resolved Python interpreter and version
ifeq ($(OS),Windows_NT)
	@echo "Using: $(PYTHON)"
	@& $(PYTHON) -V
else
	@echo "Using: $(PYTHON)"
	@$(PYTHON) -V
endif

shell: venv ## Show how to activate the virtual environment shell
	@echo "Virtual environment is ready."
	@echo "To activate it, run:"
	@echo "  On Windows (CMD/PowerShell): .\\$(subst /,\,$(ACTIVATE))"
	@echo "  On Unix (Linux/macOS/Git Bash): $(ACTIVATE)"

clean-venv: ## Force-remove the venv (kills python.exe on Windows)
ifeq ($(OS),Windows_NT)
	@taskkill /F /IM python.exe 2>$$null; Start-Sleep -Milliseconds 300; if (Test-Path '.venv'){ Remove-Item -Recurse -Force '.venv' }
else
	@rm -rf .venv
endif

clean: ## Remove Python artifacts, caches, and the virtualenv
	@echo "Cleaning project..."
	-$(RMDIR) $(VENV)
	-$(RMDIR) .pytest_cache
	-$(RMDIR) .ruff_cache
ifeq ($(OS),Windows_NT)
	@& $(PYTHON) -c "$(ENVREF)CLEAN_SCRIPT"
else
	@$(PYTHON) -c "$(ENVREF)CLEAN_SCRIPT"
endif
	@echo "Clean complete."

distclean: clean ## Alias for clean

# =============================================================================
#  Internal Helper Targets
# =============================================================================

ifeq ($(OS),Windows_NT)
check-python:
	@echo "Checking for a Python 3.11 interpreter..."
	@& $(PYTHON) -c "import sys; sys.exit(0 if sys.version_info[:2]==(3,11) else 1)" 2> $(NULL_DEVICE); if ($$LASTEXITCODE -ne 0) { \
		echo "Error: '$(PYTHON)' is not Python 3.11."; \
		echo "Please install Python 3.11 and add it to your PATH,"; \
		echo 'or specify the command via make install PYTHON=\"py -3.11\"'; \
		exit 1; \
	}
	@echo "Found Python 3.11:"
	@& $(PYTHON) -V

check-pyproject:
	@& $(PYTHON) -c "import os,sys; sys.exit(0 if os.path.exists('pyproject.toml') else 1)" 2> $(NULL_DEVICE); if ($$LASTEXITCODE -ne 0) { \
		echo "Error: pyproject.toml not found in this directory."; \
		exit 1; \
	}
else
check-python:
	@echo "Checking for a Python 3.11 interpreter..."
	@$(PYTHON) -c "import sys; sys.exit(0 if sys.version_info[:2]==(3,11) else 1)" 2>$(NULL_DEVICE) || ( \
		echo "Error: '$(PYTHON)' is not Python 3.11."; \
		echo "Please install Python 3.11 and add it to your PATH,"; \
		echo 'or specify the command via make install PYTHON=\"py -3.11\"'; \
		exit 1; \
	)
	@echo "Found Python 3.11:"
	@$(PYTHON) -V

check-pyproject:
	@$(PYTHON) -c "import os,sys; sys.exit(0 if os.path.exists('pyproject.toml') else 1)" || ( \
		echo "Error: pyproject.toml not found in this directory."; \
		exit 1; \
	)
endif