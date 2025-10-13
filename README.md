
# Simple Environment (Python 3.11)

This repo sets up a minimal Python **3.11** environment using `pyproject.toml` and a **Makefile**. It installs:

* Jupyter Notebook (`notebook`)
* `ipykernel` (so the virtualenv shows up as a kernel)

## What you get

* A local virtual environment at `.venv`
* Dependencies installed from `pyproject.toml`
* Handy `make` targets for install, dev, test, lint, format, shell, and cleanup
* Cross-platform instructions (Windows, macOS, Linux)

---

## Prerequisites

You’ll need:

* **Python 3.11**
* **GNU Make ≥ 4.0**
* A POSIX shell (**bash**) — on Windows, use **Git Bash** or **MSYS2**.

> If you don’t have these yet, see the OS-specific setup below.

---

## Project files

### `pyproject.toml`

```toml
[build-system]
requires = ["setuptools>=64", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "simple-notebook-env"
version = "0.1.0"
description = "Minimal environment for Jupyter Notebook (Python 3.11)."
requires-python = ">=3.11,<3.12"
dependencies = [
  "notebook",
  "ipykernel"
]
```



---

## OS setup

### macOS

1. **Install GNU Make and Python 3.11**

   ```bash
   # Homebrew (recommended)
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install make python@3.11
   ```

   Homebrew installs GNU make as `gmake`. Either call `gmake` explicitly or alias it:

   ```bash
   echo 'alias make="gmake"' >> ~/.zshrc
   exec zsh
   ```

2. **Verify**

   ```bash
   gmake --version
   python3.11 --version
   ```

### Linux (Debian/Ubuntu example)

```bash
sudo apt update
sudo apt install -y make python3.11 python3.11-venv
make --version
python3.11 --version
```

> On Fedora/RHEL: `sudo dnf install make python3.11 python3.11-venv`
> On Arch: `sudo pacman -S make python` (ensure Python is 3.11 or install 3.11 specifically).

### Windows

Use **Git Bash** + **GNU Make**.

1. **Install Git for Windows** (includes Git Bash).

   * [https://git-scm.com/download/win](https://git-scm.com/download/win)

2. **Install GNU Make**

   * With **Scoop** (recommended):
     In **PowerShell** (Run as Admin):

     ```powershell
     Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
     irm get.scoop.sh | iex
     scoop install make
     ```
   * Or with **Chocolatey** (Admin PowerShell):

     ```powershell
     choco install make
     ```
   * Or via **MSYS2** (then use its MSYS2/MINGW64 shell):

     ```bash
     pacman -S --needed base-devel
     ```

3. **Install Python 3.11**

   * Easiest: **winget**

     ```powershell
     winget install --id Python.Python.3.11 -e
     ```
   * Or download from [https://www.python.org/downloads/windows/](https://www.python.org/downloads/windows/)

4. **Run commands in *Git Bash***

   * Verify:

     ```bash
     make --version
     py --version
     ```
   * When invoking the Makefile, pass the `py` launcher to ensure Python 3.11:

     ```bash
     make install PYTHON="py -3.11"
     # or
     make dev PYTHON="py -3.11"
     ```

---

## Quick start

```bash
# 1) Put pyproject.toml and the Makefile at the repo root.

# 2) Create & install (non-editable)
make install
# On macOS with Homebrew make:
gmake install
# On Windows (Git Bash):
make install PYTHON="py -3.11"

# 3) Launch Jupyter Notebook from the venv
. .venv/bin/activate        # Windows (Git Bash): source .venv/Scripts/activate
jupyter notebook
```

> Optional: register the kernel with a friendly name:
>
> ```bash
> python -m ipykernel install --user --name simple-notebook-env --display-name "Python 3.11 (simple)"
> ```

---

## Common tasks

* **Editable dev install (plus extras if you add them):**

  ```bash
  make dev
  ```
* **Upgrade deps with a fresh resolve:**

  ```bash
  make update
  ```
* **Open a shell inside the venv:**

  ```bash
  make shell
  ```
* **Run tests/linters/formatters** (only if installed):

  ```bash
  make test
  make lint
  make fmt
  ```
* **Clean build artifacts and remove the venv:**

  ```bash
  make clean
  make distclean
  ```

---

## Troubleshooting

* **`make: command not found`**

  * Install GNU Make (see OS setup above). On macOS, run `gmake` or alias `make=gmake`.

* **`❌ Could not find 'py' on PATH` (Windows)**

  * Reopen Git Bash, or pass a full path to `python.exe`:

    ```bash
    make install PYTHON="/c/Users/<you>/AppData/Local/Programs/Python/Python311/python.exe"
    ```

* **Jupyter can’t see the kernel**

  * Ensure `ipykernel` is installed (it is in `pyproject.toml`), then:

    ```bash
    . .venv/bin/activate
    python -m ipykernel install --user --name simple-notebook-env --display-name "Python 3.11 (simple)"
    ```

* **macOS uses the system `make`**

  * Use `gmake install` (Homebrew’s GNU Make) or alias `make` to `gmake`.

---

## Uninstall / Reset

```bash
make distclean
```

This removes `.venv` and build caches. Your project files remain.
