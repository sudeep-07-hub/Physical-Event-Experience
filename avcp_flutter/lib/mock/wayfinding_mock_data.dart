import 'dart:async';
import '../wayfinding/gate_intent_service.dart';

final class WayfindingMockData {
  WayfindingMockData._();

  static Stream<GateContext> contextStream({
    Duration interval = const Duration(seconds: 2),
  }) async* {
    int tick = 0;
    while (true) {
      final int cycleTime = tick % 48; // 48s complete cycle

      if (cycleTime < 12) {
        // Cycle A: FREE FLOWING (0-12s)
        yield const GateContext(
          uwbProximityMeters: 280,
          bottleneckScore: 0.18,
          dwellRatio: 0.22,
          speedP95: 1.2,
          densityPpm2: 1.2,
          waitMinutes: 4,
          altWaitMinutes: 0,
          savingsMinutes: 0,
          streetName: "Occidental Ave S",
          landmarkName: "WaMu Theater",
          distanceToTurnMeters: 280,
          assignedGateId: "C",
          alternateGateId: "D",
          seatSection: "114",
          ticketToken: "AVCP-2024-SEC114-R12-S7",
          zoneId: "Z-114",
        );
      } else if (cycleTime < 24) {
        // Cycle B: CONGESTED / REROUTING (12-24s)
        yield const GateContext(
          uwbProximityMeters: 220,
          bottleneckScore: 0.82,
          dwellRatio: 0.74,
          speedP95: 0.2,
          densityPpm2: 5.6,
          waitMinutes: 14,
          altWaitMinutes: 3,
          savingsMinutes: 11,
          streetName: "4th Ave S",
          landmarkName: "BNSF crossing",
          distanceToTurnMeters: 320,
          assignedGateId: "C",
          alternateGateId: "D",
          seatSection: "114",
          ticketToken: "AVCP-2024-SEC114-R12-S7",
          zoneId: "Z-114",
        );
      } else if (cycleTime < 36) {
        // Cycle C: WAIT TIME (24-36s)
        yield const GateContext(
          uwbProximityMeters: 180,
          bottleneckScore: 0.45,
          dwellRatio: 0.68,
          speedP95: 0.5,
          densityPpm2: 3.8,
          waitMinutes: 9,
          altWaitMinutes: 4,
          savingsMinutes: 0,
          streetName: "Occidental Ave S",
          landmarkName: "Silver Cloud Hotel",
          distanceToTurnMeters: 190,
          assignedGateId: "C",
          alternateGateId: "D",
          seatSection: "114",
          ticketToken: "AVCP-2024-SEC114-R12-S7",
          zoneId: "Z-114",
        );
      } else {
        // Cycle D: NEAR GATE (36-48s)
        yield const GateContext(
          uwbProximityMeters: 18,
          bottleneckScore: 0.12,
          dwellRatio: 0.15,
          speedP95: 1.1,
          densityPpm2: 0.8,
          waitMinutes: 0,
          altWaitMinutes: 0,
          savingsMinutes: 0,
          streetName: "Stadium Plaza",
          landmarkName: "Gate C Enter",
          distanceToTurnMeters: 18,
          assignedGateId: "C",
          alternateGateId: "D",
          seatSection: "114",
          ticketToken: "AVCP-2024-SEC114-R12-S7",
          zoneId: "Z-114",
        );
      }

      tick += 2;
      await Future<void>.delayed(interval);
    }
  }
}
