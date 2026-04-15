/// Intent detection service — abstract interface.
///
/// Pure Dart. No Flutter imports. 100% testable.
library;

import '../models/user_context.dart';
import '../models/user_intent.dart';

/// Detects the most relevant user intent from device-local context.
///
/// Rule priority:
/// 1. UWB proximity to assigned gate < 30m → [UserIntent.showTicketQR]
/// 2. Zone bottleneck_score > 0.75 → [UserIntent.offerAlternateRoute]
/// 3. Zone dwell_ratio > 0.6 → [UserIntent.showWaitTime]
/// 4. Otherwise → [UserIntent.none]
abstract class IntentDetectionService {
  /// Detect the highest-priority intent from the current user context.
  UserIntent detectFromContext(UserContext ctx);
}
