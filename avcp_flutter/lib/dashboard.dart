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
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:avcp_flutter/action_banner.dart';
import 'package:avcp_flutter/theme.dart';
import 'package:avcp_flutter/providers.dart';

// ══════════════════════════════════════════════════════════════════════
// Hardware Routing Haptics
// ══════════════════════════════════════════════════════════════════════

/// Translates digital routing logic directly into physical hardware pulses
/// so the user does not need to look at down at their screen during evacuations.
abstract class HapticRouter {
  static Future<void> pulseTurnLeft() async {
    if (!kIsWeb && (await Vibration.hasVibrator() ?? false)) {
      // Two quick short pulses.
      Vibration.vibrate(pattern: [0, 100, 100, 100]);
    }
  }

  static Future<void> pulseTurnRight() async {
    if (!kIsWeb && (await Vibration.hasVibrator() ?? false)) {
      // Three quick short pulses.
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    }
  }

  static Future<void> pulseProceed() async {
    if (!kIsWeb && (await Vibration.hasVibrator() ?? false)) {
      // Single long solid pulse.
      Vibration.vibrate(duration: 500);
    }
  }
}

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
          child: SemanticStatePanel(zoneId: zoneId),
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
        polygonId: const PolygonId('voronoi_zone'),
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
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polygons: voronoiFootprint,
      onTap: (point) {
        _showZoneDetailSheet(context, zoneId);
      },
    );
  }

  void _showZoneDetailSheet(BuildContext context, String zoneId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Consumer(builder: (context, ref, child) {
          final density = ref.watch(crowdVectorProvider(zoneId).select((v) => v.value?.densityPpm2)) ?? 0.0;
          final pred60 = ref.watch(crowdVectorProvider(zoneId).select((v) => v.value?.predictedDensity60s)) ?? 0.0;
          final pred300 = ref.watch(crowdVectorProvider(zoneId).select((v) => v.value?.predictedDensity300s)) ?? 0.0;
          
          return GlassContainer(
            blur: 20.0,
            opacity: 0.1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Predictive Flow Chart (Next 5 Mins)",
                    style: AvenuTypography.label(ctx).copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, density),
                              FlSpot(1, pred60),
                              FlSpot(5, pred300),
                            ],
                            isCurved: true,
                            color: StadiumColorTokens.standard.primaryGold,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              color: StadiumColorTokens.standard.primaryGold.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
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
class SemanticStatePanel extends ConsumerWidget {
  const SemanticStatePanel({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(crowdVectorProvider(zoneId).select((v) => v.value?.densityPpm2)) ?? 0.0;
    final ratio = ref.watch(crowdVectorProvider(zoneId).select((v) => v.value?.dwellRatio)) ?? 0.0;
    
    // Abstract the physics to human terms
    String headline = "Free Flowing";
    String description = "Proceed to your destination.";
    Color stateColor = StadiumColorTokens.standard.success;
    IconData stateIcon = Icons.directions_walk;
    
    if (density >= 4.0) {
      headline = "Severe Bottleneck";
      description = "Avoid this sector immediately.";
      stateColor = StadiumColorTokens.standard.alertRed;
      stateIcon = Icons.warning_amber_rounded;
    } else if (density >= 2.0) {
      headline = "Heavy Traffic";
      final mins = (ratio * 15).round();
      description = "Estimated transit time: $mins mins";
      stateColor = Colors.orangeAccent;
      stateIcon = Icons.groups_rounded;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        blur: 15.0,
        opacity: 0.2,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(stateIcon, color: stateColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: AvenuTypography.kpi(context).copyWith(color: stateColor, fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AvenuTypography.label(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
