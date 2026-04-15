# ══════════════════════════════════════════════════════════════════════
# AVCP TFT Serving Container
# ══════════════════════════════════════════════════════════════════════
# Base: python:3.11-slim
# Serves the Temporal Fusion Transformer via a lightweight FastAPI
# endpoint compatible with Vertex AI custom container serving.
#
# Build:
#   docker build -t gcr.io/avcp-prod/tft-serving:latest -f Dockerfile .
#
# Run locally:
#   docker run -p 8080:8080 -e AIP_HEALTH_ROUTE=/health \
#     -e AIP_PREDICT_ROUTE=/predict \
#     gcr.io/avcp-prod/tft-serving:latest
# ══════════════════════════════════════════════════════════════════════

FROM python:3.11-slim AS base

# Prevent Python from buffering stdout/stderr (important for Cloud Logging)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# ── System dependencies ──────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        && \
    rm -rf /var/lib/apt/lists/*

# ── Python dependencies ──────────────────────────────────────────────
COPY requirements-serving.txt .
RUN pip install --no-cache-dir -r requirements-serving.txt

# ── Application code ─────────────────────────────────────────────────
COPY avcp/ ./avcp/
COPY serve.py .

# ── Health check ─────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# ── Vertex AI environment variables ──────────────────────────────────
ENV AIP_HEALTH_ROUTE=/health \
    AIP_PREDICT_ROUTE=/predict \
    AIP_HTTP_PORT=8080

EXPOSE 8080

# ── Run serving ──────────────────────────────────────────────────────
CMD ["python", "serve.py"]
