"""EdgePublisher — fan-out of CrowdVelocityVector to Google Cloud Pub/Sub.

Design decisions
────────────────
• Publishing is **asynchronous**; ``publish()`` returns a
  ``concurrent.futures.Future`` so the caller (EdgeIngestor) is never
  blocked on network I/O during a tick window.
• Serialization uses ``json.dumps`` (not protobuf) because the downstream
  consumer is Firebase RTDB, which expects JSON.  A protobuf path can be
  added later behind a strategy pattern with zero caller changes.
• ``ordering_key`` is ``zone_id`` so that per-zone ordering is preserved
  within Pub/Sub.  This is critical for the ``history_5min`` ring buffer
  on the subscriber side.
• Retry policy and flow control are configured defensively for the
  high-throughput edge case (~50 msgs/s per zone × N zones).
"""

from __future__ import annotations

import json
import logging
from concurrent import futures
from typing import Any

from google.api_core import retry as api_retry
from google.cloud import pubsub_v1
from google.cloud.pubsub_v1 import types as pubsub_types

from avcp.schema import CrowdVelocityVector

logger = logging.getLogger(__name__)


class EdgePublisher:
    """Publishes ``CrowdVelocityVector`` payloads to Cloud Pub/Sub.

    Parameters
    ----------
    project_id:
        GCP project identifier.
    topic_id:
        Pub/Sub topic name (e.g. ``"crowd-vectors"``).
    ordering_enabled:
        If ``True``, messages are keyed by ``zone_id`` for ordered
        delivery within a zone.  Default ``True``.
    max_messages:
        Batch settings — max messages per publish RPC.  Default ``100``.
    max_latency_s:
        Batch settings — max seconds before flushing a partial batch.
        Default ``0.05`` (50 ms) to keep tail latency low on the edge.
    """

    __slots__ = ("_publisher", "_topic_path", "_ordering_enabled")

    def __init__(
        self,
        project_id: str,
        topic_id: str,
        *,
        ordering_enabled: bool = True,
        max_messages: int = 100,
        max_latency_s: float = 0.05,
    ) -> None:
        batch_settings = pubsub_types.BatchSettings(
            max_messages=max_messages,
            max_latency=max_latency_s,
        )

        # Flow control prevents the publisher from buffering unboundedly
        # if the network is slow.  We allow 1 000 outstanding messages
        # before back-pressure kicks in.
        flow_control = pubsub_types.PublishFlowControl(
            message_limit=1_000,
            byte_limit=10 * 1024 * 1024,  # 10 MiB
            limit_exceeded_behavior=(
                pubsub_types.LimitExceededBehavior.BLOCK
            ),
        )

        publisher_options = pubsub_types.PublisherOptions(
            enable_message_ordering=ordering_enabled,
            flow_control=flow_control,
        )

        self._publisher = pubsub_v1.PublisherClient(
            batch_settings=batch_settings,
            publisher_options=publisher_options,
        )
        self._topic_path = self._publisher.topic_path(project_id, topic_id)
        self._ordering_enabled = ordering_enabled

    # ── Public API ─────────────────────────────────────────────────────

    def publish(
        self,
        vector: CrowdVelocityVector,
    ) -> futures.Future[str]:
        """Publish a single ``CrowdVelocityVector`` asynchronously.

        Returns
        -------
        concurrent.futures.Future[str]
            Resolves to the Pub/Sub message ID on success.
        """
        payload: dict[str, Any] = vector.to_firebase_payload()
        data: bytes = json.dumps(payload, separators=(",", ":")).encode("utf-8")

        kwargs: dict[str, Any] = {
            "topic": self._topic_path,
            "data": data,
            "retry": api_retry.Retry(deadline=30.0),
        }

        if self._ordering_enabled:
            kwargs["ordering_key"] = vector.zone_id

        future: futures.Future[str] = self._publisher.publish(**kwargs)
        future.add_done_callback(self._on_publish_done)
        return future

    def shutdown(self) -> None:
        """Flush pending messages and release transport resources."""
        self._publisher.stop()
        logger.info("EdgePublisher shut down cleanly.")

    # ── Internals ──────────────────────────────────────────────────────

    @staticmethod
    def _on_publish_done(future: futures.Future[str]) -> None:
        """Log publish outcome without raising into the event loop."""
        try:
            msg_id = future.result()
            logger.debug("Published message %s", msg_id)
        except Exception:
            logger.exception("Pub/Sub publish failed")
