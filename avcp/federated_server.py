from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict
import torch
import torch.nn as nn
import uvicorn
import copy

app = FastAPI(
    title="AVCP Federated Aggregator (Zero-PII)",
    description="Implements FedAvg over PyTorch Edge Gradients instead of harvesting raw PII Vectors."
)

# ════════════════════════════════════════════════════════════════
# 1. Base Model Architecture
# ════════════════════════════════════════════════════════════════

class LocalEdgeModel(nn.Module):
    """
    Identical copy of the model architecture deployed individually to UWB edge nodes.
    Predicts `bottleneck_score` from simple kinematics.
    """
    def __init__(self):
        super(LocalEdgeModel, self).__init__()
        # Input features: [density_ppm2, velocity_x, velocity_y]
        self.fc1 = nn.Linear(3, 16)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(16, 1)

    def forward(self, x):
        return self.fc2(self.relu(self.fc1(x)))

# Initialize the global orchestration model.
global_model = LocalEdgeModel()

# ════════════════════════════════════════════════════════════════
# 2. Federated States
# ════════════════════════════════════════════════════════════════

class EdgeWeightsPayload(BaseModel):
    node_id: str
    sample_count: int
    # Encodes state_dict tensors as nested flat lists for JSON transport over FastAPI.
    weights_matrix: Dict[str, List[float]]

active_edge_updates = []

# ════════════════════════════════════════════════════════════════
# 3. Aggregation Endpoints
# ════════════════════════════════════════════════════════════════

@app.post("/federated/push_gradients")
async def receive_gradients(payload: EdgeWeightsPayload):
    """
    Edge nodes train locally on their physical crowd vectors (which contain local spatial hashes),
    then push ONLY the gradient weights here. At no point does central AVCP see user vectors.
    """
    active_edge_updates.append(payload)
    
    # If we hit an epoch threshold (e.g., 50 updates), trigger FedAvg asynchronously.
    if len(active_edge_updates) >= 50:
        _trigger_fedavg()
        
    return {"status": "accepted", "message": "Zero-PII Gradients received."}

@app.get("/federated/global_model")
async def pull_global_model():
    """Edge nodes poll this to download the aggregated superior weights."""
    state_dict = global_model.state_dict()
    # Flatten it for HTTP transit.
    serialized = {k: v.flatten().tolist() for k, v in state_dict.items()}
    return {"global_weights": serialized}

# ════════════════════════════════════════════════════════════════
# 4. Federated Averaging (FedAvg) Algorithm
# ════════════════════════════════════════════════════════════════

def _trigger_fedavg():
    """
    Executes the classic FedAvg Algorithm:
    w_{t+1} = sum( (n_k / n) * w_{t+1}^k )
    """
    global active_edge_updates, global_model
    
    if not active_edge_updates:
        return

    # Total samples across all reporting edges
    n_total = sum(update.sample_count for update in active_edge_updates)
    
    # Grab the template skeleton of the state dict
    global_dict = copy.deepcopy(global_model.state_dict())
    
    # Zero out the global skeleton
    for key in global_dict.keys():
        global_dict[key] = torch.zeros_like(global_dict[key])
        
    # Aggregate weighted gradients
    for update in active_edge_updates:
        weight_ratio = update.sample_count / n_total
        
        for key in global_dict.keys():
            # Reconstruct tensor shape from flat list payload
            original_shape = global_model.state_dict()[key].shape
            tensor_data = torch.tensor(update.weights_matrix[key]).view(original_shape)
            
            global_dict[key] += tensor_data * weight_ratio
            
    # Apply new superior weights to global model
    global_model.load_state_dict(global_dict)
    
    # Clear epoch cache
    active_edge_updates = []
    print(f"✅ FedAvg Complete: Aggregated {n_total} physical samples cleanly. Zero PII stored.")
    
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
