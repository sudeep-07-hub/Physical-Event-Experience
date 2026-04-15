"""Test 3 — Key rotation.

Assert sector_hash changes after ttl_seconds elapses.
Mock time.time() via unittest.mock to simulate time progression.
Assert old hash not in rotated output.
"""

from __future__ import annotations

from unittest.mock import patch

import pytest

from avcp.key_rotation import KeyRotationService


class TestKeyRotation:
    """sector_hash must rotate when the TTL bucket changes."""

    def test_hash_changes_after_ttl(self) -> None:
        """Hash must differ after epoch bucket rolls over."""
        ttl = 10  # 10-second rotation for fast test

        with patch("avcp.key_rotation.time") as mock_time:
            # Bucket 0: time = 5 → bucket = 5 // 10 = 0
            mock_time.time.return_value = 5.0
            svc = KeyRotationService(venue_id="stadium", ttl_seconds=ttl)
            hash_bucket_0 = svc.sector_hash("gate_c")

            # Still in bucket 0: time = 9
            mock_time.time.return_value = 9.0
            hash_same_bucket = svc.sector_hash("gate_c")
            assert hash_same_bucket == hash_bucket_0, (
                "Hash should be identical within the same TTL bucket"
            )

            # Bucket 1: time = 15 → bucket = 15 // 10 = 1
            mock_time.time.return_value = 15.0
            hash_bucket_1 = svc.sector_hash("gate_c")
            assert hash_bucket_1 != hash_bucket_0, (
                "Hash MUST change after TTL bucket rolls over"
            )

    def test_old_hash_not_in_new_bucket(self) -> None:
        """After rotation, the old hash must not be recoverable."""
        with patch("avcp.key_rotation.time") as mock_time:
            mock_time.time.return_value = 100.0
            svc = KeyRotationService(venue_id="arena", ttl_seconds=60)
            old_hash = svc.sector_hash("section_b")

            # Jump forward 2 hours
            mock_time.time.return_value = 100.0 + 7200.0
            new_hash = svc.sector_hash("section_b")

            assert old_hash != new_hash
            # The old hash should not appear for any reasonable zone
            assert svc.sector_hash("section_a") != old_hash

    def test_different_zones_different_hashes(self) -> None:
        """Same bucket, different zone_ids → different hashes."""
        svc = KeyRotationService(venue_id="test_venue", ttl_seconds=3600)
        hash_a = svc.sector_hash("gate_a")
        hash_b = svc.sector_hash("gate_b")
        assert hash_a != hash_b

    def test_different_venues_different_hashes(self) -> None:
        """Same zone, different venue_ids → different hashes."""
        with patch("avcp.key_rotation.time") as mock_time:
            mock_time.time.return_value = 1000.0
            svc_1 = KeyRotationService(venue_id="venue_1", ttl_seconds=3600)
            svc_2 = KeyRotationService(venue_id="venue_2", ttl_seconds=3600)
            assert svc_1.sector_hash("gate_c") != svc_2.sector_hash("gate_c")

    def test_edge_node_id_is_session_scoped(self) -> None:
        """Each KeyRotationService instance gets a unique edge_node_id."""
        svc_1 = KeyRotationService(venue_id="test", ttl_seconds=3600)
        svc_2 = KeyRotationService(venue_id="test", ttl_seconds=3600)
        assert svc_1.edge_node_id != svc_2.edge_node_id

    def test_hash_is_64_hex_chars(self) -> None:
        """sector_hash must be a valid SHA-256 hex digest (64 chars)."""
        svc = KeyRotationService(venue_id="test", ttl_seconds=3600)
        h = svc.sector_hash("gate_c")
        assert len(h) == 64
        assert all(c in "0123456789abcdef" for c in h)

    def test_rapid_successive_calls_same_result(self) -> None:
        """Multiple calls within same bucket return identical hash."""
        svc = KeyRotationService(venue_id="test", ttl_seconds=3600)
        hashes = [svc.sector_hash("zone_x") for _ in range(100)]
        assert len(set(hashes)) == 1
