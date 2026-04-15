"""Shared fixtures for the AVCP validation suite.

All fixtures are independent — no shared mutable state between tests.
Fixtures are organized by layer:
  - Schema / data fixtures (vectors, matrices)
  - Service fixtures (crowd analysis, key rotation)
  - Vertex AI fixtures (predictor, circuit breaker)
  - Event phase / scenario fixtures (surge, halftime, evacuation)
"""

from __future__ import annotations

import collections
import statistics
import time
from dataclasses import replace
from typing import Any, Generator
from unittest.mock import MagicMock, patch

import numpy as np
import pytest

from avcp.key_rotation import KeyRotationService
from avcp.schema import CrowdVelocityVector


# ══════════════════════════════════════════════════════════════════════
# PII Blocklist — single source of truth for all PII tests
# ══════════════════════════════════════════════════════════════════════

PII_FORBIDDEN_FIELDS: frozenset[str] = frozenset({
    "user_id", "device_id", "ip", "mac", "face_vector", "name",
    "phone", "email", "imei", "ssid",
})


# ══════════════════════════════════════════════════════════════════════
# Schema / Data Fixtures
# ══════════════════════════════════════════════════════════════════════

@pytest.fixture
def sample_vector() -> CrowdVelocityVector:
    """A realistic, fully-populated CrowdVelocityVector."""
    return CrowdVelocityVector(
        zone_id="gate_c_concourse_level2",
        sector_hash="a1b2c3d4e5f6" * 5 + "ab",  # 64 hex chars
        timestamp_ms=1_700_000_000_000,
        tick_window_s=2.0,
        density_ppm2=2.3,
        velocity_x=0.45,
        velocity_y=-0.12,
        speed_p95=1.8,
        heading_deg=275.0,
        dwell_ratio=0.35,
        flow_variance=2.1,
        bottleneck_score=0.42,
        predicted_density_60s=2.8,
        predicted_density_300s=3.5,
        anomaly_flag=False,
        confidence=0.91,
        edge_node_id="abc123def456",
        schema_version="2.1.0",
    )


@pytest.fixture
def free_flow_vector() -> CrowdVelocityVector:
    """Free-flow conditions: low density, low dwell, no bottleneck."""
    return CrowdVelocityVector(
        zone_id="section_a",
        sector_hash="ff" * 32,
        timestamp_ms=1_700_000_000_000,
        density_ppm2=0.5,
        velocity_x=1.2,
        velocity_y=0.3,
        speed_p95=1.6,
        heading_deg=90.0,
        dwell_ratio=0.05,
        flow_variance=0.2,
        bottleneck_score=0.08,
    )


@pytest.fixture
def crush_vector() -> CrowdVelocityVector:
    """Crush-density conditions: Fruin LoS-F, gridlock."""
    return CrowdVelocityVector(
        zone_id="gate_c_concourse_level2",
        sector_hash="00" * 32,
        timestamp_ms=1_700_000_000_000,
        density_ppm2=6.5,
        velocity_x=0.0,
        velocity_y=0.0,
        speed_p95=0.1,
        heading_deg=0.0,
        dwell_ratio=0.95,
        flow_variance=0.1,
        bottleneck_score=1.0,
        anomaly_flag=True,
    )


# ══════════════════════════════════════════════════════════════════════
# Vertex AI Feature Matrix Fixtures
# ══════════════════════════════════════════════════════════════════════

@pytest.fixture
def valid_feature_matrix() -> np.ndarray:
    """Valid (150, 12) feature matrix with realistic values."""
    rng = np.random.default_rng(42)
    matrix = np.zeros((150, 12), dtype=np.float32)
    matrix[:, 0] = rng.uniform(0.0, 1.0, 150)      # density_norm [0,1]
    matrix[:, 1] = rng.uniform(-2.0, 2.0, 150)      # velocity_x
    matrix[:, 2] = rng.uniform(-2.0, 2.0, 150)      # velocity_y
    matrix[:, 3] = rng.uniform(0.0, 5.0, 150)       # speed_p95
    matrix[:, 4] = rng.uniform(0.0, 360.0, 150)     # heading_deg
    matrix[:, 5] = rng.uniform(0.0, 1.0, 150)       # dwell_ratio
    matrix[:, 6] = rng.uniform(0.0, 50.0, 150)      # flow_variance
    matrix[:, 7] = rng.uniform(0.0, 1.0, 150)       # bottleneck_score
    matrix[:, 8] = rng.uniform(0.0, 23.0, 150)      # hour_of_day
    matrix[:, 9] = rng.choice([0, 1], 150).astype(np.float32)
    matrix[:, 10] = rng.choice([0, 1], 150).astype(np.float32)
    matrix[:, 11] = rng.choice([0, 1], 150).astype(np.float32)
    return matrix


@pytest.fixture
def free_flow_matrix() -> np.ndarray:
    """Free-flow feature matrix: stable low density."""
    matrix = np.zeros((150, 12), dtype=np.float32)
    matrix[:, 0] = np.linspace(0.05, 0.15, 150)  # Low density
    matrix[:, 1] = 1.0    # velocity_x
    matrix[:, 2] = 0.5    # velocity_y
    matrix[:, 3] = 1.4    # speed_p95 (free-flow walk ~1.4 m/s)
    matrix[:, 4] = 90.0   # heading_deg
    matrix[:, 5] = 0.05   # dwell_ratio (almost nobody standing)
    matrix[:, 6] = 0.2    # flow_variance
    matrix[:, 7] = 0.08   # bottleneck_score
    matrix[:, 8] = 10.0   # hour_of_day (pre-event)
    matrix[:, 9] = 1.0    # phase_pre
    matrix[:, 10] = 0.0
    matrix[:, 11] = 0.0
    return matrix


@pytest.fixture
def halftime_surge_matrix() -> np.ndarray:
    """Halftime egress surge: density ramps sharply 0.3 → 0.9."""
    matrix = np.zeros((150, 12), dtype=np.float32)
    # Exponential ramp simulating crowd emptying stands
    t = np.linspace(0, 5, 150)
    matrix[:, 0] = 0.3 + 0.6 * (1 - np.exp(-t))  # density_norm
    matrix[:, 1] = np.linspace(1.0, 0.1, 150)     # velocity_x slows
    matrix[:, 2] = np.linspace(0.5, 0.05, 150)    # velocity_y slows
    matrix[:, 3] = np.linspace(1.4, 0.3, 150)     # speed_p95 crashes
    matrix[:, 4] = 180.0                           # heading south (egress)
    matrix[:, 5] = np.linspace(0.1, 0.85, 150)    # dwell_ratio rises
    matrix[:, 6] = np.linspace(0.5, 15.0, 150)    # flow variance spikes
    matrix[:, 7] = np.linspace(0.1, 0.92, 150)    # bottleneck ramps
    matrix[:, 8] = 14.5                            # halftime hour
    matrix[:, 9] = 0.0
    matrix[:, 10] = 0.0
    matrix[:, 11] = 1.0   # phase_halftime
    return matrix


@pytest.fixture
def goal_surge_matrix() -> np.ndarray:
    """Goal-scored surge: sudden step-change in density mid-window."""
    matrix = np.zeros((150, 12), dtype=np.float32)
    # Stable low density, then step change at tick 75
    matrix[:75, 0] = 0.25
    matrix[75:, 0] = 0.85  # Sudden jump (crowd reaction)
    matrix[:, 1] = 0.5
    matrix[:, 2] = 0.3
    matrix[:, 3] = 1.0
    matrix[:, 4] = 45.0
    matrix[:75, 5] = 0.2
    matrix[75:, 5] = 0.7   # Dwell spikes after goal
    matrix[:, 6] = 3.0
    matrix[:75, 7] = 0.15
    matrix[75:, 7] = 0.6
    matrix[:, 8] = 13.0    # active event
    matrix[:, 9] = 0.0
    matrix[:, 10] = 1.0    # phase_active
    matrix[:, 11] = 0.0
    return matrix


@pytest.fixture
def evacuation_matrix() -> np.ndarray:
    """Emergency evacuation simulation: extreme density spike."""
    matrix = np.zeros((150, 12), dtype=np.float32)
    # Density ramps to near-crush, then stays critical
    t = np.linspace(0, 3, 150)
    matrix[:, 0] = np.minimum(0.95, 0.2 + 0.8 * (1 - np.exp(-2 * t)))
    matrix[:, 1] = np.linspace(0.8, 0.0, 150)    # Movement stops
    matrix[:, 2] = np.linspace(0.4, 0.0, 150)
    matrix[:, 3] = np.linspace(1.2, 0.1, 150)
    matrix[:, 4] = 0.0                            # heading north (exit)
    matrix[:, 5] = np.linspace(0.2, 0.98, 150)   # Nearly everyone stuck
    matrix[:, 6] = np.linspace(1.0, 25.0, 150)   # Extreme turbulence
    matrix[:, 7] = np.linspace(0.3, 0.99, 150)   # Near-gridlock
    matrix[:, 8] = 16.0                           # post-event
    matrix[:, 9] = 0.0
    matrix[:, 10] = 0.0
    matrix[:, 11] = 0.0  # phase_post (packed as implicit class)
    return matrix


# ══════════════════════════════════════════════════════════════════════
# Key Rotation Fixtures
# ══════════════════════════════════════════════════════════════════════

@pytest.fixture
def key_service() -> KeyRotationService:
    """Fresh KeyRotationService with 10-second TTL for fast test rotation."""
    return KeyRotationService(venue_id="test_venue", ttl_seconds=10)


# ══════════════════════════════════════════════════════════════════════
# Anomaly Baseline Fixtures
# ══════════════════════════════════════════════════════════════════════

@pytest.fixture
def stable_baseline_densities() -> list[float]:
    """15-minute stable baseline: 450 ticks of density ≈ 2.0 ± 0.1."""
    rng = np.random.default_rng(99)
    return list(rng.normal(loc=2.0, scale=0.1, size=450).clip(0.0, 6.5))


@pytest.fixture
def anomalous_density(stable_baseline_densities: list[float]) -> float:
    """A density value > 2σ above the baseline mean."""
    mean = statistics.mean(stable_baseline_densities)
    stdev = statistics.stdev(stable_baseline_densities)
    return mean + 2.5 * stdev  # Clearly above 2σ threshold


@pytest.fixture
def normal_density(stable_baseline_densities: list[float]) -> float:
    """A density value within 1σ of the baseline mean."""
    mean = statistics.mean(stable_baseline_densities)
    stdev = statistics.stdev(stable_baseline_densities)
    return mean + 0.5 * stdev  # Well within normal range


# ══════════════════════════════════════════════════════════════════════
# Parametrize helpers
# ══════════════════════════════════════════════════════════════════════

def make_vector(
    density: float = 0.0,
    dwell: float = 0.0,
    bottleneck: float = 0.0,
    **kwargs: Any,
) -> CrowdVelocityVector:
    """Factory for CrowdVelocityVector with sensible defaults."""
    defaults = dict(
        zone_id="test_zone",
        sector_hash="ab" * 32,
        timestamp_ms=1_700_000_000_000,
        density_ppm2=density,
        dwell_ratio=dwell,
        bottleneck_score=bottleneck,
    )
    defaults.update(kwargs)
    return CrowdVelocityVector(**defaults)
