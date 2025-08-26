#!/usr/bin/env bash
set -euo pipefail

# Minimal installer for Dev/ML deps in either:
#  1) local virtualenv (.venv)  [default]
#  2) docker image (python:3.11-slim)  [--docker]
#
# Installs: Django, torch, torchvision, pillow
# Idempotent: re-running won’t break/reinstall unnecessarily.

MODE="venv"  # or "docker"
IMAGE_TAG="devtools:latest"
REQ_PKGS=("Django" "torch" "torchvision" "pillow")

for arg in "$@"; do
  case "$arg" in
    --docker) MODE="docker" ;;
    --venv) MODE="venv" ;;
    *) echo "[WARN] Unknown arg: $arg" ;;
  esac
done

have_cmd() { command -v "$1" >/dev/null 2>&1; }

ver_ge() {
  # usage: ver_ge "3.11.4" "3.9.0"  -> true if first >= second
  # pure bash compare
  IFS=. read -r -a A <<<"${1//[^0-9.]/}"
  IFS=. read -r -a B <<<"${2//[^0-9.]/}"
  for i in 0 1 2; do
    a=${A[i]:-0}; b=${B[i]:-0}
    if (( a > b )); then return 0; fi
    if (( a < b )); then return 1; fi
  done
  return 0
}

install_in_venv() {
  echo "[INFO] Using local virtual environment (.venv)"
  if ! have_cmd python3; then
    echo "[ERR] python3 not found. Please install Python ≥ 3.9." >&2; exit 1
  fi
  PYV=$(python3 -V 2>&1 | awk '{print $2}')
  if ! ver_ge "$PYV" "3.9.0"; then
    echo "[ERR] Python $PYV detected (< 3.9). Please upgrade Python to ≥ 3.9." >&2; exit 1
  fi

  # create venv if missing
  if [[ ! -d ".venv" ]]; then
    echo "[INFO] Creating .venv"
    python3 -m venv .venv
  else
    echo "[OK]   .venv already exists"
  fi

  VPY="./.venv/bin/python"
  VPIP="./.venv/bin/pip"

  # ensure pip present/updated in venv
  "$VPY" -m ensurepip --upgrade >/dev/null 2>&1 || true
  "$VPY" -m pip install --upgrade pip >/dev/null

  echo "[INFO] Installing required packages in .venv (idempotent)"
  "$VPIP" install -U "${REQ_PKGS[@]}"

  echo "[OK]   Done. Activate with:  source .venv/bin/activate"
}

install_in_docker() {
  echo "[INFO] Using Docker image ($IMAGE_TAG)"
  if ! have_cmd docker; then
    echo "[ERR] docker not found. Please install Docker." >&2; exit 1
  fi

  if docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
    echo "[OK]   Image $IMAGE_TAG already exists – skipping build"
  else
    echo "[INFO] Building $IMAGE_TAG with Python deps"
    # build from inline Dockerfile
    DOCKER_BUILDKIT=1 docker build -t "$IMAGE_TAG" - <<'DOCKERFILE'
FROM python:3.11-slim

# Avoid interactive tzdata etc.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System deps just for building wheels if needed (kept minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

# Python deps
RUN python -m pip install --upgrade pip \
 && pip install Django torch torchvision pillow

# Workdir and default command
WORKDIR /work
CMD ["python", "--version"]
DOCKERFILE
    echo "[OK]   Image built: $IMAGE_TAG"
  fi

  echo
  echo "[TIP]  Run a shell in the ready-to-use container:"
  echo "      docker run --rm -it -v \"\$PWD\":/work -w /work $IMAGE_TAG bash"
  echo "      # inside: python -c \"import torch, django, PIL; print(torch.__version__)\""
}

# -------- Main --------
if [[ "$MODE" == "docker" ]]; then
  install_in_docker
else
  install_in_venv
fi

echo "[SUMMARY]"
if [[ "$MODE" == "venv" ]]; then
  ./\.venv/bin/python -V || true
  ./\.venv/bin/pip list | grep -E 'Django|torch|torchvision|pillow' || true
else
  docker image inspect "$IMAGE_TAG" >/dev/null 2>&1 && echo "Docker image: $IMAGE_TAG present"
fi
