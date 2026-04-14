"""EdgeIngestor — real-time UWB-to-CrowdVelocityVector processing pipeline.

Architecture
────────────
                      ZMQ PULL (25 Hz UWB frames)
                              │
                     ┌────────▼────────┐
                     │  _ingest_frame  │  Parse + append to deque
                     └────────┬────────┘
                              │  every tick_window_s (2 s, 50 frames)
                     ┌────────▼────────┐
                     │  _flush_tick    │  Aggregate window → vector
                     └────────┬────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   _compute_density   _compute_kinematics  _compute_bottleneck
   (Voronoi tess.)    (mean vel, P95, hdg)  (Greenshields FD)
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
                     ┌────────────────┐
                     │ CrowdPredictor │  TFLite → if conf < 0.7
                     │                │  fallback to cloud Vertex AI
                     └────────┬───────┘
                              ▼
                     ┌────────────────┐
                     │ EdgePublisher  │  Pub/Sub
                     └────────────────┘

Algorithmic notes
─────────────────
• **Voronoi density**: We compute the Voronoi diagram of UWB anchor
  positions using ``scipy.spatial.Voronoi``.  Each cell's area gives a
  local density estimate; the zone-level density is the mean across
  cells that fall within the zone polygon.  Voronoi is preferred over
  grid-based counting because it adapts to irregular zone geometries
  and produces smoother density surfaces.

• **Greenshields fundamental diagram**: The classic traffic-flow model
  relates speed to density linearly:
      v(k) = v_free × (1 − k / k_jam)
  The *bottleneck_score* is the ratio of observed density to jam density,
  clamped to [0, 1].  At score ≈ 0.7+ the zone is operationally
  congested; at 1.0 it is at crush density (gridlock).

• **Anomaly detection**: A rolling 15-min baseline (450 ticks @ 2 s)
  is maintained per zone.  A tick is flagged anomalous if its density
  deviates by more than 2σ from the baseline mean.  This is a
  computationally cheap Gaussian check that runs entirely at the edge.

• **Cloud fallback**: The local TFLite predictor is the primary path.
  Only when its self-reported confidence drops below 0.7 do we call
  ``CrowdPredictor.predict()`` via Vertex AI.  This keeps cloud egress
  costs near-zero under normal conditions.
"""

from __future__ import annotations

import collections
import logging
import math
import statistics
import struct
import time
from dataclasses import dataclass
from typing import Protocol

import numpy as np
import zmq
from numpy.typing import NDArray
from scipy.spatial import Voronoi  # type: ignore[import-untyped]

from avcp.key_rotation import KeyRotationService
from avcp.publishers import EdgePublisher
from avcp.schema import CrowdVelocityVector

logger = logging.getLogger(__name__)


# ── UWB frame data structure ──────────────────────────────────────────

@dataclass(frozen=True)
class UWBFrame:
    """Single UWB anchor frame parsed from the ZMQ wire format.

    Wire format (little-endian, 28 bytes):
        4s   zone_id length + bytes (length-prefixed UTF-8)
        8d   x position (metres)
        8d   y position (metres)
        8d   timestamp (Unix epoch seconds, float64)
    """

    zone_id: str
    x: float
    y: float
    timestamp_s: float


# ── Predictor protocol ────────────────────────────────────────────────

class CrowdPredictor(Protocol):
    """Interface for density prediction (TFLite local or Vertex AI cloud).

    Implementations must return a tuple of
    ``(density_60s, density_300s, confidence)``.
    """

    def predict(
        self,
        zone_id: str,
        density_history: list[float],
        velocity_history: list[tuple[float, float]],
    ) -> tuple[float, float, float]: ...


# ── Greenshields parameters ───────────────────────────────────────────

_K_JAM: float = 6.5    # Jam density (people / m²)
_V_FREE: float = 1.4   # Free-flow walking speed (m/s)

# ── Anomaly baseline parameters ──────────────────────────────────────

_BASELINE_WINDOW: int = 450   # 15 min @ 2 s ticks
_ANOMALY_SIGMA: float = 2.0  # Standard deviations for anomaly flag

# ── Dwell speed threshold ────────────────────────────────────────────

_DWELL_SPEED_THRESHOLD: float = 0.3  # m/s

# ── Cloud fallback confidence threshold ──────────────────────────────

_CLOUD_CONFIDENCE_THRESHOLD: float = 0.7


# ── EdgeIngestor ──────────────────────────────────────────────────────

class EdgeIngestor:
    """Consume UWB frames and emit ``CrowdVelocityVector`` per tick window.

    Parameters
    ----------
    zmq_endpoint:
        ZMQ PULL socket endpoint, e.g. ``"tcp://127.0.0.1:5555"``.
    zone_area_m2:
        Area of the monitored zone in m²  (used for density fallback
        when Voronoi cells extend beyond the zone boundary).
    key_service:
        ``KeyRotationService`` instance for sector hashes and node IDs.
    publisher:
        ``EdgePublisher`` for fan-out to Pub/Sub.
    local_predictor:
        TFLite-backed predictor (primary path).
    cloud_predictor:
        Vertex AI predictor (fallback when local confidence < 0.7).
    tick_window_s:
        Aggregation window in seconds.  Default ``2.0``.
    frame_rate_hz:
        Expected UWB frame rate.  Default ``25`` Hz.
    """

    def __init__(
        self,
        zmq_endpoint: str,
        zone_area_m2: float,
        key_service: KeyRotationService,
        publisher: EdgePublisher,
        local_predictor: CrowdPredictor,
        cloud_predictor: CrowdPredictor,
        tick_window_s: float = 2.0,
        frame_rate_hz: int = 25,
    ) -> None:
        self._zmq_endpoint = zmq_endpoint
        self._zone_area_m2 = zone_area_m2
        self._key_service = key_service
        self._publisher = publisher
        self._local_predictor = local_predictor
        self._cloud_predictor = cloud_predictor
        self._tick_window_s = tick_window_s

        # deque(maxlen=50) holds exactly one tick window of frames at 25 Hz
        maxlen = int(tick_window_s * frame_rate_hz)
        self._frame_buffer: collections.deque[UWBFrame] = collections.deque(
            maxlen=maxlen,
        )

        # Rolling density baseline for anomaly detection (per zone).
        # Key: zone_id → deque of recent density values.
        self._density_baseline: dict[str, collections.deque[float]] = {}

        # Rolling histories for the predictor (per zone).
        self._density_history: dict[str, list[float]] = {}
        self._velocity_history: dict[str, list[tuple[float, float]]] = {}

        # ZMQ context is created but socket is bound in ``run()``.
        self._zmq_ctx: zmq.Context[zmq.Socket[bytes]] = zmq.Context()
        self._running = False

    # ── Public API ─────────────────────────────────────────────────────

    def run(self) -> None:
        """Start the ingest loop.  Blocks the calling thread.

        The loop pulls UWB frames as fast as they arrive (25 Hz) and
        flushes a ``CrowdVelocityVector`` every ``tick_window_s``.
        """
        socket: zmq.Socket[bytes] = self._zmq_ctx.socket(zmq.PULL)
        socket.connect(self._zmq_endpoint)
        logger.info(
            "EdgeIngestor connected to %s (window=%ss)",
            self._zmq_endpoint,
            self._tick_window_s,
        )

        self._running = True
        window_start = time.monotonic()

        try:
            while self._running:
                # Non-blocking poll with 10 ms timeout so we can check
                # the window boundary even if no frames arrive.
                if socket.poll(timeout=10, flags=zmq.POLLIN):
                    raw: bytes = socket.recv(flags=zmq.NOBLOCK)
                    frame = self._parse_frame(raw)
                    self._frame_buffer.append(frame)

                elapsed = time.monotonic() - window_start
                if elapsed >= self._tick_window_s:
                    self._flush_tick()
                    window_start = time.monotonic()
        finally:
            socket.close()
            logger.info("EdgeIngestor stopped.")

    def stop(self) -> None:
        """Signal the ingest loop to exit after the current iteration."""
        self._running = False

    # ── Frame parsing ──────────────────────────────────────────────────

    @staticmethod
    def _parse_frame(raw: bytes) -> UWBFrame:
        """Deserialize a UWB anchor frame from the ZMQ wire format.

        Wire layout (little-endian):
            [4 bytes] zone_id_len (uint32)
            [N bytes] zone_id (UTF-8)
            [8 bytes] x (float64)
            [8 bytes] y (float64)
            [8 bytes] timestamp_s (float64)
        """
        offset = 0
        (zone_len,) = struct.unpack_from("<I", raw, offset)
        offset += 4

        zone_id = raw[offset : offset + zone_len].decode("utf-8")
        offset += zone_len

        x, y, ts = struct.unpack_from("<ddd", raw, offset)
        return UWBFrame(zone_id=zone_id, x=x, y=y, timestamp_s=ts)

    # ── Tick aggregation ───────────────────────────────────────────────

    def _flush_tick(self) -> None:
        """Aggregate buffered frames into one ``CrowdVelocityVector``.

        Called once per ``tick_window_s``.  If the buffer is empty the
        tick is silently skipped (no phantom vectors are emitted).
        """
        if not self._frame_buffer:
            return

        # Snapshot and clear; the deque is only written by this thread
        # (single-producer) so no lock is needed.
        frames = list(self._frame_buffer)
        self._frame_buffer.clear()

        zone_id = frames[0].zone_id
        now_ms = int(time.time() * 1000)

        positions = np.array([[f.x, f.y] for f in frames], dtype=np.float64)

        density = self._compute_density(positions)
        vx, vy, p95, heading = self._compute_kinematics(frames)
        bn_score = self._compute_bottleneck(density)
        dwell = self._compute_dwell_ratio(frames)
        flow_var = self._compute_flow_variance(frames)
        anomaly = self._check_anomaly(zone_id, density)

        # Prediction: local TFLite first, cloud Vertex AI only on low
        # confidence.
        d60, d300, conf = self._predict(zone_id, density, vx, vy)

        sector = self._key_service.sector_hash(zone_id)

        vector = CrowdVelocityVector(
            zone_id=zone_id,
            sector_hash=sector,
            timestamp_ms=now_ms,
            tick_window_s=self._tick_window_s,
            density_ppm2=density,
            velocity_x=vx,
            velocity_y=vy,
            speed_p95=p95,
            heading_deg=heading,
            dwell_ratio=dwell,
            flow_variance=flow_var,
            bottleneck_score=bn_score,
            predicted_density_60s=d60,
            predicted_density_300s=d300,
            anomaly_flag=anomaly,
            confidence=conf,
            edge_node_id=self._key_service.edge_node_id,
            schema_version="2.1.0",
        )

        self._publisher.publish(vector)
        logger.debug("Tick published for zone=%s density=%.2f", zone_id, density)

    # ── Density via Voronoi tessellation ───────────────────────────────

    def _compute_density(self, positions: NDArray[np.float64]) -> float:
        """Estimate crowd density (people/m²) using Voronoi cell areas.

        For < 4 points Voronoi is degenerate, so we fall back to a
        simple count / area estimate.

        Returns density clamped to [0.0, 6.5].
        """
        n_points = positions.shape[0]
        if n_points == 0:
            return 0.0

        if n_points < 4:
            # Degenerate case: not enough points for a meaningful Voronoi
            # diagram.  Fall back to simple area division.
            return min(n_points / self._zone_area_m2, _K_JAM)

        try:
            vor = Voronoi(positions)
        except Exception:
            logger.warning("Voronoi computation failed; using fallback density.")
            return min(n_points / self._zone_area_m2, _K_JAM)

        finite_areas = self._voronoi_finite_areas(vor)
        if not finite_areas:
            return min(n_points / self._zone_area_m2, _K_JAM)

        # Mean inverse area = mean local density.
        mean_density = float(np.mean(1.0 / np.array(finite_areas)))
        return min(max(mean_density, 0.0), _K_JAM)

    @staticmethod
    def _voronoi_finite_areas(vor: Voronoi) -> list[float]:
        """Extract finite Voronoi cell areas, skipping unbounded cells.

        Unbounded cells (containing vertex index −1) have infinite area
        and would corrupt the density estimate, so they are excluded.
        """
        areas: list[float] = []
        for region_indices in vor.regions:
            if not region_indices or -1 in region_indices:
                continue
            polygon = vor.vertices[region_indices]
            area = _shoelace_area(polygon)
            if area > 0.0:
                areas.append(area)
        return areas

    # ── Kinematics ─────────────────────────────────────────────────────

    @staticmethod
    def _compute_kinematics(
        frames: list[UWBFrame],
    ) -> tuple[float, float, float, float]:
        """Derive mean velocity, P95 speed, and dominant heading.

        We compute per-frame displacements between consecutive frames
        (sorted by timestamp).  At least two frames are required;
        otherwise zero kinematics are returned.

        Returns
        -------
        tuple of (velocity_x, velocity_y, speed_p95, heading_deg)
        """
        if len(frames) < 2:
            return 0.0, 0.0, 0.0, 0.0

        sorted_frames = sorted(frames, key=lambda f: f.timestamp_s)

        dx_list: list[float] = []
        dy_list: list[float] = []
        speeds: list[float] = []

        for i in range(1, len(sorted_frames)):
            prev, curr = sorted_frames[i - 1], sorted_frames[i]
            dt = curr.timestamp_s - prev.timestamp_s
            if dt <= 0.0:
                continue
            dx = (curr.x - prev.x) / dt
            dy = (curr.y - prev.y) / dt
            dx_list.append(dx)
            dy_list.append(dy)
            speeds.append(math.hypot(dx, dy))

        if not speeds:
            return 0.0, 0.0, 0.0, 0.0

        vx = statistics.mean(dx_list)
        vy = statistics.mean(dy_list)

        # 95th-percentile scalar speed.
        speeds_sorted = sorted(speeds)
        p95_idx = int(0.95 * (len(speeds_sorted) - 1))
        speed_p95 = speeds_sorted[p95_idx]

        # Dominant heading: atan2 of mean velocity vector, converted to
        # compass bearing [0, 360).  atan2(x, y) gives bearing from North.
        heading = math.degrees(math.atan2(vx, vy)) % 360.0

        return vx, vy, speed_p95, heading

    # ── Greenshields bottleneck score ──────────────────────────────────

    @staticmethod
    def _compute_bottleneck(density: float) -> float:
        """Compute bottleneck score via the Greenshields fundamental diagram.

        Greenshields model:   v(k) = v_free × (1 − k / k_jam)
        Bottleneck score:     b     = k / k_jam

        A score of 0 ⇒ free-flow, 1 ⇒ jam density (gridlock).
        """
        return min(max(density / _K_JAM, 0.0), 1.0)

    # ── Dwell ratio ────────────────────────────────────────────────────

    @staticmethod
    def _compute_dwell_ratio(frames: list[UWBFrame]) -> float:
        """Fraction of consecutive-frame speeds below 0.3 m/s.

        A high dwell ratio indicates a stationary crowd — a precursor
        to congestion even at moderate densities.
        """
        if len(frames) < 2:
            return 0.0

        sorted_frames = sorted(frames, key=lambda f: f.timestamp_s)
        n_dwell = 0
        n_total = 0

        for i in range(1, len(sorted_frames)):
            prev, curr = sorted_frames[i - 1], sorted_frames[i]
            dt = curr.timestamp_s - prev.timestamp_s
            if dt <= 0.0:
                continue
            speed = math.hypot(
                (curr.x - prev.x) / dt,
                (curr.y - prev.y) / dt,
            )
            n_total += 1
            if speed < _DWELL_SPEED_THRESHOLD:
                n_dwell += 1

        return n_dwell / n_total if n_total > 0 else 0.0

    # ── Flow variance (turbulence proxy) ───────────────────────────────

    @staticmethod
    def _compute_flow_variance(frames: list[UWBFrame]) -> float:
        """Kinetic-energy variance across the tick window.

        High variance indicates turbulent, multi-directional flow (e.g.
        counter-flowing streams), which is dangerous even at moderate
        densities.  We compute variance of 0.5 × speed² as a proxy for
        per-capita kinetic energy fluctuation.
        """
        if len(frames) < 2:
            return 0.0

        sorted_frames = sorted(frames, key=lambda f: f.timestamp_s)
        energies: list[float] = []

        for i in range(1, len(sorted_frames)):
            prev, curr = sorted_frames[i - 1], sorted_frames[i]
            dt = curr.timestamp_s - prev.timestamp_s
            if dt <= 0.0:
                continue
            speed = math.hypot(
                (curr.x - prev.x) / dt,
                (curr.y - prev.y) / dt,
            )
            energies.append(0.5 * speed * speed)

        return statistics.variance(energies) if len(energies) >= 2 else 0.0

    # ── Anomaly detection ──────────────────────────────────────────────

    def _check_anomaly(self, zone_id: str, density: float) -> bool:
        """Flag anomalous density using a rolling 15-min Gaussian baseline.

        Returns ``True`` if the current density deviates by more than 2σ
        from the rolling mean.  During the warm-up period (< 30 ticks =
        1 min) no anomalies are flagged to avoid false positives.
        """
        baseline = self._density_baseline.setdefault(
            zone_id,
            collections.deque(maxlen=_BASELINE_WINDOW),
        )
        baseline.append(density)

        # Need at least 30 samples (1 min) for a stable baseline.
        if len(baseline) < 30:
            return False

        baseline_list = list(baseline)
        mean = statistics.mean(baseline_list)
        stdev = statistics.stdev(baseline_list)

        if stdev == 0.0:
            return False

        return abs(density - mean) > _ANOMALY_SIGMA * stdev

    # ── Prediction (local TFLite → cloud fallback) ─────────────────────

    def _predict(
        self,
        zone_id: str,
        density: float,
        vx: float,
        vy: float,
    ) -> tuple[float, float, float]:
        """Run density prediction, falling back to cloud on low confidence.

        Returns ``(density_60s, density_300s, confidence)``.
        """
        # Accumulate histories for the predictor.
        self._density_history.setdefault(zone_id, []).append(density)
        self._velocity_history.setdefault(zone_id, []).append((vx, vy))

        # Cap history length to avoid unbounded growth.
        max_hist = _BASELINE_WINDOW
        self._density_history[zone_id] = self._density_history[zone_id][
            -max_hist:
        ]
        self._velocity_history[zone_id] = self._velocity_history[zone_id][
            -max_hist:
        ]

        d_hist = self._density_history[zone_id]
        v_hist = self._velocity_history[zone_id]

        # Primary path: local TFLite model.
        d60, d300, conf = self._local_predictor.predict(zone_id, d_hist, v_hist)

        if conf < _CLOUD_CONFIDENCE_THRESHOLD:
            # Cloud fallback — only when local model is uncertain.
            logger.info(
                "Local confidence %.2f < %.2f for zone=%s; cloud fallback.",
                conf,
                _CLOUD_CONFIDENCE_THRESHOLD,
                zone_id,
            )
            d60, d300, conf = self._cloud_predictor.predict(
                zone_id, d_hist, v_hist,
            )

        return d60, d300, conf


# ── Utility ────────────────────────────────────────────────────────────

def _shoelace_area(polygon: NDArray[np.float64]) -> float:
    """Compute the area of a simple polygon via the shoelace formula.

    Parameters
    ----------
    polygon:
        (N, 2) array of vertices in order.

    Returns
    -------
    Absolute area in the same units as the input coordinates.
    """
    x = polygon[:, 0]
    y = polygon[:, 1]
    return float(0.5 * abs(np.dot(x, np.roll(y, -1)) - np.dot(y, np.roll(x, -1))))
