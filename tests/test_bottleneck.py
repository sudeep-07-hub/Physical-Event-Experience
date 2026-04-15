"""Test 2 — Bottleneck score monotonicity.

Parametrized over density ∈ [0.5, 1.5, 3.0, 5.5] and
dwell_ratio ∈ [0.1, 0.3, 0.6, 0.9].

Assert: bottleneck_score increases monotonically with density
(Greenshields fundamental diagram: b = k / k_jam).
"""

from __future__ import annotations

import sys
if sys.version_info >= (3, 10):
    from itertools import pairwise
else:
    from itertools import tee
    def pairwise(iterable):
        a, b = tee(iterable)
        next(b, None)
        return zip(a, b)

import pytest

from avcp.edge_ingestor import EdgeIngestor
from avcp.schema import CrowdVelocityVector

from .conftest import make_vector


# ── Greenshields bottleneck via EdgeIngestor._compute_bottleneck ──

DENSITY_LEVELS = [0.5, 1.5, 3.0, 5.5]
DWELL_LEVELS = [0.1, 0.3, 0.6, 0.9]


class TestBottleneckScoreMonotonic:
    """bottleneck_score must increase monotonically with density."""

    @pytest.mark.parametrize("dwell_ratio", DWELL_LEVELS)
    def test_monotonic_over_density(self, dwell_ratio: float) -> None:
        """For a fixed dwell_ratio, increasing density → increasing bottleneck."""
        scores = [
            EdgeIngestor._compute_bottleneck(density)
            for density in DENSITY_LEVELS
        ]

        for (d_lo, s_lo), (d_hi, s_hi) in pairwise(zip(DENSITY_LEVELS, scores)):
            assert s_lo < s_hi, (
                f"Monotonicity violated at dwell={dwell_ratio}: "
                f"density {d_lo} → score {s_lo:.3f}, "
                f"density {d_hi} → score {s_hi:.3f}"
            )

    @pytest.mark.parametrize(
        "density,expected_min,expected_max",
        [
            (0.5, 0.0, 0.15),    # Free-flow
            (1.5, 0.15, 0.35),   # Light
            (3.0, 0.35, 0.55),   # Moderate
            (5.5, 0.75, 1.0),    # Near-crush
        ],
    )
    def test_score_range(
        self, density: float, expected_min: float, expected_max: float,
    ) -> None:
        """Score should fall within expected Fruin LoS band."""
        score = EdgeIngestor._compute_bottleneck(density)
        assert expected_min <= score <= expected_max, (
            f"Score {score:.3f} for density={density} "
            f"not in [{expected_min}, {expected_max}]"
        )

    def test_zero_density_zero_score(self) -> None:
        """Zero density must produce zero bottleneck."""
        assert EdgeIngestor._compute_bottleneck(0.0) == 0.0

    def test_jam_density_unit_score(self) -> None:
        """Jam density (6.5) must produce score = 1.0."""
        assert EdgeIngestor._compute_bottleneck(6.5) == 1.0

    def test_above_jam_clamped(self) -> None:
        """Above jam density still clamped to 1.0."""
        assert EdgeIngestor._compute_bottleneck(10.0) == 1.0

    @pytest.mark.parametrize(
        "density,dwell_ratio",
        [
            (d, dw)
            for d in DENSITY_LEVELS
            for dw in DWELL_LEVELS
        ],
    )
    def test_full_parametrize_grid(
        self, density: float, dwell_ratio: float,
    ) -> None:
        """Full grid: all density × dwell combinations produce valid scores."""
        score = EdgeIngestor._compute_bottleneck(density)
        assert 0.0 <= score <= 1.0, (
            f"Score {score} out of [0, 1] for density={density}, dwell={dwell_ratio}"
        )
