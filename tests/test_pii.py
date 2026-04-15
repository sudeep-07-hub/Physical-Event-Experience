"""Test 1 — PII absent in payload.

HARD CI BLOCK: Pipeline must fail if any PII field appears in
CrowdVelocityVector.to_firebase_payload() output.

Extended blocklist: user_id, device_id, ip, mac, face_vector, name,
phone, email, imei, ssid.
"""

from __future__ import annotations

import re

import pytest

from avcp.schema import CrowdVelocityVector

from .conftest import PII_FORBIDDEN_FIELDS, make_vector


class TestPIIAbsentInPayload:
    """Strictly verify no PII fields exist in serialized output."""

    def test_forbidden_fields_disjoint(
        self, sample_vector: CrowdVelocityVector,
    ) -> None:
        """Core assertion: forbidden field names must not appear as keys."""
        payload = sample_vector.to_firebase_payload()
        violations = PII_FORBIDDEN_FIELDS & payload.keys()
        assert not violations, (
            f"PII LEAK DETECTED — CI BLOCKED. "
            f"Forbidden fields in payload: {sorted(violations)}"
        )

    def test_no_email_pattern_in_values(
        self, sample_vector: CrowdVelocityVector,
    ) -> None:
        """No string value should match an email regex."""
        email_re = re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
        payload = sample_vector.to_firebase_payload()
        for key, value in payload.items():
            if isinstance(value, str):
                assert not email_re.search(value), (
                    f"Email pattern found in field '{key}': '{value}'"
                )

    def test_no_uuid4_pattern_in_values(
        self, sample_vector: CrowdVelocityVector,
    ) -> None:
        """No string value should contain a full UUID4 (device-level tracking)."""
        uuid4_re = re.compile(
            r"[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}",
            re.IGNORECASE,
        )
        payload = sample_vector.to_firebase_payload()
        for key, value in payload.items():
            if isinstance(value, str):
                assert not uuid4_re.search(value), (
                    f"UUID4 pattern found in field '{key}': '{value}'. "
                    f"This could indicate device-level tracking."
                )

    def test_payload_keys_are_schema_fields_only(
        self, sample_vector: CrowdVelocityVector,
    ) -> None:
        """Payload keys must be exactly the schema fields — no extras."""
        payload = sample_vector.to_firebase_payload()
        expected_keys = {
            "zone_id", "sector_hash", "timestamp_ms", "tick_window_s",
            "density_ppm2", "velocity_x", "velocity_y", "speed_p95",
            "heading_deg", "dwell_ratio", "flow_variance", "bottleneck_score",
            "predicted_density_60s", "predicted_density_300s",
            "anomaly_flag", "confidence", "edge_node_id", "schema_version",
        }
        extra = payload.keys() - expected_keys
        assert not extra, f"Unexpected fields in payload: {sorted(extra)}"

    @pytest.mark.parametrize("forbidden_field", sorted(PII_FORBIDDEN_FIELDS))
    def test_each_forbidden_field_absent(
        self,
        sample_vector: CrowdVelocityVector,
        forbidden_field: str,
    ) -> None:
        """Parametrized check for each forbidden field individually."""
        payload = sample_vector.to_firebase_payload()
        assert forbidden_field not in payload, (
            f"PII field '{forbidden_field}' found in payload — CI BLOCKED"
        )
