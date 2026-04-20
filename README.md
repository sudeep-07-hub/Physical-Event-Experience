# Autonomous Venue Control Plane (AVCP) — v2.1.0 (Nav-Sync)

AVCP is an enterprise-grade venue intelligence engine designed to solve crowd physics at scale. This repository focuses on the **Predictive Wayfinding Assistant**, transitioning from static dashboards to a real-time, intent-driven HUD for 50,000+ seat stadiums.

## 🚀 The Hub Overlay — v2.1.0 Update

The latest deployment introduces the **Nav-Sync** architecture, ensuring that navigation instructions, gate statuses, and user positioning stay physically locked to the stadium's geo-coordinates during map interaction.

### Key Innovations:
*   **Predictive Intent HUD**: A dynamic instruction engine that thresholds localized physics (UWB Proximity, Density, Dwell Ratios) to automatically pivot the UI between 4 states: `Free Flowing`, `Heavy Wait`, `Rerouting`, and `Near Gate`.
*   **Coordinate-Locked Routing**: Migrated from screen-space overlays to native **Google Maps Polylines & Markers**, eliminating the "floating route" bug during pinch/zoom/pan.
*   **Zero-PII Privacy Engine**: All navigation logic is processed locally using anonymized `ZoneId` mapping and physics vectors. No identities, facial data, or persistent device IDs are ever used to draw the path to your seat.
*   **Pre-Rendered Marker Ecosystem**: High-DPI (`2.0x+`) vector markers are rendered at runtime using `dart:ui`, ensuring sharp infrastructure icons across all mobile pixel densities.

## 🛡️ Federated Edge Intelligence

Instead of streaming raw GPS coordinates to a central server:
1.  **Edge Ingestion**: Devices calculate crowd velocities locally at **25Hz**.
2.  **Anonymized Gradients**: Minimal physics vectors are pushed to a `FastAPI` aggregator.
3.  **Digital Twin Sync**: The venue's "Digital Twin" simulates 10k additional agents to predict bottlenecks 5 minutes before they occur.

## ⚙️ Tech Stack

### Frontend (Edge)
- **Framework**: `Flutter 3.x` (stable)
- **State Mgmt**: `Riverpod 2.x` (strictly decoupled providers)
- **Map System**: `Google Maps Native` with custom dark-mode JSON styling.
- **Rendering**: Optimized `RepaintBoundary` layers and `SnapSizes` draggable sheet.

### Backend (Infrastructure)
- **Core**: `Firebase RTDB` for high-frequency physics streams.
- **Serving**: `Python FastAPI` + `Temporal Fusion Transformers` for crowd prediction.
- **Mesh**: `BLE Mesh Topology` for offline fallback in high-density environments.

## 🧪 Simulation & Testing

AVCP includes a comprehensive simulation suite to validate navigation integrity:
- `test/wayfinding/coordinate_sync_test.dart`: Verifies LatLng consistency during map scaling.
- `mockGateContextProvider`: A 48-second cyclic mock stream for rapid UI iteration and offline development.

---
**Note:** A valid Google Maps API Key is required in `web/index.html` and `AndroidManifest.xml` for production map tile rendering.
