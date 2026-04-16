/// AVCP Intent Detection Service — Triple-Threat UI v1.0.0
///
/// Determines which contextual banner to surface based on anonymous
/// crowd signals. Zero PII — only zone_id and float vectors.
///
/// Priority: rerouting > ticketQr > waitTime > none.
library;

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════
// User Intent Enum
// ══════════════════════════════════════════════════════════════════════

/// The intent to surface via [ContextualActionBanner].
///
/// Ordered by priority: [rerouting] > [ticketQr] > [waitTime] > [none].
enum UserIntent {
  /// No actionable intent — show nothing.
  none,

  /// Fan is near a gate — surface ticket QR for scan-to-enter.
  ticketQr,

  /// High dwell ratio — show estimated wait time and congestion info.
  waitTime,

  /// Severe bottleneck — offer an alternate, faster route.
  rerouting,
}

// ══════════════════════════════════════════════════════════════════════
// User Context (PII-free)
// ══════════════════════════════════════════════════════════════════════

/// Anonymous context derived from UWB positioning and crowd vectors.
///
/// **Zero PII**: No name, face, email, device ID, or biometric data.
/// Only zone-level identifiers and aggregate float signals.
@immutable
class UserContext {
  const UserContext({
    required this.uwbProximityMeters,
    required this.dwellRatio,
    required this.bottleneckScore,
    required this.zoneId,
    required this.assignedGateId,
    required this.waitMinutes,
  });

  /// Distance to assigned gate in metres (from UWB anchors).
  final double uwbProximityMeters;

  /// Fraction of population with speed < 0.3 m/s. Range [0, 1].
  final double dwellRatio;

  /// 0=free-flow, 1=gridlock. Greenshields model.
  final double bottleneckScore;

  /// Venue-scoped zone identifier (e.g. "gate_c_concourse_l2").
  final String zoneId;

  /// Assigned entry gate for this anonymous session.
  final String assignedGateId;

  /// Estimated wait time in minutes for the current zone.
  final int waitMinutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserContext &&
        other.uwbProximityMeters == uwbProximityMeters &&
        other.dwellRatio == dwellRatio &&
        other.bottleneckScore == bottleneckScore &&
        other.zoneId == zoneId &&
        other.assignedGateId == assignedGateId &&
        other.waitMinutes == waitMinutes;
  }

  @override
  int get hashCode => Object.hash(
        uwbProximityMeters,
        dwellRatio,
        bottleneckScore,
        zoneId,
        assignedGateId,
        waitMinutes,
      );
}

// ══════════════════════════════════════════════════════════════════════
// Intent Detection — Abstract + Implementation
// ══════════════════════════════════════════════════════════════════════

/// Abstract interface for intent detection.
///
/// Implementations must respect the priority ordering:
/// rerouting > ticketQr > waitTime > none.
abstract class IntentDetectionService {
  /// Detect the highest-priority intent from the given [ctx].
  UserIntent detectIntent(UserContext ctx);
}

/// Rule-based intent detection with strict priority ordering.
///
/// | Priority | Intent      | Trigger Condition         |
/// |----------|-------------|---------------------------|
/// | 1 (high) | rerouting   | bottleneckScore > 0.75    |
/// | 2        | ticketQr    | uwbProximityMeters < 30.0 |
/// | 3        | waitTime    | dwellRatio > 0.60         |
/// | 4 (low)  | none        | default                   |
class IntentDetectionServiceImpl implements IntentDetectionService {
  const IntentDetectionServiceImpl();

  @override
  UserIntent detectIntent(UserContext ctx) {
    // Priority 1: Severe bottleneck → reroute immediately
    if (ctx.bottleneckScore > 0.75) {
      return UserIntent.rerouting;
    }

    // Priority 2: Near gate → surface ticket QR
    if (ctx.uwbProximityMeters < 30.0) {
      return UserIntent.ticketQr;
    }

    // Priority 3: High dwell → show wait time
    if (ctx.dwellRatio > 0.60) {
      return UserIntent.waitTime;
    }

    // Default: no actionable intent
    return UserIntent.none;
  }
}
