import 'package:flutter_test/flutter_test.dart';
import 'package:avcp_flutter/wayfinding/gate_intent_service.dart';

void main() {
  group('GateIntentService Rules', () {
    final service = GateIntentServiceImpl();

    GateContext _buildContext({
      double uwbProximity = 100.0,
      double bottleneck = 0.0,
      double dwell = 0.0,
    }) {
      return GateContext(
        uwbProximityMeters: uwbProximity,
        bottleneckScore: bottleneck,
        dwellRatio: dwell,
        speedP95: 1.0,
        densityPpm2: 1.0,
        zoneId: 'Z1',
        assignedGateId: 'A',
        alternateGateId: 'B',
        waitMinutes: 5,
        altWaitMinutes: 0,
        savingsMinutes: 0,
        seatSection: '100',
        streetName: 'Main St',
        landmarkName: 'Statue',
        distanceToTurnMeters: 50,
        ticketToken: 'ABC',
      );
    }

    test('(a) priority: nearGate beats rerouting when both true', () {
      final ctx = _buildContext(uwbProximity: 15.0, bottleneck: 0.90);
      expect(service.detect(ctx), WayfindingIntent.nearGate);
    });

    test('(b) priority: rerouting beats waitTime', () {
      final ctx = _buildContext(bottleneck: 0.85, dwell: 0.90);
      expect(service.detect(ctx), WayfindingIntent.rerouting);
    });

    test('(c) freeFlowing returned when all thresholds below trigger', () {
      final ctx = _buildContext(uwbProximity: 100.0, bottleneck: 0.2, dwell: 0.3);
      expect(service.detect(ctx), WayfindingIntent.freeFlowing);
    });

    test('(d) boundary: uwbProximity exactly 30.0 -> freeFlowing', () {
      final ctx = _buildContext(uwbProximity: 30.0);
      expect(service.detect(ctx), WayfindingIntent.freeFlowing);
    });

    test('(e) boundary: bottleneckScore exactly 0.75 -> waitTime', () {
      // Because > 0.75 is rerouting, exactly 0.75 falls through.
      // If dwell > 0.60 it returns waitTime.
      final ctx = _buildContext(bottleneck: 0.75, dwell: 0.65);
      expect(service.detect(ctx), WayfindingIntent.waitTime);
    });
  });
}
