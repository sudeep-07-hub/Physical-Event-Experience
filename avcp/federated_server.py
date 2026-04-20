"""AVCP Federated Aggregator (Zero-PII) — Hardened v2.1.0.

Implements FedAvg over PyTorch Edge Gradients instead of harvesting raw
PII Vectors.  All aggregation is done on gradient weights only — the
central server never sees user-level crowd vectors.

Security:
- API key authentication on gradient push endpoint
- Input validation (weight matrix shape + size limits)
- Thread-safe update collection via asyncio.Lock
- Background aggregation (non-blocking request handling)
- Structured logging (no print statements)
"""

from __future__ import annotations

import logging
import os
from typing import Dict, List

import torch
import torch.nn as nn
import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Header
from pydantic import BaseModel, field_validator
import copy
import asyncio

logger = logging.getLogger(__name__)

app = FastAPI(
    title="AVCP Federated Aggregator (Zero-PII)",
    description="Implements FedAvg over PyTorch Edge Gradients instead of harvesting raw PII Vectors.",
    version="2.1.0",
)

# ════════════════════════════════════════════════════════════════
# 1. Configuration
# ════════════════════════════════════════════════════════════════

# API key for authenticating edge nodes (set via environment variable)
_API_KEY = os.environ.get("AVCP_FED_API_KEY", "dev-key-change-me")

# Maximum number of floats allowed per weight matrix entry
_MAX_WEIGHT_VALUES = 100_000

# FedAvg aggregation threshold
_FEDAVG_THRESHOLD = 50

# ════════════════════════════════════════════════════════════════
# 2. Base Model Architecture
# ════════════════════════════════════════════════════════════════

class LocalEdgeModel(nn.Module):
    """Identical copy of the model architecture deployed individually to UWB edge nodes.

    Predicts `bottleneck_score` from simple kinematics.
    """

    def __init__(self) -> None:
        super(LocalEdgeModel, self).__init__()
        # Input features: [density_ppm2, velocity_x, velocity_y]
        self.fc1 = nn.Linear(3, 16)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(16, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.fc2(self.relu(self.fc1(x)))


# Initialize the global orchestration model.
global_model = LocalEdgeModel()

# ════════════════════════════════════════════════════════════════
# 3. Federated States (Thread-Safe)
# ════════════════════════════════════════════════════════════════

class EdgeWeightsPayload(BaseModel):
    """Validated payload for edge gradient submissions."""

    node_id: str
    sample_count: int
    # Encodes state_dict tensors as nested flat lists for JSON transport.
    weights_matrix: Dict[str, List[float]]

    @field_validator("sample_count")
    @classmethod
    def sample_count_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("sample_count must be positive")
        return v

    @field_validator("weights_matrix")
    @classmethod
    def validate_weights_size(cls, v: Dict[str, List[float]]) -> Dict[str, List[float]]:
        """Reject payloads with excessively large weight matrices (DoS protection)."""
        for key, values in v.items():
            if len(values) > _MAX_WEIGHT_VALUES:
                raise ValueError(
                    f"Weight key '{key}' has {len(values)} values, "
                    f"exceeding limit of {_MAX_WEIGHT_VALUES}"
                )
        return v


# Async lock for thread-safe access to the update list
_update_lock = asyncio.Lock()
_active_edge_updates: list[EdgeWeightsPayload] = []

# ════════════════════════════════════════════════════════════════
# 4. Authentication
# ════════════════════════════════════════════════════════════════

async def _verify_api_key(x_api_key: str = Header(..., alias="X-API-Key")) -> str:
    """Validate the API key from the request header."""
    if x_api_key != _API_KEY:
        logger.warning("Rejected request with invalid API key")
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key


# ════════════════════════════════════════════════════════════════
# 5. Aggregation Endpoints
# ════════════════════════════════════════════════════════════════

@app.post("/federated/push_gradients")
async def receive_gradients(
    payload: EdgeWeightsPayload,
    _key: str = Depends(_verify_api_key),
) -> dict[str, str]:
    """Receive gradient weights from an edge node.

    Edge nodes train locally on their physical crowd vectors (which contain
    local spatial hashes), then push ONLY the gradient weights here.  At no
    point does the central AVCP server see user-level vectors.
    """
    # Validate that the weight keys match the global model
    expected_keys = set(global_model.state_dict().keys())
    received_keys = set(payload.weights_matrix.keys())
    if received_keys != expected_keys:
        raise HTTPException(
            status_code=422,
            detail=f"Weight keys mismatch. Expected: {sorted(expected_keys)}, "
            f"got: {sorted(received_keys)}",
        )

    async with _update_lock:
        _active_edge_updates.append(payload)
        count = len(_active_edge_updates)

    logger.info(
        "Received gradients from node=%s samples=%d (buffer=%d/%d)",
        payload.node_id,
        payload.sample_count,
        count,
        _FEDAVG_THRESHOLD,
    )

    # If we hit the epoch threshold, trigger FedAvg in background
    if count >= _FEDAVG_THRESHOLD:
        asyncio.create_task(_trigger_fedavg())

    return {"status": "accepted", "message": "Zero-PII Gradients received."}


@app.get("/federated/global_model")
async def pull_global_model(
    _key: str = Depends(_verify_api_key),
) -> dict[str, dict[str, list[float]]]:
    """Edge nodes poll this to download the aggregated superior weights."""
    state_dict = global_model.state_dict()
    serialized = {k: v.flatten().tolist() for k, v in state_dict.items()}
    return {"global_weights": serialized}


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy", "model": "LocalEdgeModel", "version": "2.1.0"}


# ════════════════════════════════════════════════════════════════
# 6. Federated Averaging (FedAvg) Algorithm
# ════════════════════════════════════════════════════════════════

async def _trigger_fedavg() -> None:
    """Execute the classic FedAvg Algorithm.

    w_{t+1} = sum( (n_k / n) * w_{t+1}^k )

    Runs as a background task so it doesn't block API responses.
    """
    global _active_edge_updates

    async with _update_lock:
        if not _active_edge_updates:
            return

        # Snapshot and clear
        updates = list(_active_edge_updates)
        _active_edge_updates = []

    # Total samples across all reporting edges
    n_total = sum(update.sample_count for update in updates)

    # Grab the template skeleton of the state dict
    global_dict = copy.deepcopy(global_model.state_dict())

    # Zero out the global skeleton
    for key in global_dict.keys():
        global_dict[key] = torch.zeros_like(global_dict[key])

    # Aggregate weighted gradients
    for update in updates:
        weight_ratio = update.sample_count / n_total

        for key in global_dict.keys():
            # Reconstruct tensor shape from flat list payload
            original_shape = global_model.state_dict()[key].shape
            tensor_data = torch.tensor(update.weights_matrix[key]).view(
                original_shape
            )
            global_dict[key] += tensor_data * weight_ratio

    # Apply new superior weights to global model
    global_model.load_state_dict(global_dict)

    logger.info(
        "FedAvg complete: aggregated %d updates (%d total samples). Zero PII stored.",
        len(updates),
        n_total,
    )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    uvicorn.run(app, host="0.0.0.0", port=8080)
