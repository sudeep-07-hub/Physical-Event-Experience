"""Test 4 — Circuit breaker activation.

Mock Vertex endpoint to return errors consistently.
Assert CrowdPredictor activates circuit breaker and falls back to
LinearRegressionFallback. Assert circuit_breaker_state == OPEN.
"""

from __future__ import annotations

import time
from unittest.mock import MagicMock, patch

import numpy as np
import pytest

from avcp.vertex.crowd_predictor import (
    CircuitBreaker,
    CircuitState,
    InputValidationError,
    LinearRegressionFallback,
    validate_input,
)


class TestCircuitBreakerActivation:
    """Circuit breaker must trip and route to fallback on endpoint failure."""

    def test_trips_on_consistent_timeout(self) -> None:
        """Simulates Vertex endpoint returning HTTP 504 (high latency)."""
        cb = CircuitBreaker(
            latency_threshold_ms=80.0,
            error_rate_threshold=0.05,
            rolling_window_s=60.0,
            half_open_after_s=0.1,
            min_requests=5,
        )

        # Simulate 10 requests all exceeding 80ms (504 gateway timeout)
        for _ in range(10):
            cb.record(latency_ms=150.0, is_error=True)

        assert cb.state == CircuitState.OPEN, (
            "Circuit breaker should be OPEN after consistent timeouts"
        )

    def test_fallback_returns_valid_prediction(
        self, valid_feature_matrix: np.ndarray,
    ) -> None:
        """When circuit is OPEN, fallback must produce valid output."""
        fallback = LinearRegressionFallback()
        result = fallback.predict(valid_feature_matrix)

        assert "density_60s" in result
        assert "density_300s" in result
        assert "confidence" in result
        assert result["confidence"] == 0.45  # Fallback confidence flag
        assert 0.0 <= result["density_60s"] <= 6.5
        assert 0.0 <= result["density_300s"] <= 6.5

    def test_trips_on_error_rate(self) -> None:
        """5%+ error rate should trigger circuit breaker."""
        cb = CircuitBreaker(
            latency_threshold_ms=80.0,
            error_rate_threshold=0.05,
            rolling_window_s=60.0,
            min_requests=10,
        )

        # 8 successes + 3 errors = 27% error rate >> 5%
        for _ in range(8):
            cb.record(latency_ms=20.0, is_error=False)
        for _ in range(3):
            cb.record(latency_ms=20.0, is_error=True)

        assert cb.state == CircuitState.OPEN

    def test_half_open_recovery(self) -> None:
        """After half_open_after_s, circuit moves to HALF_OPEN.
        A successful request then closes it."""
        cb = CircuitBreaker(
            latency_threshold_ms=50.0,
            half_open_after_s=0.1,
            min_requests=5,
        )

        # Trip
        for _ in range(10):
            cb.record(latency_ms=100.0, is_error=False)
        assert cb.state == CircuitState.OPEN

        # Wait for HALF_OPEN
        time.sleep(0.15)
        assert cb.state == CircuitState.HALF_OPEN

        # Successful request → CLOSED
        cb.record(latency_ms=20.0, is_error=False)
        assert cb.state == CircuitState.CLOSED

    def test_half_open_failure_reopens(self) -> None:
        """Failed request in HALF_OPEN → back to OPEN."""
        cb = CircuitBreaker(
            latency_threshold_ms=50.0,
            half_open_after_s=0.1,
            min_requests=5,
        )

        # Trip
        for _ in range(10):
            cb.record(latency_ms=100.0, is_error=False)

        # Wait for HALF_OPEN
        time.sleep(0.15)
        assert cb.state == CircuitState.HALF_OPEN

        # Failed test request in HALF_OPEN → OPEN again
        cb.record(latency_ms=200.0, is_error=True)
        assert cb.state == CircuitState.OPEN

    def test_surge_scenario_fallback(
        self, halftime_surge_matrix: np.ndarray,
    ) -> None:
        """Fallback prediction on surge data must produce elevated density."""
        fallback = LinearRegressionFallback()
        result = fallback.predict(halftime_surge_matrix)
        # Halftime surge: density should be elevated
        assert result["density_60s"] > 1.0
        assert result["density_300s"] > 0.5

    def test_input_validation_rejects_bad_shape(self) -> None:
        """Input validation must reject non-(150,12) matrices."""
        with pytest.raises(InputValidationError, match="shape"):
            validate_input(np.zeros((100, 12), dtype=np.float32))

    def test_input_validation_rejects_nan(
        self, valid_feature_matrix: np.ndarray,
    ) -> None:
        """NaN values must be rejected."""
        bad = valid_feature_matrix.copy()
        bad[50, 3] = np.nan
        with pytest.raises(InputValidationError, match="NaN"):
            validate_input(bad)
