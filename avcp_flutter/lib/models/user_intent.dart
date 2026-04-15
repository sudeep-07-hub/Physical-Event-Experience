/// User intent — the output of [IntentDetectionService].
///
/// Modeled as a Freezed union so each intent variant can carry its own
/// payload (e.g., gate ID for ticket QR, route for alternate suggestion).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_intent.freezed.dart';

@freezed
sealed class UserIntent with _$UserIntent {
  /// No actionable intent detected.
  const factory UserIntent.none() = IntentNone;

  /// User is within 30m of their assigned gate → surface ticket QR.
  const factory UserIntent.showTicketQR({
    required String gateId,
    required double distanceMetres,
  }) = IntentShowTicketQR;

  /// Zone dwell_ratio > 0.6 → show estimated wait time.
  const factory UserIntent.showWaitTime({
    required String zoneId,
    required double dwellRatio,
    required int estimatedWaitMinutes,
  }) = IntentShowWaitTime;

  /// Zone bottleneck_score > 0.75 → suggest alternate route.
  const factory UserIntent.offerAlternateRoute({
    required String fromZoneId,
    required String suggestedZoneId,
    required double bottleneckScore,
  }) = IntentOfferAlternateRoute;
}
