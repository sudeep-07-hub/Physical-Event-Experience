"""Test 5 — Edge publisher no PII.

Intercept Pub/Sub publish call via unittest.mock.
Deserialize payload from call args.
Assert no string field value matches email regex or UUID4 pattern
that would indicate device-level tracking.
"""

from __future__ import annotations

import json
import re
from unittest.mock import MagicMock, patch

import pytest

from avcp.schema import CrowdVelocityVector

from .conftest import PII_FORBIDDEN_FIELDS, make_vector


class TestEdgePublisherNoPII:
    """Intercept publish calls and verify zero PII leakage."""

    @patch("avcp.publishers.pubsub_v1")
    def test_published_payload_has_no_pii_keys(
        self, mock_pubsub: MagicMock,
    ) -> None:
        """Payload sent to Pub/Sub must not contain PII field names."""
        from avcp.publishers import EdgePublisher

        mock_publisher = MagicMock()
        mock_pubsub.PublisherClient.return_value = mock_publisher
        mock_publisher.topic_path.return_value = "projects/p/topics/t"

        publisher = EdgePublisher(
            project_id="test-project",
            topic_id="crowd-vectors",
        )

        vector = make_vector(density=2.5, dwell=0.4)
        publisher.publish(vector)

        # Extract the data bytes from the publish call
        call_kwargs = mock_publisher.publish.call_args
        data_bytes = call_kwargs.kwargs.get("data") or call_kwargs[1].get("data")
        payload = json.loads(data_bytes.decode("utf-8"))

        violations = PII_FORBIDDEN_FIELDS & payload.keys()
        assert not violations, (
            f"PII fields in Pub/Sub payload: {sorted(violations)}"
        )

    @patch("avcp.publishers.pubsub_v1")
    def test_published_values_no_email_pattern(
        self, mock_pubsub: MagicMock,
    ) -> None:
        """No string value in published data should match email regex."""
        from avcp.publishers import EdgePublisher

        mock_publisher = MagicMock()
        mock_pubsub.PublisherClient.return_value = mock_publisher
        mock_publisher.topic_path.return_value = "projects/p/topics/t"

        publisher = EdgePublisher(
            project_id="test-project",
            topic_id="crowd-vectors",
        )

        vector = make_vector(density=1.0)
        publisher.publish(vector)

        call_kwargs = mock_publisher.publish.call_args
        data_bytes = call_kwargs.kwargs.get("data") or call_kwargs[1].get("data")
        payload = json.loads(data_bytes.decode("utf-8"))

        email_re = re.compile(
            r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
        )
        for key, value in payload.items():
            if isinstance(value, str):
                assert not email_re.search(value), (
                    f"Email pattern found in '{key}': '{value}'"
                )

    @patch("avcp.publishers.pubsub_v1")
    def test_published_values_no_uuid4_tracking(
        self, mock_pubsub: MagicMock,
    ) -> None:
        """No value should contain a UUID4 pattern (device tracking)."""
        from avcp.publishers import EdgePublisher

        mock_publisher = MagicMock()
        mock_pubsub.PublisherClient.return_value = mock_publisher
        mock_publisher.topic_path.return_value = "projects/p/topics/t"

        publisher = EdgePublisher(
            project_id="test-project",
            topic_id="crowd-vectors",
        )

        vector = make_vector(density=3.0)
        publisher.publish(vector)

        call_kwargs = mock_publisher.publish.call_args
        data_bytes = call_kwargs.kwargs.get("data") or call_kwargs[1].get("data")
        payload = json.loads(data_bytes.decode("utf-8"))

        uuid4_re = re.compile(
            r"[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-"
            r"[89ab][0-9a-f]{3}-[0-9a-f]{12}",
            re.IGNORECASE,
        )
        for key, value in payload.items():
            if isinstance(value, str):
                assert not uuid4_re.search(value), (
                    f"UUID4 device-tracking pattern in '{key}': '{value}'"
                )

    @patch("avcp.publishers.pubsub_v1")
    def test_ordering_key_is_zone_id(
        self, mock_pubsub: MagicMock,
    ) -> None:
        """Ordering key must be zone_id (not a device identifier)."""
        from avcp.publishers import EdgePublisher

        mock_publisher = MagicMock()
        mock_pubsub.PublisherClient.return_value = mock_publisher
        mock_publisher.topic_path.return_value = "projects/p/topics/t"

        publisher = EdgePublisher(
            project_id="test-project",
            topic_id="crowd-vectors",
            ordering_enabled=True,
        )

        vector = make_vector(density=2.0)
        publisher.publish(vector)

        call_kwargs = mock_publisher.publish.call_args
        ordering_key = (
            call_kwargs.kwargs.get("ordering_key")
            or call_kwargs[1].get("ordering_key")
        )
        assert ordering_key == vector.zone_id, (
            f"Ordering key '{ordering_key}' should be zone_id, "
            f"not a device identifier"
        )
