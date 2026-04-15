"""AVCP CrowdPredictor — Vertex AI serving client with circuit breaker.

Stateless. Thread-safe. One instance per edge node.

Features:
- Full input validation (shape, dtype, value range checks)
- Circuit breaker: auto-fallback to LinearRegressionFallback when
  P99 latency > 80ms or error rate > 5% over a 60s rolling window
- Prometheus metrics: prediction_latency_ms, model_confidence,
  circuit_breaker_state

Usage:
    predictor = CrowdPredictor(
        endpoint_id="12345",
        project="avcp-prod",
        location="us-central1",
    )
    result = predictor.predict(feature_matrix)
    # → {"density_60s": 3.2, "density_300s": 4.1, "confidence": 0.87}
"""

from __future__ import annotations

import enum
import logging
import threading
import time
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np
import yaml

try:
    from google.cloud import aiplatform
except ImportError:
    aiplatform = None  # type: ignore[assignment]

try:
    from prometheus_client import Gauge, Histogram
except ImportError:
    # Graceful degradation: no-op metrics if prometheus_client not installed
    class _NoOpMetric:
        def __init__(self, *a: Any, **kw: Any) -> None: ...
        def observe(self, *a: Any, **kw: Any) -> None: ...
        def set(self, *a: Any, **kw: Any) -> None: ...
        def labels(self, **kw: Any) -> "_NoOpMetric":
            return self

    Histogram = _NoOpMetric  # type: ignore[misc, assignment]
    Gauge = _NoOpMetric  # type: ignore[misc, assignment]


logger = logging.getLogger(__name__)

# ── Load Config ──────────────────────────────────────────────────────

_CONFIG_PATH = Path(__file__).parent / "model_config.yaml"


def _load_config() -> dict[str, Any]:
    with open(_CONFIG_PATH) as f:
        return yaml.safe_load(f)


_CONFIG = _load_config()
_INPUT_CFG = _CONFIG["input"]
_SERVING_CFG = _CONFIG["serving"]
_CB_CFG = _SERVING_CFG["circuit_breaker"]

# ── Prometheus Metrics ───────────────────────────────────────────────

PREDICTION_LATENCY = Histogram(
    "avcp_prediction_latency_ms",
    "Prediction latency in milliseconds",
    buckets=[5, 10, 20, 40, 60, 80, 100, 150, 200, 500],
)

MODEL_CONFIDENCE = Histogram(
    "avcp_model_confidence",
    "Model confidence score distribution",
    buckets=[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0],
)

CIRCUIT_BREAKER_STATE = Gauge(
    "avcp_circuit_breaker_state",
    "Circuit breaker state: 0=closed, 1=open, 2=half-open",
)


# ══════════════════════════════════════════════════════════════════════
# Circuit Breaker
# ══════════════════════════════════════════════════════════════════════

class CircuitState(enum.Enum):
    """Circuit breaker states."""

    CLOSED = 0       # Normal operation — requests go to Vertex AI
    OPEN = 1         # Tripped — all requests go to fallback
    HALF_OPEN = 2    # Testing — single request to Vertex AI


@dataclass
class _RequestRecord:
    """Record of a single prediction request for circuit breaker tracking."""

    timestamp: float
    latency_ms: float
    is_error: bool


class CircuitBreaker:
    """Rolling-window circuit breaker for Vertex AI endpoint.

    Opens (trips) when over a 60s rolling window:
    - P99 latency exceeds 80ms, OR
    - Error rate exceeds 5%

    Transitions to HALF_OPEN after 30s, allowing a single test request.
    If the test succeeds under thresholds, closes. Otherwise, re-opens.
    """

    def __init__(
        self,
        latency_threshold_ms: float = _CB_CFG["latency_threshold_ms"],
        error_rate_threshold: float = _CB_CFG["error_rate_threshold"],
        rolling_window_s: float = _CB_CFG["rolling_window_seconds"],
        half_open_after_s: float = _CB_CFG["half_open_after_seconds"],
        min_requests: int = _CB_CFG["min_requests_in_window"],
    ) -> None:
        self.latency_threshold_ms = latency_threshold_ms
        self.error_rate_threshold = error_rate_threshold
        self.rolling_window_s = rolling_window_s
        self.half_open_after_s = half_open_after_s
        self.min_requests = min_requests

        self._state = CircuitState.CLOSED
        self._records: deque[_RequestRecord] = deque()
        self._opened_at: float = 0.0
        self._lock = threading.Lock()

    @property
    def state(self) -> CircuitState:
        with self._lock:
            if self._state == CircuitState.OPEN:
                # Check if we should transition to HALF_OPEN
                if time.monotonic() - self._opened_at >= self.half_open_after_s:
                    self._state = CircuitState.HALF_OPEN
                    CIRCUIT_BREAKER_STATE.set(CircuitState.HALF_OPEN.value)
                    logger.info("Circuit breaker → HALF_OPEN (testing)")
            return self._state

    def record(self, latency_ms: float, is_error: bool) -> None:
        """Record a request outcome and evaluate circuit state."""
        now = time.monotonic()
        record = _RequestRecord(
            timestamp=now, latency_ms=latency_ms, is_error=is_error,
        )

        with self._lock:
            self._records.append(record)
            self._prune_old(now)

            if self._state == CircuitState.HALF_OPEN:
                if is_error or latency_ms > self.latency_threshold_ms:
                    self._trip(now)
                else:
                    self._close()
                return

            if self._state == CircuitState.CLOSED:
                self._evaluate(now)

    def _prune_old(self, now: float) -> None:
        cutoff = now - self.rolling_window_s
        while self._records and self._records[0].timestamp < cutoff:
            self._records.popleft()

    def _evaluate(self, now: float) -> None:
        if len(self._records) < self.min_requests:
            return

        latencies = sorted(r.latency_ms for r in self._records)
        p99_idx = int(len(latencies) * 0.99)
        p99_latency = latencies[min(p99_idx, len(latencies) - 1)]

        errors = sum(1 for r in self._records if r.is_error)
        error_rate = errors / len(self._records)

        if p99_latency > self.latency_threshold_ms:
            logger.warning(
                "Circuit breaker TRIP: P99 latency %.1fms > %.1fms threshold",
                p99_latency,
                self.latency_threshold_ms,
            )
            self._trip(now)
        elif error_rate > self.error_rate_threshold:
            logger.warning(
                "Circuit breaker TRIP: error rate %.1f%% > %.1f%% threshold",
                error_rate * 100,
                self.error_rate_threshold * 100,
            )
            self._trip(now)

    def _trip(self, now: float) -> None:
        self._state = CircuitState.OPEN
        self._opened_at = now
        CIRCUIT_BREAKER_STATE.set(CircuitState.OPEN.value)
        logger.warning("Circuit breaker → OPEN (fallback active)")

    def _close(self) -> None:
        self._state = CircuitState.CLOSED
        self._records.clear()
        CIRCUIT_BREAKER_STATE.set(CircuitState.CLOSED.value)
        logger.info("Circuit breaker → CLOSED (Vertex AI restored)")


# ══════════════════════════════════════════════════════════════════════
# Input Validation
# ══════════════════════════════════════════════════════════════════════

class InputValidationError(ValueError):
    """Raised when prediction input fails validation."""


def validate_input(feature_matrix: np.ndarray) -> None:
    """Validate feature matrix shape, dtype, and value ranges.

    Args:
        feature_matrix: Expected shape (150, 12), dtype float32/float64.

    Raises:
        InputValidationError: On any validation failure.
    """
    expected_shape = (_INPUT_CFG["timesteps"], _INPUT_CFG["features"])

    # Shape check
    if feature_matrix.shape != expected_shape:
        raise InputValidationError(
            f"Input shape {feature_matrix.shape} != expected {expected_shape}"
        )

    # Dtype check
    if not np.issubdtype(feature_matrix.dtype, np.floating):
        raise InputValidationError(
            f"Input dtype {feature_matrix.dtype} is not floating-point. "
            f"Expected float32 or float64."
        )

    # NaN/Inf check
    if np.isnan(feature_matrix).any():
        raise InputValidationError("Input contains NaN values")
    if np.isinf(feature_matrix).any():
        raise InputValidationError("Input contains Inf values")

    # Value range checks per feature column
    ranges = _INPUT_CFG.get("value_ranges", {})
    feature_names = _INPUT_CFG["feature_names"]
    for i, name in enumerate(feature_names):
        if i >= feature_matrix.shape[1]:
            break
        if name in ranges:
            lo, hi = ranges[name]
            col = feature_matrix[:, i]
            if col.min() < lo - 0.01 or col.max() > hi + 0.01:
                raise InputValidationError(
                    f"Feature '{name}' (col {i}): values [{col.min():.3f}, "
                    f"{col.max():.3f}] outside allowed range [{lo}, {hi}]"
                )


# ══════════════════════════════════════════════════════════════════════
# Fallback Model
# ══════════════════════════════════════════════════════════════════════

class LinearRegressionFallback:
    """On-device cached linear regression fallback.

    Used when the circuit breaker trips (Vertex AI unavailable or slow).
    Simple exponential smoothing on the last N density values to produce
    T+60s and T+300s forecasts.
    """

    def predict(self, feature_matrix: np.ndarray) -> dict[str, float]:
        """Predict using exponential smoothing on density column.

        Args:
            feature_matrix: shape (150, 12)

        Returns:
            Prediction dict with density_60s, density_300s, confidence.
        """
        density_col = feature_matrix[:, 0]  # density_norm (column 0)
        k_jam = _CONFIG["features"]["normalization"]["density_k_jam"]

        # Exponential smoothing
        alpha = 0.3
        smoothed = density_col[0]
        for val in density_col[1:]:
            smoothed = alpha * val + (1 - alpha) * smoothed

        # Trend: slope of last 30 ticks (1 minute)
        recent = density_col[-30:]
        if len(recent) > 1:
            trend = (recent[-1] - recent[0]) / len(recent)
        else:
            trend = 0.0

        # Forecast (in normalized units, convert back to p/m²)
        density_60s = max(0.0, (smoothed + trend * 30) * k_jam)   # +60s
        density_300s = max(0.0, (smoothed + trend * 150) * k_jam)  # +300s

        return {
            "density_60s": min(density_60s, k_jam),
            "density_300s": min(density_300s, k_jam),
            "confidence": 0.45,  # Low confidence flag for fallback
        }


# ══════════════════════════════════════════════════════════════════════
# CrowdPredictor
# ══════════════════════════════════════════════════════════════════════

class CrowdPredictor:
    """Stateless, thread-safe Vertex AI prediction client.

    One instance per edge node. All inputs are float32 vectors —
    zero string fields.

    Features:
    - Full input validation (shape, dtype, ranges)
    - Circuit breaker with LinearRegressionFallback
    - Prometheus metrics (latency, confidence, circuit state)

    Args:
        endpoint_id: Vertex AI endpoint numeric ID.
        project: GCP project ID.
        location: GCP region (e.g., "us-central1").
    """

    def __init__(
        self,
        endpoint_id: str,
        project: str,
        location: str,
    ) -> None:
        if aiplatform is None:
            raise RuntimeError(
                "google-cloud-aiplatform is required. "
                "Install with: pip install google-cloud-aiplatform"
            )

        self._endpoint = aiplatform.Endpoint(
            endpoint_name=(
                f"projects/{project}/locations/{location}"
                f"/endpoints/{endpoint_id}"
            )
        )
        self._circuit_breaker = CircuitBreaker()
        self._fallback = LinearRegressionFallback()

    @property
    def circuit_state(self) -> CircuitState:
        """Current circuit breaker state."""
        return self._circuit_breaker.state

    def predict(self, feature_matrix: np.ndarray) -> dict[str, float]:
        """Run prediction with circuit breaker protection.

        Args:
            feature_matrix: shape (150, 12) — 5 min @ 2s ticks.

        Returns:
            {
                "density_60s": float,   # Predicted density @ T+60s
                "density_300s": float,  # Predicted density @ T+5min
                "confidence": float,    # Model confidence [0, 1]
            }

        Raises:
            InputValidationError: If input fails shape/dtype/range checks.
        """
        # ── Input validation ─────────────────────────────────────────
        validate_input(feature_matrix)

        # ── Circuit breaker routing ──────────────────────────────────
        state = self._circuit_breaker.state

        if state == CircuitState.OPEN:
            logger.debug("Circuit OPEN — routing to fallback")
            return self._fallback.predict(feature_matrix)

        # CLOSED or HALF_OPEN — try Vertex AI
        try:
            result = self._predict_vertex(feature_matrix)
            return result
        except Exception:
            logger.exception("Vertex AI prediction failed")
            return self._fallback.predict(feature_matrix)

    def _predict_vertex(self, feature_matrix: np.ndarray) -> dict[str, float]:
        """Call Vertex AI endpoint and track metrics."""
        instances = [{"inputs": feature_matrix.astype(np.float32).tolist()}]

        start = time.monotonic()
        try:
            response = self._endpoint.predict(instances=instances)
            latency_ms = (time.monotonic() - start) * 1000
            is_error = False
        except Exception as exc:
            latency_ms = (time.monotonic() - start) * 1000
            self._circuit_breaker.record(latency_ms, is_error=True)
            PREDICTION_LATENCY.observe(latency_ms)
            raise exc

        # Record success
        self._circuit_breaker.record(latency_ms, is_error=False)
        PREDICTION_LATENCY.observe(latency_ms)

        pred = response.predictions[0]
        confidence = float(pred.get("confidence", 0.0))
        MODEL_CONFIDENCE.observe(confidence)

        return {
            "density_60s": float(pred["density_60s"]),
            "density_300s": float(pred["density_300s"]),
            "confidence": confidence,
        }


# ══════════════════════════════════════════════════════════════════════
# PII Assertion (importable by tests)
# ══════════════════════════════════════════════════════════════════════

def assert_no_pii_columns(columns: list[str]) -> None:
    """Assert that no PII columns are present in the given column list.

    Raises:
        ValueError: If any forbidden PII column is found.
    """
    forbidden = set(_CONFIG["pii_forbidden_columns"])
    violations = set(c.lower() for c in columns) & {f.lower() for f in forbidden}
    if violations:
        raise ValueError(
            f"PII columns detected: {sorted(violations)}. "
            f"Remove before model input."
        )
