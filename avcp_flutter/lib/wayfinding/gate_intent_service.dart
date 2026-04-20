import 'package:flutter/foundation.dart';

/// Predicts stadium crowd navigation intent based on localized physics thresholds.
enum WayfindingIntent {
  freeFlowing,
  waitTime,
  rerouting,
  nearGate,
}

/// A zero-PII data structure tracking physics variables around a specific zone.
/// Strictly enforces anonymity: No name, no face, no device ID, no email, no phone.
@immutable
class GateContext {
  const GateContext({
    required this.uwbProximityMeters,
    required this.dwellRatio,
    required this.bottleneckScore,
    required this.speedP95,
    required this.densityPpm2,
    required this.zoneId,
    required this.assignedGateId,
    required this.alternateGateId,
    required this.waitMinutes,
    required this.altWaitMinutes,
    required this.savingsMinutes,
    required this.seatSection,
    required this.streetName,
    required this.landmarkName,
    required this.distanceToTurnMeters,
    required this.ticketToken,
  });

  final double uwbProximityMeters;
  final double dwellRatio;
  final double bottleneckScore;
  final double speedP95;
  final double densityPpm2;
  final String zoneId;
  final String assignedGateId;
  final String alternateGateId;
  final int waitMinutes;
  final int altWaitMinutes;
  final int savingsMinutes;
  final String seatSection;
  final String streetName;
  final String landmarkName;
  final int distanceToTurnMeters;
  final String ticketToken; // anonymized scan token
}

abstract class GateIntentService {
  WayfindingIntent detect(GateContext ctx);
}

class GateIntentServiceImpl implements GateIntentService {
  @override
  WayfindingIntent detect(GateContext ctx) {
    if (ctx.uwbProximityMeters < 30.0) return WayfindingIntent.nearGate;
    if (ctx.bottleneckScore > 0.75) return WayfindingIntent.rerouting;
    if (ctx.dwellRatio > 0.60) return WayfindingIntent.waitTime;
    return WayfindingIntent.freeFlowing;
  }
}
