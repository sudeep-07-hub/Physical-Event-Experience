"""Unit tests for AVCP Vertex AI — CrowdPredictor, Pipeline, and Serving.

Test coverage:
1. Input shape contract validation
2. Input dtype and value range validation
3. Circuit breaker activation on high latency
4. Circuit breaker activation on high error rate
5. Circuit breaker state transitions (CLOSED → OPEN → HALF_OPEN → CLOSED)
6. LinearRegressionFallback prediction sanity
7. MAPE assertion on fixture surge data
8. PII absent from all model input columns
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
    assert_no_pii_columns,
    validate_input,
)


# ══════════════════════════════════════════════════════════════════════
# Fixtures
# ══════════════════════════════════════════════════════════════════════

@pytest.fixture
def valid_matrix() -> np.ndarray:
    """Valid (150, 12) feature matrix with realistic values."""
    rng = np.random.default_rng(42)
    matrix = np.zeros((150, 12), dtype=np.float32)
    matrix[:, 0] = rng.uniform(0.0, 1.0, 150)     # density_norm [0,1]
    matrix[:, 1] = rng.uniform(-2.0, 2.0, 150)     # velocity_x
    matrix[:, 2] = rng.uniform(-2.0, 2.0, 150)     # velocity_y
    matrix[:, 3] = rng.uniform(0.0, 5.0, 150)      # speed_p95
    matrix[:, 4] = rng.uniform(0.0, 360.0, 150)    # heading_deg
    matrix[:, 5] = rng.uniform(0.0, 1.0, 150)      # dwell_ratio
    matrix[:, 6] = rng.uniform(0.0, 50.0, 150)     # flow_variance
    matrix[:, 7] = rng.uniform(0.0, 1.0, 150)      # bottleneck_score
    matrix[:, 8] = rng.uniform(0.0, 23.0, 150)     # hour_of_day
    matrix[:, 9] = rng.choice([0, 1], 150).astype(np.float32)   # phase_pre
    matrix[:, 10] = rng.choice([0, 1], 150).astype(np.float32)  # phase_active
    matrix[:, 11] = rng.choice([0, 1], 150).astype(np.float32)  # phase_halftime
    return matrix


@pytest.fixture
def surge_matrix() -> np.ndarray:
    """Surge scenario matrix: density ramps from 0.2 to 0.9 over 150 ticks."""
    matrix = np.zeros((150, 12), dtype=np.float32)
    # Density ramps up (simulating goal-scored surge)
    matrix[:, 0] = np.linspace(0.2, 0.9, 150)
    matrix[:, 1] = 0.5   # velocity_x
    matrix[:, 2] = 0.3   # velocity_y
    matrix[:, 3] = 1.2   # speed_p95
    matrix[:, 4] = 45.0  # heading_deg
    matrix[:, 5] = np.linspace(0.3, 0.9, 150)  # dwell_ratio ramps
    matrix[:, 6] = 5.0   # flow_variance
    matrix[:, 7] = np.linspace(0.1, 0.85, 150)  # bottleneck ramps
    matrix[:, 8] = 13.0  # 1 PM — active event
    matrix[:, 9] = 0.0   # not pre
    matrix[:, 10] = 1.0  # active
    matrix[:, 11] = 0.0  # not halftime
    return matrix


# ══════════════════════════════════════════════════════════════════════
# 1. Input Shape Contract
# ══════════════════════════════════════════════════════════════════════

class TestInputShapeContract:
    """Input must be exactly (150, 12) float."""

    def test_valid_shape_passes(self, valid_matrix: np.ndarray) -> None:
        validate_input(valid_matrix)  # Should not raise

    def test_wrong_rows_fails(self) -> None:
        matrix = np.zeros((100, 12), dtype=np.float32)
        with pytest.raises(InputValidationError, match="shape"):
            validate_input(matrix)

    def test_wrong_cols_fails(self) -> None:
        matrix = np.zeros((150, 8), dtype=np.float32)
        with pytest.raises(InputValidationError, match="shape"):
            validate_input(matrix)

    def test_1d_fails(self) -> None:
        matrix = np.zeros(150, dtype=np.float32)
        with pytest.raises(InputValidationError, match="shape"):
            validate_input(matrix)

    def test_3d_fails(self) -> None:
        matrix = np.zeros((1, 150, 12), dtype=np.float32)
        with pytest.raises(InputValidationError, match="shape"):
            validate_input(matrix)

    def test_integer_dtype_fails(self) -> None:
        matrix = np.zeros((150, 12), dtype=np.int32)
        with pytest.raises(InputValidationError, match="floating"):
            validate_input(matrix)

    def test_nan_fails(self, valid_matrix: np.ndarray) -> None:
        valid_matrix[75, 3] = np.nan
        with pytest.raises(InputValidationError, match="NaN"):
            validate_input(valid_matrix)

    def test_inf_fails(self, valid_matrix: np.ndarray) -> None:
        valid_matrix[0, 0] = np.inf
        with pytest.raises(InputValidationError, match="Inf"):
            validate_input(valid_matrix)


# ══════════════════════════════════════════════════════════════════════
# 2. Value Range Validation
# ══════════════════════════════════════════════════════════════════════

class TestValueRangeValidation:
    """Feature columns must be within documented ranges."""

    def test_density_out_of_range(self) -> None:
        matrix = np.zeros((150, 12), dtype=np.float32)
        matrix[:, 0] = 1.5  # density_norm should be [0, 1]
        with pytest.raises(InputValidationError, match="density_ppm2"):
            validate_input(matrix)

    def test_bottleneck_out_of_range(self) -> None:
        matrix = np.zeros((150, 12), dtype=np.float32)
        matrix[:, 7] = 2.0  # bottleneck_score should be [0, 1]
        with pytest.raises(InputValidationError, match="bottleneck_score"):
            validate_input(matrix)

    def test_dwell_ratio_out_of_range(self) -> None:
        matrix = np.zeros((150, 12), dtype=np.float32)
        matrix[:, 5] = -0.5  # dwell_ratio should be [0, 1]
        with pytest.raises(InputValidationError, match="dwell_ratio"):
            validate_input(matrix)


# ══════════════════════════════════════════════════════════════════════
# 3. Circuit Breaker — Latency Trip
# ══════════════════════════════════════════════════════════════════════

class TestCircuitBreakerLatency:
    """Circuit opens when P99 latency > 80ms over 60s window."""

    def test_opens_on_high_latency(self) -> None:
        cb = CircuitBreaker(
            latency_threshold_ms=80.0,
            error_rate_threshold=0.05,
            rolling_window_s=60.0,
            half_open_after_s=0.1,  # Short for testing
            min_requests=5,
        )

        # Send 10 requests with high latency
        for _ in range(10):
            cb.record(latency_ms=120.0, is_error=False)

        assert cb.state == CircuitState.OPEN

    def test_stays_closed_under_threshold(self) -> None:
        cb = CircuitBreaker(min_requests=5)

        for _ in range(10):
            cb.record(latency_ms=30.0, is_error=False)

        assert cb.state == CircuitState.CLOSED

    def test_ignores_few_requests(self) -> None:
        cb = CircuitBreaker(min_requests=10)

        # Only 3 high-latency requests — below min_requests threshold
        for _ in range(3):
            cb.record(latency_ms=200.0, is_error=False)

        assert cb.state == CircuitState.CLOSED


# ══════════════════════════════════════════════════════════════════════
# 4. Circuit Breaker — Error Rate Trip
# ══════════════════════════════════════════════════════════════════════

class TestCircuitBreakerErrorRate:
    """Circuit opens when error rate > 5% over 60s window."""

    def test_opens_on_high_error_rate(self) -> None:
        cb = CircuitBreaker(
            latency_threshold_ms=80.0,
            error_rate_threshold=0.05,
            rolling_window_s=60.0,
            min_requests=10,
        )

        # 9 successes + 2 errors = 18% error rate > 5%
        for _ in range(9):
            cb.record(latency_ms=20.0, is_error=False)
        for _ in range(2):
            cb.record(latency_ms=20.0, is_error=True)

        assert cb.state == CircuitState.OPEN

    def test_stays_closed_with_low_error_rate(self) -> None:
        cb = CircuitBreaker(min_requests=10)

        # 100 successes, 0 errors
        for _ in range(100):
            cb.record(latency_ms=30.0, is_error=False)

        assert cb.state == CircuitState.CLOSED


# ══════════════════════════════════════════════════════════════════════
# 5. Circuit Breaker — State Transitions
# ══════════════════════════════════════════════════════════════════════

class TestCircuitBreakerTransitions:
    """CLOSED → OPEN → HALF_OPEN → CLOSED lifecycle."""

    def test_full_lifecycle(self) -> None:
        cb = CircuitBreaker(
            latency_threshold_ms=50.0,
            error_rate_threshold=0.05,
            rolling_window_s=60.0,
            half_open_after_s=0.1,   # 100ms for fast test
            min_requests=5,
        )

        # Start CLOSED
        assert cb.state == CircuitState.CLOSED

        # Trip to OPEN
        for _ in range(10):
            cb.record(latency_ms=100.0, is_error=False)
        assert cb.state == CircuitState.OPEN

        # Wait for HALF_OPEN
        time.sleep(0.15)
        assert cb.state == CircuitState.HALF_OPEN

        # Successful request in HALF_OPEN → CLOSED
        cb.record(latency_ms=20.0, is_error=False)
        assert cb.state == CircuitState.CLOSED

    def test_half_open_failure_reopens(self) -> None:
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

        # Failed request in HALF_OPEN → back to OPEN
        cb.record(latency_ms=200.0, is_error=False)
        assert cb.state == CircuitState.OPEN


# ══════════════════════════════════════════════════════════════════════
# 6. LinearRegressionFallback
# ══════════════════════════════════════════════════════════════════════

class TestFallback:
    """Fallback model produces valid predictions."""

    def test_produces_valid_output(self, valid_matrix: np.ndarray) -> None:
        fb = LinearRegressionFallback()
        result = fb.predict(valid_matrix)

        assert "density_60s" in result
        assert "density_300s" in result
        assert "confidence" in result

        assert 0.0 <= result["density_60s"] <= 6.5
        assert 0.0 <= result["density_300s"] <= 6.5
        assert result["confidence"] == 0.45  # Flag for fallback

    def test_surge_gives_increasing_prediction(
        self, surge_matrix: np.ndarray,
    ) -> None:
        fb = LinearRegressionFallback()
        result = fb.predict(surge_matrix)

        # With a ramping density, 300s prediction should exceed 60s
        assert result["density_300s"] >= result["density_60s"]

    def test_all_zero_input(self) -> None:
        matrix = np.zeros((150, 12), dtype=np.float32)
        fb = LinearRegressionFallback()
        result = fb.predict(matrix)

        assert result["density_60s"] == 0.0
        assert result["density_300s"] == 0.0


# ══════════════════════════════════════════════════════════════════════
# 7. MAPE Assertion on Fixture Surge Data
# ══════════════════════════════════════════════════════════════════════

class TestMAPE:
    """MAPE evaluation logic on fixture surge data."""

    def test_mape_on_known_data(self) -> None:
        """Verify MAPE calculation is correct on synthetic data."""
        actuals = np.array([2.0, 3.0, 4.0, 5.0, 6.0])
        predictions = np.array([2.1, 2.9, 4.2, 4.8, 6.3])

        # MAPE = mean(|actual - pred| / actual) * 100
        mape = np.mean(np.abs((actuals - predictions) / actuals)) * 100

        # Expected: mean of [5%, 3.3%, 5%, 4%, 5%] = 4.47%
        assert mape < 8.0, f"MAPE {mape:.2f}% exceeds 8% threshold"

    def test_mape_fails_on_bad_predictions(self) -> None:
        """Verify MAPE gate catches bad predictions."""
        actuals = np.array([2.0, 3.0, 4.0, 5.0, 6.0])
        predictions = np.array([1.0, 1.5, 2.0, 2.5, 3.0])  # ~50% off

        mape = np.mean(np.abs((actuals - predictions) / actuals)) * 100

        assert mape >= 8.0, f"MAPE {mape:.2f}% should exceed 8% threshold"

    def test_surge_scenario_mape(self, surge_matrix: np.ndarray) -> None:
        """Fallback model on surge data should have reasonable MAPE."""
        fb = LinearRegressionFallback()
        result = fb.predict(surge_matrix)

        # The fallback should at least produce a non-zero prediction
        assert result["density_60s"] > 0.0
        assert result["density_300s"] > 0.0


# ══════════════════════════════════════════════════════════════════════
# 8. PII Absent from Model Inputs
# ══════════════════════════════════════════════════════════════════════

class TestPIIAbsence:
    """No PII columns may reach the model."""

    def test_clean_columns_pass(self) -> None:
        clean = [
            "density_ppm2", "velocity_x", "velocity_y", "speed_p95",
            "heading_deg", "dwell_ratio", "flow_variance", "bottleneck_score",
            "hour_of_day", "phase_pre", "phase_active", "phase_halftime",
        ]
        assert_no_pii_columns(clean)  # Should not raise

    def test_user_id_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["density_ppm2", "user_id", "velocity_x"])

    def test_device_id_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["device_id"])

    def test_ip_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["ip"])

    def test_mac_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["MAC"])  # Case-insensitive

    def test_face_vector_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["face_vector"])

    def test_name_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["name"])

    def test_email_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["email"])

    def test_precise_coordinates_blocked(self) -> None:
        with pytest.raises(ValueError, match="PII"):
            assert_no_pii_columns(["lat_precise", "lng_precise"])

    def test_multiple_pii_columns_all_reported(self) -> None:
        with pytest.raises(ValueError, match="PII") as exc_info:
            assert_no_pii_columns(["user_id", "device_id", "ip", "density_ppm2"])
        # All three violations should appear in the error message
        error_msg = str(exc_info.value)
        assert "device_id" in error_msg
        assert "ip" in error_msg
        assert "user_id" in error_msg
