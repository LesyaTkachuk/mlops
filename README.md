# mlops

Repository for managing MLOps processes associated with deploying machine learning models.

# 1. Bash Script for Environment Setup

A Bash script `install_dev_tools.sh` that automates the setup of the environment for DevOps and ML development:

- Checks if the following are installed: Docker, Docker Compose, Python ≥ 3.9, pip, Django, torch, torchvision, pillow
- If missing, installs:
  - Docker and Docker Compose
  - Python (via apt or pyenv if the system version is older)
  - pip
  - Libraries: torch, torchvision, pillow

## Run:

```
chmod +x install_dev_tools.sh
```

default: local .venv

```
./install_dev_tools.sh
```

or: build a docker image with the deps

```
./install_dev_tools.sh --docker
```

# 2. Containerization of the ML Service

## Download the Model

Download the model if it is not already present in the file `model.pt`:

```
python3 export_model.py
```

## Build two Docker images — full and optimized for comparison

Slim-image:

```
docker build -t mobilenet-slim -f Dockerfile-slim .
```

Fat-image:

```
docker build -t mobilenet-fat -f Dockerfile-fat .
```

## Run the model in a Docker container with the fat and slim docker-images using a test images of a cat and a labrador

Fat-image:

```
docker run --rm -v "$(pwd)/images/dog_test.jpg:/app/dog_test.jpg:ro" mobilenet-fat /app/dog_test.jpg

docker run --rm -v "$(pwd)/images/cat_test.png:/app/cat_test.png:ro" mobilenet-fat /app/cat_test.png
```

Slim-image:

```
docker run --rm -v "$(pwd)/images/dog_test.jpg:/app/dog_test.jpg:ro" mobilenet-slim /app/dog_test.jpg

docker run --rm -v "$(pwd)/images/cat_test.png:/app/cat_test.png:ro" mobilenet-slim /app/cat_test.png
```
