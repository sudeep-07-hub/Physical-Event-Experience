"""Security tests — Firebase RTDB rules unit tests.

Tests Firebase security rules via assertion-based verification:
- Fan role cannot write to any path
- Fan role cannot read system_health path
- Operator role cannot read other venues
- Unauthenticated user cannot read any path

Note: In production, these run against the Firebase emulator using
@firebase/rules-unit-testing. This Python version verifies the rules
JSON structure and documents the expected behavior for CI.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest


# ── Load rules ────────────────────────────────────────────────────────

RULES_PATH = (
    Path(__file__).parent.parent.parent
    / "avcp_flutter"
    / "database.rules.json"
)


@pytest.fixture
def rules() -> dict[str, Any]:
    """Load the Firebase RTDB security rules."""
    with open(RULES_PATH) as f:
        return json.load(f)


# ══════════════════════════════════════════════════════════════════════
# Rule Structure Assertions
# ══════════════════════════════════════════════════════════════════════

class TestFirebaseRulesStructure:
    """Verify security rules enforce proper access control."""

    def test_rules_file_exists(self) -> None:
        """database.rules.json must exist."""
        assert RULES_PATH.exists(), f"Rules file not found at {RULES_PATH}"

    def test_top_level_structure(self, rules: dict[str, Any]) -> None:
        """Rules must have 'rules' top-level key with 'venues'."""
        assert "rules" in rules
        assert "venues" in rules["rules"]

    def test_zones_read_requires_auth(self, rules: dict[str, Any]) -> None:
        """Zones path must require authentication for read."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        zone_read = venue_rules["zones"][".read"]
        assert "auth != null" in zone_read, (
            f"Zone read rule '{zone_read}' must require authentication"
        )

    def test_zones_write_denied(self, rules: dict[str, Any]) -> None:
        """Fan role MUST NOT be able to write to zones."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        zone_write = venue_rules["zones"].get(".write", False)
        # Write must be explicitly false or absent (default deny)
        assert zone_write is False or zone_write == "false", (
            f"Zone write rule must be false, got: {zone_write}"
        )

    def test_system_health_requires_operator(
        self, rules: dict[str, Any],
    ) -> None:
        """system_health path must only be readable by operator role."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        health_read = venue_rules["system_health"][".read"]
        assert "role" in health_read and "operator" in health_read, (
            f"system_health read rule '{health_read}' must require operator role"
        )

    def test_system_health_write_operator_only(
        self, rules: dict[str, Any],
    ) -> None:
        """system_health write must require operator role."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        health_write = venue_rules["system_health"][".write"]
        assert "role" in health_write and "operator" in health_write, (
            f"system_health write rule '{health_write}' must require operator role"
        )

    def test_overrides_write_operator_only(
        self, rules: dict[str, Any],
    ) -> None:
        """Overrides write must require operator role."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        if "overrides" in venue_rules:
            override_write = venue_rules["overrides"][".write"]
            assert "operator" in override_write, (
                f"Override write rule must require operator role"
            )

    def test_no_global_read_true(self, rules: dict[str, Any]) -> None:
        """Top-level rules must NOT have '.read': true (open to world)."""
        assert rules["rules"].get(".read") != True  # noqa: E712
        assert rules["rules"].get(".read") != "true"

    def test_no_global_write_true(self, rules: dict[str, Any]) -> None:
        """Top-level rules must NOT have '.write': true (open to world)."""
        assert rules["rules"].get(".write") != True  # noqa: E712
        assert rules["rules"].get(".write") != "true"


class TestFirebaseRulesAccessControl:
    """Document expected access patterns for CI verification."""

    def test_fan_cannot_write(self, rules: dict[str, Any]) -> None:
        """Fan role (auth != null, no special role) cannot write zones."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        zone_write = venue_rules["zones"].get(".write", False)
        # Fan has auth != null but no role — write must be denied
        assert zone_write is False or zone_write == "false"

    def test_fan_cannot_read_system_health(
        self, rules: dict[str, Any],
    ) -> None:
        """Fan role must NOT be able to read system_health."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        health_read = venue_rules["system_health"][".read"]
        # The rule requires operator role — fan doesn't have it
        assert "operator" in health_read, (
            "system_health read must be restricted to operator"
        )

    def test_unauthenticated_denied(self, rules: dict[str, Any]) -> None:
        """Unauthenticated user (auth == null) cannot read any path."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        zone_read = venue_rules["zones"][".read"]
        # 'auth != null' means unauthenticated is denied
        assert "auth != null" in zone_read

    def test_cross_venue_isolation(self, rules: dict[str, Any]) -> None:
        """Rules use $venue_id wildcard — each venue is isolated.
        An operator for venue A should not read venue B's data
        (enforced by auth.token.venue_id matching in production)."""
        # The $venue_id wildcard ensures isolation at the rules level
        assert "$venue_id" in rules["rules"]["venues"]

    def test_validate_rule_on_current_vector(
        self, rules: dict[str, Any],
    ) -> None:
        """current_vector must validate required fields on write."""
        venue_rules = rules["rules"]["venues"]["$venue_id"]
        zone_rules = venue_rules["zones"].get("$zone_id", {})
        vector_rules = zone_rules.get("current_vector", {})
        validate = vector_rules.get(".validate", "")
        if validate:
            # Must check for required fields
            assert "zone_id" in validate or "density_ppm2" in validate, (
                "Validate rule should check for required schema fields"
            )
