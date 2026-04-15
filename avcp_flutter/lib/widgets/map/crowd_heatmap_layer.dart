/// Crowd density heatmap overlay using Jet colormap.
///
/// Renders crowd density as a semi-transparent color overlay (alpha 0.6)
/// using a [CustomPainter]. In production, this would use a [TileProvider]
/// for proper map-coordinate rendering. This implementation uses a
/// simplified canvas-based approach.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/crowd_velocity_vector.dart';
import '../../providers/crowd_state_provider.dart';

class CrowdHeatmapLayer extends ConsumerWidget {
  const CrowdHeatmapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allZonesAsync = ref.watch(allZonesStreamProvider);

    return allZonesAsync.when(
      data: (vectors) => CustomPaint(
        painter: _HeatmapPainter(vectors: vectors),
        size: Size.infinite,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Paints crowd density as a Jet colormap overlay.
class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({required this.vectors});

  final List<CrowdVelocityVector> vectors;

  @override
  void paint(Canvas canvas, Size size) {
    if (vectors.isEmpty) return;

    for (final v in vectors) {
      // Map zone to screen position — in production this uses
      // map projection coordinates. Simplified here with hash-based
      // positioning for demonstration.
      final hash = v.zoneId.hashCode;
      final x = (hash % 100) / 100 * size.width;
      final y = ((hash ~/ 100) % 100) / 100 * size.height;
      final center = Offset(x, y);

      // Radius scales with density
      final radius = 30.0 + v.densityPpm2 * 15.0;

      // Jet colormap: blue (low) → cyan → green → yellow → red (high)
      final color = _jetColor(v.densityPpm2 / 6.5);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, paint);
    }
  }

  /// Jet colormap: maps [0, 1] → blue → cyan → green → yellow → red.
  Color _jetColor(double t) {
    final clamped = t.clamp(0.0, 1.0);

    double r, g, b;

    if (clamped < 0.25) {
      r = 0;
      g = 4 * clamped;
      b = 1;
    } else if (clamped < 0.5) {
      r = 0;
      g = 1;
      b = 1 - 4 * (clamped - 0.25);
    } else if (clamped < 0.75) {
      r = 4 * (clamped - 0.5);
      g = 1;
      b = 0;
    } else {
      r = 1;
      g = 1 - 4 * (clamped - 0.75);
      b = 0;
    }

    return Color.fromARGB(
      255,
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.vectors != vectors;
  }
}
