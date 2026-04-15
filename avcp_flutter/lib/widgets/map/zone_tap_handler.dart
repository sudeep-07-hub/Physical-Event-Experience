/// Zone tap handler — detects taps on zone polygons and opens detail sheet.
///
/// This is a utility mixin / helper rather than a standalone widget,
/// since zone tap handling is integrated into [VenueMapView] via
/// [Polygon.onTap] callbacks.
library;

import 'package:flutter/material.dart';

import '../zone/zone_detail_sheet.dart';

/// Opens the [ZoneDetailSheet] for a specific zone.
///
/// Usage from any widget:
/// ```dart
/// ZoneTapHandler.openZoneDetail(context, 'gate_c_concourse');
/// ```
abstract final class ZoneTapHandler {
  /// Show the zone detail bottom sheet.
  static void openZoneDetail(BuildContext context, String zoneId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ZoneDetailSheet(zoneId: zoneId),
    );
  }
}
