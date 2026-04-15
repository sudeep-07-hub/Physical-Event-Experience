/// Concrete rule-based implementation of [IntentDetectionService].
///
/// Priority order ensures the most actionable intent surfaces first:
/// 1a. Gate zone + UWB < 5m — immediate ticket popup (highest urgency)
/// 1b. Assigned gate + UWB < 30m — softer ticket trigger
/// 2.  Bottleneck (score > 0.75) — safety-critical
/// 3.  Wait time (dwell_ratio > 0.6) — informational
library;

import '../models/user_context.dart';
import '../models/user_intent.dart';
import 'intent_detection_service.dart';

class IntentDetectionServiceImpl implements IntentDetectionService {
  // ── Thresholds ────────────────────────────────────────────────────────
  static const double _gateZoneImmediateThresholdM = 5.0;
  static const double _gateProximityThresholdM = 30.0;
  static const double _bottleneckThreshold = 0.75;
  static const double _dwellRatioThreshold = 0.6;

  @override
  UserIntent detectFromContext(UserContext ctx) {
    // Priority 1a: User enters a "gate" zone AND is within 5m → immediate
    // ticket popup. This catches the moment of arrival at the physical gate.
    if (ctx.currentZoneId.toLowerCase().contains('gate') &&
        ctx.uwbProximityToGateM != null &&
        ctx.uwbProximityToGateM! < _gateZoneImmediateThresholdM) {
      return UserIntent.showTicketQR(
        gateId: ctx.assignedGateId ?? _extractGateId(ctx.currentZoneId),
        distanceMetres: ctx.uwbProximityToGateM!,
      );
    }

    // Priority 1b: Near assigned gate (UWB < 30m) — softer trigger when
    // approaching but not yet at the gate zone.
    if (ctx.assignedGateId != null &&
        ctx.uwbProximityToGateM != null &&
        ctx.uwbProximityToGateM! <= _gateProximityThresholdM) {
      return UserIntent.showTicketQR(
        gateId: ctx.assignedGateId!,
        distanceMetres: ctx.uwbProximityToGateM!,
      );
    }

    // Priority 2: Bottleneck → suggest alternate route
    if (ctx.zoneBottleneckScore > _bottleneckThreshold) {
      return UserIntent.offerAlternateRoute(
        fromZoneId: ctx.currentZoneId,
        // In production, this would come from a route service.
        // For now, we surface the intent and let the UI resolve.
        suggestedZoneId: '${ctx.currentZoneId}_alt',
        bottleneckScore: ctx.zoneBottleneckScore,
      );
    }

    // Priority 3: High dwell → show wait time
    if (ctx.zoneDwellRatio > _dwellRatioThreshold) {
      // Rough heuristic: dwell_ratio 0.6 → ~4 min, 1.0 → ~8 min
      final estimatedWait = (ctx.zoneDwellRatio * 12).ceil().clamp(1, 30);
      return UserIntent.showWaitTime(
        zoneId: ctx.currentZoneId,
        dwellRatio: ctx.zoneDwellRatio,
        estimatedWaitMinutes: estimatedWait,
      );
    }

    return const UserIntent.none();
  }

  /// Extracts a gate ID from the zone name when no assigned gate is set.
  /// e.g. "gate_c_concourse_level2" → "C"
  String _extractGateId(String zoneId) {
    final parts = zoneId.toLowerCase().split('_');
    final gateIdx = parts.indexOf('gate');
    if (gateIdx >= 0 && gateIdx + 1 < parts.length) {
      return parts[gateIdx + 1].toUpperCase();
    }
    return 'UNKNOWN';
  }
}
