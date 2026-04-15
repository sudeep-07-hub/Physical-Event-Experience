/// Concrete rule-based implementation of [IntentDetectionService].
///
/// Priority order ensures the most actionable intent surfaces first:
/// 1. Gate proximity (UWB < 30m) — highest urgency
/// 2. Bottleneck (score > 0.75) — safety-critical
/// 3. Wait time (dwell_ratio > 0.6) — informational
library;

import '../models/user_context.dart';
import '../models/user_intent.dart';
import 'intent_detection_service.dart';

class IntentDetectionServiceImpl implements IntentDetectionService {
  // ── Thresholds ────────────────────────────────────────────────────────
  static const double _gateProximityThresholdM = 30.0;
  static const double _bottleneckThreshold = 0.75;
  static const double _dwellRatioThreshold = 0.6;

  @override
  UserIntent detectFromContext(UserContext ctx) {
    // Priority 1: Near assigned gate → show ticket QR
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
}
