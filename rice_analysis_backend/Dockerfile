# ──────────────────────────────────────────────────────────────────────────────
# Rice Analysis Backend — Dockerfile
# Multi-stage build for a lean production image.
#
# Build:  docker build -t rice-analysis-api .
# Run:    docker run --gpus all -p 8000:8000 rice-analysis-api
# ──────────────────────────────────────────────────────────────────────────────

# ── Stage 1: base image with CUDA support ─────────────────────────────────────
# Use the official PyTorch CUDA image so GPU drivers are pre-configured.
# For CPU-only deployments replace with: python:3.11-slim
FROM pytorch/pytorch:2.2.0-cuda12.1-cudnn8-runtime AS base

WORKDIR /app

# System dependencies for OpenCV headless
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
 && rm -rf /var/lib/apt/lists/*

# ── Stage 2: install Python dependencies ─────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Stage 3: copy application code ───────────────────────────────────────────
COPY app/ ./app/

# Expose API port
EXPOSE 8000

# Health check — Docker will restart if the API stops responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# ── Entry point ───────────────────────────────────────────────────────────────
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
