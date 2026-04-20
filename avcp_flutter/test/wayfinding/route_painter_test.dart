import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avcp_flutter/wayfinding/route_painter.dart';
import 'package:avcp_flutter/wayfinding/gate_intent_service.dart';
import 'package:avcp_flutter/theme.dart';

void main() {
  group('RoutePainter Caching', () {
    final listA = [const Offset(0, 0), const Offset(10, 10)];
    final listB = [const Offset(0, 0), const Offset(10, 10)]; // Different reference

    test('shouldRepaint returns false when references match', () {
      final p1 = RoutePainter(
        routePoints: listA,
        blockedPoints: const [],
        gates: const [],
        tokens: StadiumColorTokens.standard,
        intent: WayfindingIntent.freeFlowing,
        dashOffset: 0.0,
      );

      final p2 = RoutePainter(
        routePoints: listA, // exact reference
        blockedPoints: const [],
        gates: const [],
        tokens: StadiumColorTokens.standard,
        intent: WayfindingIntent.freeFlowing,
        dashOffset: 0.0,
      );

      expect(p1.shouldRepaint(p2), isFalse);
    });

    test('shouldRepaint returns true when intent changes', () {
      final p1 = RoutePainter(
        routePoints: listA,
        blockedPoints: const [],
        gates: const [],
        tokens: StadiumColorTokens.standard,
        intent: WayfindingIntent.freeFlowing,
        dashOffset: 0.0,
      );

      final p2 = RoutePainter(
        routePoints: listA,
        blockedPoints: const [],
        gates: const [],
        tokens: StadiumColorTokens.standard,
        intent: WayfindingIntent.rerouting,
        dashOffset: 0.0,
      );

      expect(p1.shouldRepaint(p2), isTrue);
    });
  });
}
