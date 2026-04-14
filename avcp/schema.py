"""CrowdVelocityVector — immutable, PII-free crowd motion record.

Design decisions
────────────────
• Frozen dataclass enforces immutability; every mutation creates a new
  instance, which eliminates an entire class of race-condition bugs in the
  multi-threaded edge pipeline.
• Every field is a primitive or bool—no nested structures—so
  `to_firebase_payload` is a zero-cost `asdict()` call.
• `density_ppm2` is clamped to [0.0, 6.5] at construction time via
  `__post_init__`; 6.5 p/m² is the Fruin Level-of-Service F crush
  threshold.  Values above that are physically implausible for a standing
  crowd and indicate sensor error.
• `heading_deg` is normalized to [0, 360) to keep downstream compass-rose
  visualizations consistent.
"""

from __future__ import annotations

import math
from dataclasses import asdict, dataclass, field
from typing import Any


@dataclass(frozen=True)
class CrowdVelocityVector:
    """Immutable, PII-free crowd motion record emitted per zone per tick.

    All fields are safe for Firebase RTDB by schema contract—no PII is
    stored or derivable from this record.
    """

    # ── Spatial identity (zone-level, never device-level) ──────────────
    zone_id: str
    """Venue-scoped zone identifier, e.g. ``"gate_c_concourse_level2"``."""

    sector_hash: str
    """SHA-256(zone_id ‖ venue_id), rotated hourly via KeyRotationService."""

    timestamp_ms: int
    """Unix epoch milliseconds (UTC)."""

    tick_window_s: float = 2.0
    """Aggregation window in seconds.  Default is 2.0 s (25 Hz UWB → 50
    frames per tick)."""

    # ── Kinematic fields ───────────────────────────────────────────────
    density_ppm2: float = 0.0
    """People per square metre.  Clamped to [0.0, 6.5] (Fruin LoS-F)."""

    velocity_x: float = 0.0
    """Mean lateral flow m/s, signed (−=west, +=east)."""

    velocity_y: float = 0.0
    """Mean longitudinal flow m/s, signed (−=south, +=north)."""

    speed_p95: float = 0.0
    """95th-percentile scalar speed m/s."""

    heading_deg: float = 0.0
    """Dominant heading [0, 360), 0=North."""

    # ── Congestion signals ─────────────────────────────────────────────
    dwell_ratio: float = 0.0
    """Fraction of population with speed < 0.3 m/s.  Range [0, 1]."""

    flow_variance: float = 0.0
    """Kinetic-energy variance (turbulence proxy)."""

    bottleneck_score: float = 0.0
    """0=free-flow, 1=gridlock.  Computed via Greenshields model."""

    # ── Predictive annotations (Vertex AI / TFLite at edge) ────────────
    predicted_density_60s: float = 0.0
    """Forecast density at T+60 s."""

    predicted_density_300s: float = 0.0
    """Forecast density at T+5 min."""

    anomaly_flag: bool = False
    """True if deviation > 2σ from a rolling 15-min baseline."""

    confidence: float = 0.0
    """Model confidence [0, 1]."""

    # ── Operational metadata ───────────────────────────────────────────
    edge_node_id: str = ""
    """Anonymized edge-node UUID, regenerated per session startup.
    Never persisted to disk."""

    schema_version: str = field(default="2.1.0")
    """Semver schema version string."""

    # ── Post-init validation ───────────────────────────────────────────
    def __post_init__(self) -> None:
        """Clamp & normalize fields that have physical invariants.

        Uses ``object.__setattr__`` because the dataclass is frozen.
        """
        # density_ppm2 ∈ [0.0, 6.5]  (Fruin crush limit)
        clamped_density = max(0.0, min(self.density_ppm2, 6.5))
        object.__setattr__(self, "density_ppm2", clamped_density)

        # heading_deg ∈ [0, 360)
        normalized_heading = self.heading_deg % 360.0
        object.__setattr__(self, "heading_deg", normalized_heading)

        # dwell_ratio ∈ [0, 1]
        clamped_dwell = max(0.0, min(self.dwell_ratio, 1.0))
        object.__setattr__(self, "dwell_ratio", clamped_dwell)

        # bottleneck_score ∈ [0, 1]
        clamped_bn = max(0.0, min(self.bottleneck_score, 1.0))
        object.__setattr__(self, "bottleneck_score", clamped_bn)

        # confidence ∈ [0, 1]
        clamped_conf = max(0.0, min(self.confidence, 1.0))
        object.__setattr__(self, "confidence", clamped_conf)

    # ── Serialization ──────────────────────────────────────────────────
    def to_firebase_payload(self) -> dict[str, Any]:
        """Serialize for Firebase RTDB.

        Returns a plain dict of primitives.  All fields are PII-free by
        schema contract, so no filtering is required.
        """
        return asdict(self)

    # ── Convenience ────────────────────────────────────────────────────
    def speed_scalar(self) -> float:
        """Compute the scalar speed from (velocity_x, velocity_y)."""
        return math.hypot(self.velocity_x, self.velocity_y)
