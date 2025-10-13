# syntax=docker/dockerfile:1
FROM python:3.11-slim

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# Set the working directory for the application installation
WORKDIR /opt/app

# Copy the entire project context into the image
# This is crucial for `pip install .` to work correctly.
COPY . .

# Install Python dependencies from your pyproject.toml
RUN python -m pip install --upgrade pip \
 && pip install .

# Set the default working directory for the user
WORKDIR /workspace
EXPOSE 8888

# Run Jupyter Notebook. Correctly formatted to disable token authentication.
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root", "--NotebookApp.token="]