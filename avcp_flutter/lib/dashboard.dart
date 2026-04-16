/// AVCP Glanceable Dashboard — Triple-Threat UI v1.0.0
///
/// Stack layout (z-order, bottom to top):
///   [0] VenueMapLayer — Google Maps with dark style + heatmap overlay
///   [1] RepaintBoundary → FlowVectorLayer — directional crowd arrows
///   [2] KpiOverlayRow — three select()-driven KPI cards
///   [3] ContextualActionBanner — intent-driven overlay
///
/// Zero PII in any layer. Only zone_id and float vectors.
library;

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:avcp_flutter/action_banner.dart';
import 'package:avcp_flutter/theme.dart';
import 'package:avcp_flutter/providers.dart';

// ══════════════════════════════════════════════════════════════════════
// Dashboard Root
// ══════════════════════════════════════════════════════════════════════

/// Root widget for the AVCP Glanceable Dashboard.
///
/// Requires a [zoneId] to bind all providers to the correct zone.
class GlanceableDashboard extends ConsumerWidget {
  const GlanceableDashboard({
    super.key,
    required this.zoneId,
    this.initialPosition = const LatLng(47.5951, -122.3316),
  });

  /// Venue-scoped zone identifier.
  final String zoneId;

  /// Map camera center (venue coordinates, never user location).
  final LatLng initialPosition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // [0] Map base layer
        VenueMapLayer(
          zoneId: zoneId,
          initialPosition: initialPosition,
        ),

        // [1] Flow vector arrows (repaint-bounded)
        RepaintBoundary(
          child: _FlowVectorOverlay(zoneId: zoneId),
        ),

        // [2] KPI cards (top bar)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: KpiOverlayRow(zoneId: zoneId),
        ),

        // [3] Contextual action banner (bottom)
        const Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: ContextualActionBanner(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Venue Map Layer
// ══════════════════════════════════════════════════════════════════════

/// Google Maps with dark JSON style. Zero PII — no user location marker.
class VenueMapLayer extends ConsumerWidget {
  const VenueMapLayer({
    super.key,
    required this.zoneId,
    required this.initialPosition,
  });

  final String zoneId;
  final LatLng initialPosition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;

    // Watch density to shade the Voronoi polygon
    final double density = ref
        .watch(crowdVectorProvider(zoneId).select((v) => v.value?.densityPpm2))
        ?? 0.0;
        
    final Color polygonColor = density > 4.0 
        ? ext.tokens.alertRed.withOpacity(0.4)
        : density > 1.5 
            ? ext.tokens.primaryGold.withOpacity(0.3)
            : Colors.transparent;

    // Placeholder Voronoi footprint around the initial position
    final Set<Polygon> voronoiFootprint = {
      Polygon(
        polygonId: PolygonId('voronoi_$zoneId'),
        points: [
          LatLng(initialPosition.latitude + 0.0005, initialPosition.longitude - 0.0005),
          LatLng(initialPosition.latitude + 0.0005, initialPosition.longitude + 0.0005),
          LatLng(initialPosition.latitude - 0.0005, initialPosition.longitude + 0.0008),
          LatLng(initialPosition.latitude - 0.0008, initialPosition.longitude - 0.0002),
        ],
        fillColor: polygonColor,
        strokeColor: polygonColor.withOpacity(0.8),
        strokeWidth: 2,
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 17.0,
      ),
      mapType: MapType.normal,
      style: _kDarkMapStyle,
      polygons: voronoiFootprint,
      myLocationEnabled: false, // ZERO PII — no user location
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      onTap: (LatLng position) {
        _showZoneDetailSheet(context, zoneId);
      },
    );
  }

  void _showZoneDetailSheet(BuildContext context, String zoneId) {
    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;
    showBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ext.tokens.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Zone: $zoneId',
                style: AvenuTypography.label(ctx),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap map for live zone details',
                style: AvenuTypography.caption(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Flow Vector Layer
// ══════════════════════════════════════════════════════════════════════

/// Wrapper that reads the stream and passes data to [FlowVectorPainter].
class _FlowVectorOverlay extends ConsumerWidget {
  const _FlowVectorOverlay({required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;

    final vectorAsync = ref.watch(crowdVectorProvider(zoneId));

    return vectorAsync.when(
      data: (vector) {
        final ZoneFlowVector flow = ZoneFlowVector(
          center: Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
          ),
          headingDeg: vector.headingDeg,
          speedP95: vector.speedP95,
        );
        return CustomPaint(
          size: Size.infinite,
          painter: FlowVectorPainter(
            vectors: <ZoneFlowVector>[flow],
            primaryGold: ext.tokens.primaryGold,
            alertRed: ext.tokens.alertRed,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Directional flow data for a single zone.
@immutable
class ZoneFlowVector {
  const ZoneFlowVector({
    required this.center,
    required this.headingDeg,
    required this.speedP95,
  });

  /// Screen-space center of the zone.
  final Offset center;

  /// Dominant heading [0, 360), 0=North.
  final double headingDeg;

  /// 95th-percentile speed m/s.
  final double speedP95;
}

/// CustomPainter rendering directional flow arrows.
///
/// Color by speed: <0.5 → primaryGold, 0.5–1.2 → white, >1.2 → alertRed.
/// [shouldRepaint] uses reference equality on [vectors] list.
class FlowVectorPainter extends CustomPainter {
  const FlowVectorPainter({
    required this.vectors,
    required this.primaryGold,
    required this.alertRed,
  });

  final List<ZoneFlowVector> vectors;
  final Color primaryGold;
  final Color alertRed;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ZoneFlowVector v in vectors) {
      final Color color;
      if (v.speedP95 < 0.5) {
        color = primaryGold;
      } else if (v.speedP95 <= 1.2) {
        color = Colors.white;
      } else {
        color = alertRed;
      }

      final double angleRad = v.headingDeg * pi / 180.0 - pi / 2;
      final double length = (v.speedP95 * 20.0).clamp(8.0, 40.0);

      final Offset tip = v.center +
          Offset(
            cos(angleRad) * length,
            sin(angleRad) * length,
          );

      // Shaft
      final Paint shaftPaint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v.center, tip, shaftPaint);

      // Arrowhead: two lines at ±25°
      const double headAngle = 25.0 * pi / 180.0;
      const double headLength = 10.0;
      final Paint headPaint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final double backAngle = angleRad + pi;
      for (final double sign in <double>[-1, 1]) {
        final Offset wing = tip +
            Offset(
              cos(backAngle + sign * headAngle) * headLength,
              sin(backAngle + sign * headAngle) * headLength,
            );
        canvas.drawLine(tip, wing, headPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowVectorPainter oldDelegate) {
    return !identical(oldDelegate.vectors, vectors);
  }
}

// ══════════════════════════════════════════════════════════════════════
// KPI Overlay Row
// ══════════════════════════════════════════════════════════════════════

/// Top-bar row of three KPI cards with 80% opaque dark background.
class KpiOverlayRow extends StatelessWidget {
  const KpiOverlayRow({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: const Color(0xCC121212), // 80% opaque background
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            Expanded(child: FlowKpiCard(zoneId: zoneId)),
            const SizedBox(width: 8),
            Expanded(child: WaitKpiCard(zoneId: zoneId)),
            const SizedBox(width: 8),
            Expanded(child: DensityKpiCard(zoneId: zoneId)),
          ],
        ),
      ),
    );
  }
}

/// Generic KPI card with semantic label, minimum 44×44pt touch target.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.semanticsLabel,
  });

  final String label;
  final String value;
  final String unit;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 88, minHeight: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: AvenuTypography.caption(context)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  value,
                  style: AvenuTypography.kpi(context).copyWith(fontSize: 20),
                ),
                const SizedBox(width: 2),
                Text(unit, style: AvenuTypography.caption(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Select-driven KPI Cards ─────────────────────────────────────────

/// Flow speed KPI card — uses `.select()` on velocityX only.
class FlowKpiCard extends ConsumerWidget {
  const FlowKpiCard({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double vx = ref
        .watch(crowdVectorProvider(zoneId).select((v) => v.value?.velocityX))
        ?? 0.0;

    final String display = vx.abs().toStringAsFixed(1);
    return KpiCard(
      label: 'FLOW',
      value: display,
      unit: 'm/s',
      semanticsLabel: 'Flow speed: $display metres per second',
    );
  }
}

/// Wait time KPI card — uses `.select()` on dwellRatio only.
class WaitKpiCard extends ConsumerWidget {
  const WaitKpiCard({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double ratio = ref
        .watch(crowdVectorProvider(zoneId).select((v) => v.value?.dwellRatio))
        ?? 0.0;

    final String display = (ratio * 15).round().toString();
    return KpiCard(
      label: 'WAIT',
      value: display,
      unit: 'min',
      semanticsLabel: 'Estimated wait: $display minutes',
    );
  }
}

/// Density KPI card — uses `.select()` on densityPpm2 only.
class DensityKpiCard extends ConsumerWidget {
  const DensityKpiCard({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double density = ref
        .watch(crowdVectorProvider(zoneId).select((v) => v.value?.densityPpm2))
        ?? 0.0;

    final String display = ((density / 6.5) * 100).round().toString();
    return KpiCard(
      label: 'DENSITY',
      value: display,
      unit: '%',
      semanticsLabel: 'Crowd density: $display percent of capacity',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Dark Map Style JSON
// ══════════════════════════════════════════════════════════════════════

/// Google Maps dark style — no landmarks, no labels except roads.
const String _kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
