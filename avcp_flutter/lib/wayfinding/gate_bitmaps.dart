import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pre-renders sharp, high-DPI vector markers into BitmapDescriptors.
/// Strictly zero-PII: purely geometric and infrastructure-based indicators.
class GateBitmaps {
  final BitmapDescriptor userDot;
  final BitmapDescriptor gateAssigned;
  final BitmapDescriptor gateBlocked;
  final BitmapDescriptor gateAlternate;
  final BitmapDescriptor gateNearGold;

  const GateBitmaps({
    required this.userDot,
    required this.gateAssigned,
    required this.gateBlocked,
    required this.gateAlternate,
    required this.gateNearGold,
  });

  static Future<GateBitmaps> create({required double dpr}) async {
    return GateBitmaps(
      userDot: await _renderUserDot(dpr),
      gateAssigned: await _renderGateIcon(dpr, 'C', const Color(0xFFFFD700), Colors.black),
      gateBlocked: await _renderGateBlocked(dpr, 'C'),
      gateAlternate: await _renderGateIcon(dpr, 'D', const Color(0xFF00E676), Colors.black),
      gateNearGold: await _renderGateIcon(dpr, 'C', const Color(0xFFFFD700), Colors.black, isLarge: true, hasPulse: true),
    );
  }

  static Future<BitmapDescriptor> _renderUserDot(double dpr) async {
    final size = 40.0 * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Outer ring (glow)
    final outerPaint = Paint()
      ..color = const Color(0x664FC3F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * dpr;
    canvas.drawCircle(Offset(size / 2, size / 2), size * 0.45, outerPaint);

    // Inner fill
    final innerPaint = Paint()..color = const Color(0xFF4FC3F7);
    canvas.drawCircle(Offset(size / 2, size / 2), size * 0.25, innerPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * dpr;
    canvas.drawCircle(Offset(size / 2, size / 2), size * 0.25, borderPaint);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _renderGateIcon(
    double dpr,
    String letter,
    Color bgColor,
    Color textColor, {
    bool isLarge = false,
    bool hasPulse = false,
  }) async {
    final radius = (isLarge ? 22.0 : 16.0) * dpr;
    final fullSize = (isLarge ? 60.0 : 40.0) * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = Offset(fullSize / 2, fullSize / 2);

    if (hasPulse) {
      final pulsePaint = Paint()
        ..color = bgColor.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * dpr;
      canvas.drawCircle(center, radius + (8 * dpr), pulsePaint);
      canvas.drawCircle(center, radius + (14 * dpr), pulsePaint);
    }

    // Main Circle
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * dpr,
    );

    // Letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: textColor,
          fontSize: radius * 1.2,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    final image = await recorder.endRecording().toImage(fullSize.toInt(), fullSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _renderGateBlocked(double dpr, String letter) async {
    final radius = 16.0 * dpr;
    final fullSize = 40.0 * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = Offset(fullSize / 2, fullSize / 2);

    // Background
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF222222));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * dpr,
    );

    // Letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: const Color(0xFFFF5252),
          fontSize: radius * 1.2,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    // X Cross
    final crossPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 2.5 * dpr
      ..strokeCap = StrokeCap.round;
    
    final d = radius * 0.7;
    canvas.drawLine(center - Offset(d, d), center + Offset(d, d), crossPaint);
    canvas.drawLine(center - Offset(d, -d), center + Offset(d, -d), crossPaint);

    final image = await recorder.endRecording().toImage(fullSize.toInt(), fullSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
