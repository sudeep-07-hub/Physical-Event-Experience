"""FastAPI serving endpoint for AVCP TFT model.

Compatible with Vertex AI custom container serving protocol.
Routes: /predict (POST), /health (GET), /metrics (GET).
"""

from __future__ import annotations

import logging
import os

import numpy as np
import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

from avcp.vertex.crowd_predictor import (
    CrowdPredictor,
    InputValidationError,
    LinearRegressionFallback,
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title="AVCP TFT Serving",
    version="2.1.0",
    description="Crowd density prediction serving endpoint",
)

# ── Initialize predictor ─────────────────────────────────────────────
# In production, these come from Vertex AI environment
_PROJECT = os.environ.get("GCP_PROJECT", "avcp-prod")
_LOCATION = os.environ.get("GCP_LOCATION", "us-central1")
_ENDPOINT_ID = os.environ.get("VERTEX_ENDPOINT_ID", "")

_fallback = LinearRegressionFallback()

# Predictor is lazily initialized (endpoint may not be available in dev)
_predictor: CrowdPredictor | None = None


def _get_predictor() -> CrowdPredictor | LinearRegressionFallback:
    global _predictor
    if _ENDPOINT_ID and _predictor is None:
        try:
            _predictor = CrowdPredictor(
                endpoint_id=_ENDPOINT_ID,
                project=_PROJECT,
                location=_LOCATION,
            )
        except Exception:
            logger.warning("Failed to init CrowdPredictor, using fallback")
            return _fallback
    return _predictor or _fallback


# ── Routes ───────────────────────────────────────────────────────────


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.post("/predict")
async def predict(request: Request) -> JSONResponse:
    """Vertex AI prediction endpoint.

    Expects JSON body:
    {
        "instances": [{"inputs": [[...], [...], ...]}]
    }
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")

    instances = body.get("instances", [])
    if not instances:
        raise HTTPException(status_code=400, detail="No instances provided")

    predictions = []
    predictor = _get_predictor()

    for instance in instances:
        inputs = instance.get("inputs")
        if inputs is None:
            raise HTTPException(
                status_code=400,
                detail="Each instance must have an 'inputs' field",
            )

        try:
            feature_matrix = np.array(inputs, dtype=np.float32)
            if isinstance(predictor, CrowdPredictor):
                result = predictor.predict(feature_matrix)
            else:
                result = predictor.predict(feature_matrix)
            predictions.append(result)
        except InputValidationError as e:
            raise HTTPException(status_code=422, detail=str(e))
        except Exception as e:
            logger.exception("Prediction error")
            raise HTTPException(status_code=500, detail=str(e))

    return JSONResponse(content={"predictions": predictions})


# ── Prometheus metrics endpoint ──────────────────────────────────────

try:
    from prometheus_fastapi_instrumentator import Instrumentator

    Instrumentator().instrument(app).expose(app, endpoint="/metrics")
except ImportError:
    logger.info("prometheus_fastapi_instrumentator not available, skipping /metrics")


# ── Entry point ──────────────────────────────────────────────────────

if __name__ == "__main__":
    port = int(os.environ.get("AIP_HTTP_PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
