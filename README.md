# Simple Environment (Python 3.11)

This repository provides a minimal, reproducible Python **3.11** environment using `pyproject.toml`, a `Makefile`, and **Docker**. It's designed for running a Jupyter Notebook server either locally in a virtual environment or within an isolated container.

## What you get

  * A choice between a local virtual environment (`.venv`) or a Dockerized setup.
  * Dependencies managed by `pyproject.toml` (Jupyter Notebook and `ipykernel`).
  * A powerful `Makefile` with targets for installation, development, testing, and container management.
  * Cross-platform instructions for a seamless experience on macOS, Linux, and Windows.
![](assets/2025-10-13-18-55-21.png)
-----

## Prerequisites

You have two main options for running this project. Choose one.

1.  **For Local Development:**

      * **Python 3.11**
      * **GNU Make** (`make` or `gmake`)
      * A POSIX shell like **bash** (use Git Bash on Windows).

2.  **For Docker (Recommended):**

      * **Docker Desktop** (macOS, Windows) or **Docker Engine** (Linux).
      * **GNU Make** (optional, but recommended for using the Makefile shortcuts).

> See the **OS Setup** section below for detailed installation instructions for the local environment.

-----

## 🐳 Option 1: Docker Quick Start (Recommended)

Using Docker is the easiest way to get started, as it requires no local Python installation and guarantees a consistent environment.

1.  **Build the Docker Image**
    This command packages the Python environment and all dependencies into a self-contained image named `simple-env:latest`.

    ```bash
    make build-container
    ```

2.  **Run the Jupyter Container**
    This starts the container in the background, maps port `8888` to your machine, and mounts the current project directory into the container's `/workspace` folder.

    ```bash
    make run-container
    ```

3.  **Access Jupyter Notebook**
    Open your browser and navigate to the URL provided in the output:
    🔗 **http://localhost:8888**

    Any notebooks you create or modify will be saved directly in your local project folder.

### Common Docker Tasks

The `Makefile` provides several commands to manage the container's lifecycle:

  * `make build-container`: Build or rebuild the Docker image.
  * `make run-container`: Start or restart the container.
  * `make logs`: View live logs from the Jupyter server (press `Ctrl-C` to exit).
  * `make stop-container`: Stop the container without removing it.
  * `make remove-container`: Stop and permanently remove the container.

-----

## 🐍 Option 2: Local Environment Quick Start

Use this method if you prefer to manage a Python virtual environment directly on your host machine.

1.  **Create the Virtual Environment and Install Dependencies**
    This command creates a `.venv` folder and installs the packages from `pyproject.toml`.

    ```bash
    make install
    ```

    > **Note:** On macOS with Homebrew, use `gmake install`. On Windows with Git Bash, use `make install PYTHON="py -3.11"`.

2.  **Activate the Environment and Launch Jupyter**

    ```bash
    # Activate on macOS/Linux
    source .venv/bin/activate

    # Activate on Windows (Git Bash)
    source .venv/Scripts/activate

    # Launch the notebook server
    jupyter notebook
    ```

### Common Local Tasks

  * `make dev`: Install in editable mode with development dependencies.
  * `make update`: Upgrade all project dependencies.
  * `make shell`: Open a new shell with the virtual environment activated.
  * `make test`, `make lint`, `make fmt`: Run quality checks (if tools are installed via `make dev`).
  * `make clean`: Remove build artifacts and the `.venv` directory.

-----

## Project Files

### `pyproject.toml`

This file defines the project metadata and its core dependencies.

```toml
[build-system]
requires = ["setuptools>=64", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "simple-environment"
version = "0.1.0"
description = "Minimal environment for Jupyter Notebook (Python 3.11)."
requires-python = ">=3.11,<3.12"
dependencies = [
  "notebook",
  "ipykernel"
]
```

### `Dockerfile`

This file defines the steps to build the containerized environment.

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app
COPY . .
RUN python -m pip install --upgrade pip && pip install .

WORKDIR /workspace
EXPOSE 8888

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root", "--NotebookApp.token="]
```

-----

## OS Setup (for Local Environment)

\<details\>
\<summary\>Click to expand OS-specific setup instructions\</summary\>

### macOS

1.  **Install Homebrew, GNU Make, and Python 3.11**

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install make python@3.11
    ```

    Homebrew installs GNU Make as `gmake`. You must either call `gmake` explicitly or create an alias:

    ```bash
    echo 'alias make="gmake"' >> ~/.zshrc && exec zsh
    ```

2.  **Verify**

    ```bash
    gmake --version
    python3.11 --version
    ```

### Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y make python3.11 python3.11-venv
make --version
python3.11 --version
```

### Windows

1.  **Install Git for Windows** (provides Git Bash): [https://git-scm.com/download/win](https://git-scm.com/download/win)

2.  **Install Python 3.11**: [https://www.python.org/downloads/windows/](https://www.python.org/downloads/windows/) (ensure you add it to PATH).

3.  **Install GNU Make** (using an Admin PowerShell):

      * With **Scoop** (recommended): `irm get.scoop.sh | iex` then `scoop install make`
      * Or with **Chocolatey**: `choco install make`

4.  **Run all `make` commands inside Git Bash.** You may need to specify the Python executable:

    ```bash
    make install PYTHON="py -3.11"
    ```

\</details\>

-----

## Troubleshooting

  * **`make: command not found`**: Install GNU Make. On macOS, use `gmake` or create an alias.
  * **Jupyter can’t see the kernel (local setup)**: Ensure you've activated the virtual environment (`source .venv/bin/activate`) before running `jupyter notebook`.
  * **Permission Denied (Docker on Linux)**: You may need to run Docker commands with `sudo` or [add your user to the `docker` group](https://www.google.com/search?q=%5Bhttps://docs.docker.com/engine/install/linux-postinstall/%5D\(https://docs.docker.com/engine/install/linux-postinstall/\)).

-----

## Uninstall / Reset

  * **Local Environment**:
    ```bash
    make clean
    ```
  * **Docker Environment**:
    ```bash
    make remove-container
    ```