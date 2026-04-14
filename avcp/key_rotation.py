"""KeyRotationService — hourly sector-hash rotation and session-scoped UUIDs.

Security model
──────────────
• ``sector_hash`` is SHA-256(zone_id ‖ venue_id ‖ epoch_bucket).  The
  epoch_bucket changes every ``ttl_seconds`` (default 3 600 s = 1 h),
  which means that even if an attacker intercepts a hash, it becomes
  useless after the rotation window.
• ``edge_node_id`` is a UUID4 generated **once** at process startup and
  held only in memory.  It is never written to disk, so a process restart
  yields a new identifier—unlinkable to the previous session.
• The class is thread-safe: ``_lock`` guards the rotation state, and the
  hot-path (``sector_hash``) only acquires under contention when the
  bucket actually rolls over.
"""

from __future__ import annotations

import hashlib
import threading
import time
import uuid


class KeyRotationService:
    """Provides time-bucketed sector hashes and ephemeral node identifiers.

    Parameters
    ----------
    venue_id:
        Stable venue identifier (e.g. ``"lumen_field"``).
    ttl_seconds:
        Rotation interval for the epoch bucket.  Default ``3600`` (1 h).
    """

    __slots__ = (
        "_venue_id",
        "_ttl_seconds",
        "_current_bucket",
        "_lock",
        "_edge_node_id",
    )

    def __init__(self, venue_id: str, ttl_seconds: int = 3600) -> None:
        self._venue_id = venue_id
        self._ttl_seconds = ttl_seconds
        self._current_bucket: int = self._compute_bucket()
        self._lock = threading.Lock()

        # Session-scoped UUID — lives only in RAM, never persisted.
        self._edge_node_id: str = uuid.uuid4().hex

    # ── Public API ─────────────────────────────────────────────────────

    def sector_hash(self, zone_id: str) -> str:
        """Return the current SHA-256 sector hash for *zone_id*.

        The hash incorporates the current epoch bucket, so it rotates
        automatically every ``ttl_seconds``.

        Algorithmic note: we use SHA-256 (not HMAC) because the input is
        not secret—it is an opaque *anonymization* token, not an
        authentication credential.  The epoch bucket provides temporal
        unlinkability.
        """
        bucket = self._ensure_current_bucket()
        raw = f"{zone_id}:{self._venue_id}:{bucket}"
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @property
    def edge_node_id(self) -> str:
        """Return the session-scoped, in-memory-only edge node UUID."""
        return self._edge_node_id

    @property
    def venue_id(self) -> str:
        """Return the venue identifier."""
        return self._venue_id

    # ── Internals ──────────────────────────────────────────────────────

    def _compute_bucket(self) -> int:
        """Integer-divide epoch time by TTL to get the current bucket."""
        return int(time.time()) // self._ttl_seconds

    def _ensure_current_bucket(self) -> int:
        """Return the current bucket, rotating if the TTL has elapsed.

        Uses a double-check pattern: the fast path is lock-free; the lock
        is only acquired when a bucket transition is detected.
        """
        bucket = self._compute_bucket()
        if bucket == self._current_bucket:
            return self._current_bucket

        with self._lock:
            # Re-check under lock to prevent double-rotation.
            bucket = self._compute_bucket()
            if bucket != self._current_bucket:
                self._current_bucket = bucket
        return self._current_bucket
