import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'gate_intent_service.dart';

class GatePinData {
  final Offset offset;
  final String gateId;
  final String state; // "assigned" | "blocked" | "alternate"
  GatePinData({required this.offset, required this.gateId, required this.state});
}

class RoutePainter extends CustomPainter {
  const RoutePainter({
    required this.routePoints,
    required this.blockedPoints,
    required this.gates,
    required this.tokens,
    required this.intent,
    required this.dashOffset,
  });

  final List<Offset> routePoints;
  final List<Offset> blockedPoints;
  final List<GatePinData> gates;
  final StadiumColorTokens tokens;
  final WayfindingIntent intent;
  final double dashOffset;

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isEmpty) return;

    // 1. Draw blocked old route
    if (blockedPoints.isNotEmpty) {
      final blockedPaint = Paint()
        ..color = tokens.alertRed.withOpacity(0.4)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      
      final path = Path()..moveTo(blockedPoints.first.dx, blockedPoints.first.dy);
      for (var i = 1; i < blockedPoints.length; i++) {
        path.lineTo(blockedPoints[i].dx, blockedPoints[i].dy);
      }
      canvas.drawPath(path, blockedPaint);

      // Draw X at midpoint
      if (blockedPoints.length >= 2) {
        final mid = blockedPoints[blockedPoints.length ~/ 2];
        final crossPaint = Paint()..color = tokens.alertRed.withOpacity(0.7)..strokeWidth = 2;
        canvas.drawLine(mid - const Offset(6, 6), mid + const Offset(6, 6), crossPaint);
        canvas.drawLine(mid - const Offset(6, -6), mid + const Offset(6, -6), crossPaint);
      }
    }

    // 2. Draw active route
    final Color routeColor = (intent == WayfindingIntent.freeFlowing || intent == WayfindingIntent.waitTime)
        ? tokens.primaryGold
        : tokens.success;

    final activePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final actPath = Path()..moveTo(routePoints.first.dx, routePoints.first.dy);
    for (var i = 1; i < routePoints.length; i++) {
      actPath.lineTo(routePoints[i].dx, routePoints[i].dy);
    }
    // Technically requires path metric dash decomposition based on dashOffset.
    // Simplifying standard drawPath for rapid prototyping.
    canvas.drawPath(actPath, activePaint);

    // 3. Chevrons (Simplified single chevron at midpoint)
    if (routePoints.length >= 2) {
      final p1 = routePoints.first;
      final p2 = routePoints[1];
      final angle = atan2(p2.dy - p1.dy, p2.dx - p1.dx);
      
      final chevronPaint = Paint()
        ..color = routeColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
        
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      
      canvas.drawLine(mid, mid - Offset(cos(angle - 0.5) * 12, sin(angle - 0.5) * 12), chevronPaint);
      canvas.drawLine(mid, mid - Offset(cos(angle + 0.5) * 12, sin(angle + 0.5) * 12), chevronPaint);
    }

    // 4. Gate pins
    for (var gate in gates) {
      if (gate.state == 'assigned') {
        final r = (intent == WayfindingIntent.nearGate) ? 18.0 : 12.0;
        final p = Paint()..color = tokens.primaryGold;
        canvas.drawCircle(gate.offset, r, p);
      } else if (gate.state == 'blocked') {
        final p = Paint()..color = const Color(0xFF222222);
        canvas.drawCircle(gate.offset, 12.0, p);
        
        final border = Paint()..color = tokens.alertRed..style = PaintingStyle.stroke..strokeWidth = 2;
        canvas.drawCircle(gate.offset, 12.0, border);
        
        // Draw X
        final crossPaint = Paint()..color = tokens.alertRed..strokeWidth = 1.5;
        canvas.drawLine(gate.offset - const Offset(4, 4), gate.offset + const Offset(4, 4), crossPaint);
        canvas.drawLine(gate.offset - const Offset(4, -4), gate.offset + const Offset(4, -4), crossPaint);
      } else if (gate.state == 'alternate') {
        final p = Paint()..color = tokens.success;
        canvas.drawCircle(gate.offset, 12.0, p);
        
        final border = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5;
        canvas.drawCircle(gate.offset, 12.0, border);
      }
    }

    // 5. User dot
    final userPaint = Paint()..color = tokens.uwbBlue;
    final whiteBorder = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawCircle(routePoints.first, 10, userPaint);
    canvas.drawCircle(routePoints.first, 10, whiteBorder);
  }

  @override
  bool shouldRepaint(RoutePainter old) {
    return old.routePoints != routePoints || old.intent != intent || old.dashOffset != dashOffset;
  }
}
