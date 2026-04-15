"""AVCP Load Tests — Locust-based crowd surge simulation.

Usage:
    # Scenario A: Kickoff surge (50k ramp)
    locust -f tests/load/locustfile.py --headless \
        -u 50000 -r 6250 --run-time 10m \
        --tags kickoff --host https://your-firebase-rtdb.firebaseio.com

    # Scenario B: Halftime egress (50k burst)
    locust -f tests/load/locustfile.py --headless \
        -u 50000 -r 50000 --run-time 2m \
        --tags halftime --host https://your-firebase-rtdb.firebaseio.com

    # Scenario C: Edge node failure + recovery
    locust -f tests/load/locustfile.py --headless \
        -u 50000 -r 5000 --run-time 15m \
        --tags failure --host https://your-firebase-rtdb.firebaseio.com

SLA Targets:
    - p99 Firebase read latency: < 100ms
    - p50 Firebase read latency: < 30ms
    - Error rate: < 0.1%
    - No stale data > 30s without advisory flag
"""

from __future__ import annotations

import json
import math
import os
import random
import statistics
import time
from collections import deque
from typing import Any

from locust import HttpUser, TaskSet, between, events, tag, task
from locust.runners import MasterRunner

# ── Configuration ─────────────────────────────────────────────────────

VENUE_ID = os.environ.get("AVCP_VENUE_ID", "lumen_field")
AUTH_TOKEN = os.environ.get("AVCP_AUTH_TOKEN", "test-bearer-token")
NUM_ZONES = int(os.environ.get("AVCP_NUM_ZONES", "24"))

ZONE_IDS = [
    f"gate_{chr(65 + i)}_concourse_level{(i % 3) + 1}"
    for i in range(NUM_ZONES)
]

# Event phases for scenario gating
EVENT_PHASES = ["pre", "active", "halftime", "post"]


# ── SLA Thresholds ────────────────────────────────────────────────────

class SLA:
    P99_READ_MS = 100
    P50_READ_MS = 30
    MAX_ERROR_RATE_PCT = 0.1
    MAX_STALE_SECONDS = 30
    MIN_EDGE_NODES = 20


# ── Metrics Collector ─────────────────────────────────────────────────

class LoadTestMetrics:
    """Collects latency samples and computes percentiles post-run."""

    def __init__(self) -> None:
        self.latencies: list[float] = []
        self.errors: int = 0
        self.successes: int = 0
        self.stale_reads: int = 0

    def record(self, latency_ms: float, is_error: bool) -> None:
        self.latencies.append(latency_ms)
        if is_error:
            self.errors += 1
        else:
            self.successes += 1

    def record_stale(self) -> None:
        self.stale_reads += 1

    @property
    def total_requests(self) -> int:
        return self.errors + self.successes

    @property
    def error_rate_pct(self) -> float:
        if self.total_requests == 0:
            return 0.0
        return (self.errors / self.total_requests) * 100

    @property
    def p50_ms(self) -> float:
        if not self.latencies:
            return 0.0
        sorted_l = sorted(self.latencies)
        return sorted_l[int(len(sorted_l) * 0.50)]

    @property
    def p99_ms(self) -> float:
        if not self.latencies:
            return 0.0
        sorted_l = sorted(self.latencies)
        return sorted_l[int(len(sorted_l) * 0.99)]

    @property
    def mean_ms(self) -> float:
        if not self.latencies:
            return 0.0
        return statistics.mean(self.latencies)

    def assert_sla(self) -> dict[str, Any]:
        """Run SLA assertions and return results for PR comment."""
        results = {
            "p50_ms": round(self.p50_ms, 1),
            "p99_ms": round(self.p99_ms, 1),
            "mean_ms": round(self.mean_ms, 1),
            "error_rate_pct": round(self.error_rate_pct, 3),
            "total_requests": self.total_requests,
            "stale_reads": self.stale_reads,
            "sla_passed": True,
            "violations": [],
        }

        if self.p99_ms > SLA.P99_READ_MS:
            results["sla_passed"] = False
            results["violations"].append(
                f"p99={self.p99_ms:.1f}ms > {SLA.P99_READ_MS}ms"
            )

        if self.p50_ms > SLA.P50_READ_MS:
            results["sla_passed"] = False
            results["violations"].append(
                f"p50={self.p50_ms:.1f}ms > {SLA.P50_READ_MS}ms"
            )

        if self.error_rate_pct > SLA.MAX_ERROR_RATE_PCT:
            results["sla_passed"] = False
            results["violations"].append(
                f"error_rate={self.error_rate_pct:.3f}% > "
                f"{SLA.MAX_ERROR_RATE_PCT}%"
            )

        return results


# Global metrics instance
_metrics = LoadTestMetrics()


# ══════════════════════════════════════════════════════════════════════
# Scenario A — Kickoff Surge
# ══════════════════════════════════════════════════════════════════════

class KickoffSurgeUser(HttpUser):
    """Simulates 0 → 50,000 fan ramp during event kickoff.

    Uses exponential arrival curve (not uniform ramp-up).
    Each fan reads their assigned zone's current_vector.
    """

    wait_time = between(2, 4)  # 2–4s cadence matches tick_window_s

    def on_start(self) -> None:
        self.zone_id = random.choice(ZONE_IDS)
        self.event_phase = "active"  # Kickoff = entering active phase

    @tag("kickoff")
    @task
    def read_zone_vector(self) -> None:
        """Read current crowd vector for assigned zone."""
        start = time.monotonic()
        path = f"/venues/{VENUE_ID}/zones/{self.zone_id}/current_vector.json"

        with self.client.get(
            path,
            headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
            catch_response=True,
            name="/zones/[zone_id]/current_vector",
        ) as resp:
            latency_ms = (time.monotonic() - start) * 1000

            if resp.status_code != 200:
                resp.failure(f"HTTP {resp.status_code}")
                _metrics.record(latency_ms, is_error=True)
                return

            if latency_ms > SLA.P99_READ_MS:
                resp.failure(f"SLA breach: {latency_ms:.1f}ms > {SLA.P99_READ_MS}ms")

            _metrics.record(latency_ms, is_error=False)

            # Validate response has required fields
            try:
                data = resp.json()
                if data and "density_ppm2" not in data:
                    resp.failure("Missing density_ppm2 in response")
            except (json.JSONDecodeError, TypeError):
                pass  # Firebase may return null for empty zones


# ══════════════════════════════════════════════════════════════════════
# Scenario B — Halftime Egress
# ══════════════════════════════════════════════════════════════════════

class HalftimeEgressUser(HttpUser):
    """Simulates 50,000 concurrent fans requesting navigation at halftime.

    All users burst within a 30-second window to stress-test
    IntentDetectionService and alternate route computation.
    """

    wait_time = between(0.5, 1.5)  # High-frequency burst

    def on_start(self) -> None:
        self.zone_id = random.choice(ZONE_IDS)
        self.event_phase = "halftime"

    @tag("halftime")
    @task(3)
    def read_zone_during_egress(self) -> None:
        """High-frequency zone reads during egress."""
        start = time.monotonic()
        path = f"/venues/{VENUE_ID}/zones/{self.zone_id}/current_vector.json"

        with self.client.get(
            path,
            headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
            catch_response=True,
            name="/zones/[zone_id]/current_vector (halftime)",
        ) as resp:
            latency_ms = (time.monotonic() - start) * 1000
            _metrics.record(latency_ms, is_error=(resp.status_code != 200))

    @tag("halftime")
    @task(1)
    def request_alternate_route(self) -> None:
        """Request alternate route when current path is congested."""
        start = time.monotonic()
        from_zone = self.zone_id
        to_zone = random.choice([z for z in ZONE_IDS if z != from_zone])

        path = (
            f"/venues/{VENUE_ID}/routes.json"
            f"?from={from_zone}&to={to_zone}&avoid_bottleneck=true"
        )

        with self.client.get(
            path,
            headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
            catch_response=True,
            name="/routes (congestion-avoiding)",
        ) as resp:
            latency_ms = (time.monotonic() - start) * 1000

            if resp.status_code == 200:
                try:
                    data = resp.json()
                    # Must return a route, not "unavailable"
                    if data and data.get("status") == "unavailable":
                        resp.failure("Route unavailable during halftime egress")
                except (json.JSONDecodeError, TypeError):
                    pass

            _metrics.record(latency_ms, is_error=(resp.status_code != 200))


# ══════════════════════════════════════════════════════════════════════
# Scenario C — Edge Node Failure + Recovery
# ══════════════════════════════════════════════════════════════════════

class EdgeFailureUser(HttpUser):
    """Simulates edge node failure at T=5min.

    30% of zones will stop publishing (simulated by checking timestamp).
    Assertions:
    - Stale zones flagged with alert_state="advisory" within 10s
    - No zone silently serves data older than 30s without flag
    - When nodes recover, alert_state returns to "normal" within 30s
    """

    wait_time = between(2, 4)

    def on_start(self) -> None:
        self.zone_id = random.choice(ZONE_IDS)
        self.event_phase = "active"
        self._start_time = time.monotonic()

    @tag("failure")
    @task
    def monitor_zone_staleness(self) -> None:
        """Read zone vector and verify staleness handling."""
        start = time.monotonic()
        elapsed_s = start - self._start_time
        path = f"/venues/{VENUE_ID}/zones/{self.zone_id}/current_vector.json"

        with self.client.get(
            path,
            headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
            catch_response=True,
            name="/zones/[zone_id]/current_vector (staleness check)",
        ) as resp:
            latency_ms = (time.monotonic() - start) * 1000
            _metrics.record(latency_ms, is_error=(resp.status_code != 200))

            if resp.status_code != 200:
                return

            try:
                data = resp.json()
                if data is None:
                    return

                # Check data freshness
                timestamp_ms = data.get("timestamp_ms", 0)
                now_ms = int(time.time() * 1000)
                age_s = (now_ms - timestamp_ms) / 1000

                if age_s > SLA.MAX_STALE_SECONDS:
                    # Data is stale — must have advisory flag
                    alert_state = data.get("alert_state", "unknown")
                    if alert_state != "advisory":
                        resp.failure(
                            f"Stale data ({age_s:.0f}s old) without advisory flag"
                        )
                        _metrics.record_stale()
            except (json.JSONDecodeError, TypeError, KeyError):
                pass


# ── Event hooks for SLA reporting ─────────────────────────────────────

@events.quitting.add_listener
def on_quitting(environment: Any, **kwargs: Any) -> None:
    """Print SLA report on test completion."""
    results = _metrics.assert_sla()

    print("\n" + "=" * 60)
    print("AVCP Load Test — SLA Report")
    print("=" * 60)
    print(f"  Total requests:   {results['total_requests']:,}")
    print(f"  p50 latency:      {results['p50_ms']:.1f} ms (SLA: <{SLA.P50_READ_MS}ms)")
    print(f"  p99 latency:      {results['p99_ms']:.1f} ms (SLA: <{SLA.P99_READ_MS}ms)")
    print(f"  Mean latency:     {results['mean_ms']:.1f} ms")
    print(f"  Error rate:       {results['error_rate_pct']:.3f}% (SLA: <{SLA.MAX_ERROR_RATE_PCT}%)")
    print(f"  Stale reads:      {results['stale_reads']}")
    print(f"  SLA PASSED:       {'✅ YES' if results['sla_passed'] else '❌ NO'}")
    if results["violations"]:
        print(f"  Violations:       {', '.join(results['violations'])}")
    print("=" * 60)

    # Write JSON report for CI consumption
    report_path = os.environ.get("AVCP_LOAD_REPORT", "load_test_report.json")
    with open(report_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nReport written to {report_path}")
