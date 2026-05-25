# ──────────────────────────────────────────────────────────────────────────────
# Rice Analysis Backend — Dockerfile (RunPod Serverless)
#
# Production build: RunPod GPU container running the serverless worker.
# Local dev:        docker run --gpus all rice-analyzer-serverless python local_test.py
#
# Build:  docker build -t <hub>/rice-analyzer-serverless:latest .
# Push:   docker push <hub>/rice-analyzer-serverless:latest
# ──────────────────────────────────────────────────────────────────────────────

FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime AS base

WORKDIR /app
ENV PYTHONUNBUFFERED=1

# libglib2.0-0 required by opencv-python-headless; curl for healthcheck
RUN apt-get update --fix-missing && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source tree (includes model weights at app/models/)
COPY app/ ./app/

# Refresh processor configs using the container's transformers version.
# Uses sub-processor classes directly to avoid the composite GroundingDinoProcessor
# from_pretrained regression in transformers >= 4.45 (multiple values for image_processor).
RUN python -c "\
from transformers import AutoImageProcessor, AutoTokenizer, SamImageProcessor; \
AutoImageProcessor.from_pretrained('IDEA-Research/grounding-dino-base') \
    .save_pretrained('/app/app/models/dino'); \
AutoTokenizer.from_pretrained('IDEA-Research/grounding-dino-base') \
    .save_pretrained('/app/app/models/dino'); \
SamImageProcessor.from_pretrained('facebook/sam-vit-base') \
    .save_pretrained('/app/app/models/sam'); \
print('Processor configs refreshed OK')"

# Copy the RunPod entrypoint
COPY run_serverless.py .

# Non-root user for container security
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Minimal healthcheck — verifies Python + app config can be imported
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "from app.core.config import settings; print('ok')" || exit 1

# RunPod Serverless worker — starts the queue handler daemon directly.
# No HTTP port needed; RunPod manages the request queue.
CMD ["python", "-u", "run_serverless.py"]
