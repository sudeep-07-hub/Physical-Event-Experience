/// Animated flow vector layer — directional arrows showing crowd movement.
///
/// Uses [CustomPainter] with a 2-second animation cycle.
/// Arrows indicate dominant heading direction and speed.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/crowd_velocity_vector.dart';
import '../../providers/crowd_state_provider.dart';

class FlowVectorLayer extends ConsumerStatefulWidget {
  const FlowVectorLayer({super.key});

  @override
  ConsumerState<FlowVectorLayer> createState() => _FlowVectorLayerState();
}

class _FlowVectorLayerState extends ConsumerState<FlowVectorLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allZonesAsync = ref.watch(allZonesStreamProvider);

    return allZonesAsync.when(
      data: (vectors) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _FlowVectorPainter(
            vectors: vectors,
            animationProgress: _controller.value,
          ),
          size: Size.infinite,
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Paints animated directional arrows for crowd flow.
class _FlowVectorPainter extends CustomPainter {
  _FlowVectorPainter({
    required this.vectors,
    required this.animationProgress,
  });

  final List<CrowdVelocityVector> vectors;
  final double animationProgress;

  static const _arrowLength = 24.0;
  static const _arrowHeadSize = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (vectors.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final v in vectors) {
      // Skip zones with negligible flow
      final speed = math.sqrt(v.velocityX * v.velocityX +
          v.velocityY * v.velocityY);
      if (speed < 0.1) continue;

      // Position from zone hash (same mapping as heatmap)
      final hash = v.zoneId.hashCode;
      final baseX = (hash % 100) / 100 * size.width;
      final baseY = ((hash ~/ 100) % 100) / 100 * size.height;

      // Heading in radians (0=North, clockwise)
      final headingRad = v.headingDeg * math.pi / 180;

      // Animate: arrows travel along heading direction
      final offset = animationProgress * _arrowLength;
      final startX = baseX + math.sin(headingRad) * offset;
      final startY = baseY - math.cos(headingRad) * offset;
      final endX = startX + math.sin(headingRad) * _arrowLength;
      final endY = startY - math.cos(headingRad) * _arrowLength;

      // Arrow shaft
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );

      // Arrow head
      final headAngle1 = headingRad + math.pi * 0.8;
      final headAngle2 = headingRad - math.pi * 0.8;
      canvas.drawLine(
        Offset(endX, endY),
        Offset(
          endX + math.sin(headAngle1) * _arrowHeadSize,
          endY - math.cos(headAngle1) * _arrowHeadSize,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(endX, endY),
        Offset(
          endX + math.sin(headAngle2) * _arrowHeadSize,
          endY - math.cos(headAngle2) * _arrowHeadSize,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlowVectorPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.vectors != vectors;
  }
}
