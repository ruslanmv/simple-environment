# Makefile — Python 3.11 env from pyproject.toml

# ====================================================================================
#  Configuration
# ====================================================================================

# Use bash for all recipes.
SHELL := /bin/bash

# .ONESHELL: ensures all lines in a recipe are executed in a single shell instance.
# -e: exit immediately if a command fails.
# -u: treat unset variables as an error.
# -o pipefail: fail a pipeline if any command in it fails.
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# ?= allows overriding from the command line, e.g., `make dev PYTHON=python3.12`
PYTHON ?= python3.11
VENV   ?= .venv

# Internal variables
BIN := $(VENV)/bin
PY  := $(BIN)/python
PIP := $(BIN)/pip

# Define all targets that are not files.
.PHONY: help check-python check-pyproject venv install dev update test lint fmt check shell clean distclean


# ====================================================================================
#  Core Targets
# ====================================================================================

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_.-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# This target uses the filesystem to avoid re-creating the venv if it exists.
$(VENV): check-python ## Create a virtualenv if it doesn't exist
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	@echo "✅ Created $(VENV) with $$($(PY) -V) and upgraded pip"

venv: $(VENV) ## Ensure the virtualenv exists (alias for the above)

install: venv check-pyproject ## Install project in non-editable mode
	$(PIP) install .
	@echo "✅ Installed project into $(VENV)"

dev: venv check-pyproject ## Install project in editable mode with dev dependencies
	$(PIP) install -e ".[dev]"
	@echo "✅ Dev environment ready in $(VENV)"

update: venv check-pyproject ## Upgrade project and its dependencies
	# Use -e for dev installs, otherwise standard install
	if $(PIP) list -e | grep -q -e "^$(shell basename `pwd`)"; then \
		echo "Project is in editable mode, upgrading with '-e .[dev]'..."; \
		$(PIP) install --upgrade -e ".[dev]"; \
	else \
		echo "Project is in standard mode, upgrading with '.'..."; \
		$(PIP) install --upgrade .; \
	fi
	@echo "✅ Project and dependencies upgraded"


# ====================================================================================
#  Development & QA Targets
# ====================================================================================

test: venv ## Run tests with pytest
	@if ! command -v $(BIN)/pytest &> /dev/null; then \
		echo "ℹ️ pytest not found. Skipping tests. (Install with dev dependencies)"; exit 0; \
	fi
	echo "🧪 Running tests..."
	$(BIN)/pytest

lint: venv ## Check code style with ruff
	@if ! command -v $(BIN)/ruff &> /dev/null; then \
		echo "ℹ️ ruff not found. Skipping linting. (Install with dev dependencies)"; exit 0; \
	fi
	echo "🔍 Linting with ruff..."
	$(BIN)/ruff check .

fmt: venv ## Format code with ruff and black
	@if command -v $(BIN)/ruff &> /dev/null; then \
		echo "🎨 Formatting with ruff..."; \
		$(BIN)/ruff format .; \
	else \
		echo "ℹ️ ruff not found, skipping."; \
	fi
	@if command -v $(BIN)/black &> /dev/null; then \
		echo "🎨 Formatting with black..."; \
		$(BIN)/black .; \
	else \
		echo "ℹ️ black not found, skipping."; \
	fi

check: lint test ## Run all checks (linting and testing)


# ====================================================================================
#  Utility Targets
# ====================================================================================

shell: venv ## Open an interactive shell in the virtualenv
	@echo "🐍 Entering venv shell. Type 'exit' to leave."
	@# 'exec' replaces the make process with a new shell, which is cleaner than nesting.
	@bash --noprofile --norc -i -c "source $(VENV)/bin/activate && exec bash -i"

clean: ## Remove Python build artifacts and cache
	@echo "🧹 Cleaning artifacts..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@rm -rf .pytest_cache .ruff_cache .mypy_cache build dist *.egg-info

distclean: clean ## Remove all artifacts AND the virtualenv
	@rm -rf $(VENV)
	@echo "🔥 Removed $(VENV) environment."


# ====================================================================================
#  Internal Helper Targets
# ====================================================================================

check-python:
	@command -v $(PYTHON) >/dev/null 2>&1 || { \
		echo "❌ $(PYTHON) not found. Install it or override, e.g., 'make PYTHON=/path/to/python'"; \
		exit 1; }

check-pyproject:
	@test -f pyproject.toml || { echo "❌ pyproject.toml not found in this directory."; exit 1; }