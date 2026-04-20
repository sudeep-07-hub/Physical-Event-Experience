# Autonomous Venue Control Plane (AVCP) - Advanced Architecture

Welcome to the Advanced Deployment phase of AVCP. This repository represents an enterprise-grade prototype engineered specifically to solve physical crowd physics inside 50,000+ seat venues under heavy congestion constraints.

## 🛡️ Zero-PII Privacy (Federated Architecture)

Tracking humans natively through cellular networks is extremely dangerous from a privacy perspective. AVCP solves this via **Federated Edge Intelligence**.

Instead of your phone streaming its GPS and MAC address to a central server:
1. Your phone calculates crowd velocities completely securely on your own silicon (`Edge SGD`).
2. An anonymized, lightweight array of gradients ($w_{t+1}$) is passed to our `FastAPI` instance.
3. The `FedAvg` aggregator averages 50,000 gradients mathematics without ever observing who sent what.

### The "Ghost" Mesh Topology
If cellular towers crash under the physical load of 50,000 fans checking their phones simultaneously, AVCP survives natively.
- Using `flutter_reactive_ble`, devices instantly flip into **Peripheral Advertisers**.
- A bare-metal 31-byte constraint encodes `[Zone_ID | Congestion_Level | Timestamp]` into raw hexadecimal BLE Manufacturer Data packets. 
- Nearby peers automatically scan, parse, and update their physical maps without needing any Wi-Fi or 5G connection.

## 🧪 Simulation Capabilities

You don't deploy to 50,000 users blindly. We implemented a **Digital Twin Simulator** built entirely on the `mesa` Python Agent-Based framework. 

By executing `tests/stadium_sim.py`, 10,000 localized AI Fan Agents attempt to traverse a physical matrix blindly. The system generates a benchmark comparing throughput metrics against our predictive routing layer, proving AVCP eliminates bottlenecks structurally.

## ⚙️ Tech Stack
- Frontend Edge: `Flutter 3+` (Riverpod, Freezed, BLE Mesh, OpenStreetMap).
- Central Backend: `Firebase RTDB` + `Python FastAPI`.
- Models: `Temporal Fusion Transformers` + `Mesa Multi-Agent Grids` + `PyTorch SGD`.
