# Makefile — Python 3.11 & Docker

# ====================================================================================
#  Configuration
# ====================================================================================

SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# Local Python Environment Config
PYTHON ?= python3.11
VENV   ?= .venv

# Docker Config
DOCKER_IMAGE ?= simple-env:latest
DOCKER_NAME  ?= simple-env
DOCKER_PORT  ?= 8888

# Internal variables
BIN := $(VENV)/bin
PY  := $(BIN)/python
PIP := $(BIN)/pip

# Declare all targets as .PHONY to avoid conflicts with file names
.PHONY: help venv install dev update test lint fmt check shell clean distclean \
        build-container run-container stop-container remove-container logs \
        check-python check-pyproject

# ====================================================================================
#  Core Targets
# ====================================================================================

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_.-]+:.*?## / {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- Local Python Environment ---

$(VENV): check-python
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	@echo "✅ Created $(VENV) with $$($(PY) -V)"

venv: $(VENV) ## Ensure the virtualenv exists (alias)

install: venv check-pyproject ## Install project in non-editable mode
	$(PIP) install .
	@echo "✅ Installed project into $(VENV)"

dev: venv check-pyproject ## Install project in editable mode with dev dependencies
	$(PIP) install -e ".[dev]"
	@echo "✅ Dev environment ready in $(VENV)"

update: venv check-pyproject ## Upgrade project and its dependencies
	if $(PIP) list -e | grep -q -e "^$(shell basename `pwd`)"; then \
		echo "Project is in editable mode, upgrading..."; \
		$(PIP) install --upgrade -e ".[dev]"; \
	else \
		echo "Project is in standard mode, upgrading..."; \
		$(PIP) install --upgrade .; \
	fi
	@echo "✅ Project and dependencies upgraded"

# --- Development & QA ---

test: venv ## Run tests with pytest
	@if ! command -v $(BIN)/pytest &> /dev/null; then \
		echo "ℹ️ pytest not found. Skipping tests. (Install with 'make dev')"; exit 0; \
	fi
	echo "🧪 Running tests..."
	$(BIN)/pytest

lint: venv ## Check code style with ruff
	@if ! command -v $(BIN)/ruff &> /dev/null; then \
		echo "ℹ️ ruff not found. Skipping linting. (Install with 'make dev')"; exit 0; \
	fi
	echo "🔍 Linting with ruff..."
	$(BIN)/ruff check .

fmt: venv ## Format code with ruff and black
	@if command -v $(BIN)/ruff &> /dev/null; then \
		echo "🎨 Formatting with ruff..."; \
		$(BIN)/ruff format .; \
	fi
	@if command -v $(BIN)/black &> /dev/null; then \
		echo "🎨 Formatting with black..."; \
		$(BIN)/black .; \
	fi

check: lint test ## Run all checks (linting and testing)

# --- Docker ---

build-container: check-pyproject ## 🐳 Build the Docker image
	@echo "Building image '$(DOCKER_IMAGE)'..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "✅ Image '$(DOCKER_IMAGE)' built successfully."

run-container: ## 🚀 Run or restart the container in detached mode
	@echo "Checking container '$(DOCKER_NAME)'..."
	@if docker ps --format '{{.Names}}' | grep -q '^$(DOCKER_NAME)$$'; then \
		echo "ℹ️ Container is already running."; \
	elif docker ps -a --format '{{.Names}}' | grep -q '^$(DOCKER_NAME)$$'; then \
		echo "✅ Restarting existing container..."; \
		docker start $(DOCKER_NAME) > /dev/null; \
	else \
		echo "✅ Creating and starting new container..."; \
		docker run -d \
			--name $(DOCKER_NAME) \
			-p $(DOCKER_PORT):8888 \
			-v "$$(pwd):/workspace" \
			$(DOCKER_IMAGE) > /dev/null; \
	fi
	@echo "🚀 Container is up."
	@echo "🔗 Open Jupyter at: http://localhost:$(DOCKER_PORT)"

stop-container: ## 🛑 Stop the running container
	@echo "Stopping container '$(DOCKER_NAME)'..."
	@docker stop $(DOCKER_NAME) >/dev/null || echo "ℹ️ Container was not running."
	@echo "✅ Container stopped."

remove-container: ## 🔥 Stop and remove the container
	@echo "Removing container '$(DOCKER_NAME)'..."
	@docker rm -f $(DOCKER_NAME) >/dev/null || echo "ℹ️ Container did not exist."
	@echo "✅ Container removed."

logs: ## 📝 View the container's logs (Ctrl-C to exit)
	@echo "Following logs for '$(DOCKER_NAME)'. Press Ctrl-C to exit."
	@docker logs -f $(DOCKER_NAME)

# --- Utility ---

shell: venv ## Open an interactive shell in the virtualenv
	@echo "🐍 Entering venv shell. Type 'exit' to leave."
	@bash --noprofile --norc -i -c "source $(VENV)/bin/activate && exec bash -i"

clean: ## Remove Python build artifacts, caches, AND the virtualenv
	@echo "🧹 Cleaning artifacts and removing $(VENV)..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@rm -rf .pytest_cache .ruff_cache .mypy_cache build dist *.egg-info
	@rm -rf $(VENV)
	@echo "🔥 Removed $(VENV) environment."

distclean: clean ## Alias for compatibility (clean already removes .venv)
	@true

# ====================================================================================
#  Internal Helper Targets
# ====================================================================================

check-python:
	@command -v $(PYTHON) >/dev/null 2>&1 || { \
		echo "❌ $(PYTHON) not found. Install it or override, e.g., 'make PYTHON=/path/to/python'"; \
		exit 1; }

check-pyproject:
	@test -f pyproject.toml || { echo "❌ pyproject.toml not found in this directory."; exit 1; }