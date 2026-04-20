import time
import json
import random
import uuid
import datetime
from typing import Dict, Any

# Simulation constants
ZONES = ["Z-101", "Z-102", "Z-103", "Z-201", "Z-202"]
K_JAM = 6.5  # Fruin crush limit (ppm2)

def generate_mock_surge(zone_id: str, is_anomaly: bool = False) -> Dict[str, Any]:
    """Generates a realistic physical crowd vector conforming to the AVCP schema."""
    
    # Baseline physics
    base_density = random.uniform(1.0, 2.5) if not is_anomaly else random.uniform(4.5, 6.0)
    density_ppm2 = min(base_density, K_JAM)
    
    # Greenshields Model derivation for speed based on density
    # v = v_f * (1 - k / k_jam)
    v_freeflow = 1.4  # m/s
    speed_p95 = v_freeflow * (1 - (density_ppm2 / K_JAM))
    if speed_p95 < 0.1: speed_p95 = 0.1
    
    # Resolve velocities
    heading_deg = random.uniform(0, 360)
    import math
    rad = math.radians(heading_deg)
    velocity_x = speed_p95 * math.cos(rad)
    velocity_y = speed_p95 * math.sin(rad)
    
    return {
        "zone_id": zone_id,
        "sector_hash": uuid.uuid4().hex, # Rotated securely
        "timestamp_ms": int(time.time() * 1000),
        "density_ppm2": round(density_ppm2, 2),
        "velocity_x": round(velocity_x, 2),
        "velocity_y": round(velocity_y, 2),
        "speed_p95": round(speed_p95, 2),
        "heading_deg": round(heading_deg, 1),
        "dwell_ratio": round(random.uniform(0.1, 0.9), 2),
        "flow_variance": round(random.uniform(0.01, 0.5), 3),
        "bottleneck_score": round((density_ppm2 / K_JAM), 2),
        "predicted_density_60s": round(density_ppm2 * random.uniform(0.9, 1.2), 2),
        "predicted_density_300s": round(density_ppm2 * random.uniform(0.8, 1.5), 2),
        "anomaly_flag": is_anomaly,
        "confidence": 0.95,
        "edge_node_id": f"UWB-{random.randint(10,99)}"
    }

def run_simulation(duration_seconds: int = 60, hz: int = 2):
    """Fires payload bursts corresponding to edge ingestion rates."""
    print(f"🏟️ Starting AVCP Physical Surge Simulation ({hz}Hz)")
    print("-" * 50)
    
    ticks = duration_seconds * hz
    sleep_interval = 1.0 / hz
    
    for tick in range(ticks):
        # Induce a massive surge at halftime (tick 30)
        is_surge = (tick > 30 and tick < 60)
        
        payloads = [generate_mock_surge(zone, is_surge) for zone in ZONES]
        
        # Simulate pushing to Firebase REST / MQTT / ZMQ
        print(f"[{datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]}] "
              f"Pushed {len(payloads)} vectors | Surge Active: {is_surge}")
        
        for p in payloads:
            if p['anomaly_flag']:
                print(f"  🚨 ANOMALY in {p['zone_id']}: Density {p['density_ppm2']} ppm2 (Bottleneck: {p['bottleneck_score']})")
                
        time.sleep(sleep_interval)

if __name__ == "__main__":
    try:
        run_simulation(duration_seconds=120, hz=2)
    except KeyboardInterrupt:
        print("\nSimulation aborted.")
