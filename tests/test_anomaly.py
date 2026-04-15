"""Test 6 — Anomaly flag threshold.

Assert anomaly_flag is True when density deviates > 2σ from
rolling 15-minute baseline. Uses fixture with known baseline stats.
"""

from __future__ import annotations

import collections
import statistics

import pytest

from avcp.edge_ingestor import EdgeIngestor


class TestAnomalyFlagThreshold:
    """anomaly_flag must activate at > 2σ deviation from 15-min baseline."""

    def _build_ingestor_with_baseline(
        self, baseline: list[float], zone_id: str = "test_zone",
    ) -> EdgeIngestor:
        """Create an EdgeIngestor and prime its density baseline."""
        # We can't construct a full EdgeIngestor without ZMQ etc.,
        # so we test the _check_anomaly method directly by setting up
        # the internal state.
        from unittest.mock import MagicMock

        ingestor = EdgeIngestor.__new__(EdgeIngestor)
        ingestor._density_baseline = {
            zone_id: collections.deque(baseline, maxlen=450),
        }
        return ingestor

    def test_anomaly_detected_above_2sigma(
        self,
        stable_baseline_densities: list[float],
        anomalous_density: float,
    ) -> None:
        """Density > 2σ above baseline mean → anomaly_flag = True."""
        ingestor = self._build_ingestor_with_baseline(
            stable_baseline_densities,
        )
        result = ingestor._check_anomaly("test_zone", anomalous_density)
        assert result == True, (
            f"Expected anomaly_flag=True for density={anomalous_density:.3f} "
            f"(baseline mean={statistics.mean(stable_baseline_densities):.3f}, "
            f"stdev={statistics.stdev(stable_baseline_densities):.3f})"
        )

    def test_no_anomaly_within_1sigma(
        self,
        stable_baseline_densities: list[float],
        normal_density: float,
    ) -> None:
        """Density within 1σ of baseline mean → anomaly_flag = False."""
        ingestor = self._build_ingestor_with_baseline(
            stable_baseline_densities,
        )
        result = ingestor._check_anomaly("test_zone", normal_density)
        assert result == False, (
            f"Expected anomaly_flag=False for density={normal_density:.3f}"
        )

    def test_no_anomaly_during_warmup(self) -> None:
        """During warmup period (< 30 ticks), no anomalies should fire."""
        ingestor = self._build_ingestor_with_baseline(
            [2.0] * 10,  # Only 10 ticks — below 30 threshold
        )
        # Even an extreme density shouldn't flag during warmup
        result = ingestor._check_anomaly("test_zone", 100.0)
        assert result == False, (
            "Anomaly should not fire during warmup (< 30 ticks)"
        )

    def test_exactly_2sigma_not_anomalous(
        self,
        stable_baseline_densities: list[float],
    ) -> None:
        """Density exactly at 2σ boundary should NOT be flagged
        (threshold is > 2σ, not >=)."""
        mean = statistics.mean(stable_baseline_densities)
        stdev = statistics.stdev(stable_baseline_densities)
        boundary_density = mean + 2.0 * stdev

        ingestor = self._build_ingestor_with_baseline(
            stable_baseline_densities,
        )
        result = ingestor._check_anomaly("test_zone", boundary_density)
        assert result == False, (
            "Exactly 2σ should not trigger (threshold is strictly > 2σ)"
        )

    def test_negative_deviation_also_anomalous(
        self,
        stable_baseline_densities: list[float],
    ) -> None:
        """Density > 2σ BELOW baseline mean is also anomalous."""
        mean = statistics.mean(stable_baseline_densities)
        stdev = statistics.stdev(stable_baseline_densities)
        low_anomaly = max(0.0, mean - 2.5 * stdev)

        ingestor = self._build_ingestor_with_baseline(
            stable_baseline_densities,
        )
        result = ingestor._check_anomaly("test_zone", low_anomaly)
        assert result == True, (
            f"Negative deviation > 2σ should also be anomalous"
        )

    @pytest.mark.parametrize(
        "sigma_multiple,expected",
        [
            (0.5, False),
            (1.0, False),
            (1.5, False),
            (2.0, False),   # Boundary — not anomalous
            (2.1, True),    # Just above
            (2.5, True),
            (3.0, True),
        ],
    )
    def test_sigma_threshold_parametrized(
        self,
        stable_baseline_densities: list[float],
        sigma_multiple: float,
        expected: bool,
    ) -> None:
        """Parametrized test across various σ multiples."""
        mean = statistics.mean(stable_baseline_densities)
        stdev = statistics.stdev(stable_baseline_densities)
        test_density = mean + sigma_multiple * stdev

        ingestor = self._build_ingestor_with_baseline(
            stable_baseline_densities,
        )
        result = ingestor._check_anomaly("test_zone", test_density)
        assert result == expected, (
            f"At {sigma_multiple}σ (density={test_density:.3f}): "
            f"expected anomaly={expected}, got {result}"
        )
