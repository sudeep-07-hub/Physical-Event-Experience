/// User context for intent detection.
///
/// Aggregates device-local signals (UWB proximity, current zone, dwell time)
/// that drive the [IntentDetectionService] without exposing PII.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_context.freezed.dart';
part 'user_context.g.dart';

/// Role of the current user — gates access to [OperatorDashboard].
enum UserRole {
  /// General attendee / fan.
  attendee,

  /// Venue staff with operational access.
  staff,

  /// Venue operator with full dashboard + override access.
  operator,
}

@freezed
class UserContext with _$UserContext {
  const factory UserContext({
    /// Current zone the user is physically in.
    @JsonKey(name: 'current_zone_id') required String currentZoneId,

    /// UWB-derived distance to the user's assigned gate, in metres.
    /// `null` if UWB is unavailable.
    @JsonKey(name: 'uwb_proximity_to_gate_m') double? uwbProximityToGateM,

    /// Gate ID from the user's ticket.
    @JsonKey(name: 'assigned_gate_id') String? assignedGateId,

    /// How long the user has been stationary in the current zone, in seconds.
    @JsonKey(name: 'dwell_time_s') @Default(0.0) double dwellTimeS,

    /// Current zone's dwell ratio (from crowd vector).
    @JsonKey(name: 'zone_dwell_ratio') @Default(0.0) double zoneDwellRatio,

    /// Current zone's bottleneck score (from crowd vector).
    @JsonKey(name: 'zone_bottleneck_score')
    @Default(0.0)
    double zoneBottleneckScore,

    /// User role — determines UI surface visibility.
    @Default(UserRole.attendee) UserRole role,
  }) = _UserContext;

  factory UserContext.fromJson(Map<String, dynamic> json) =>
      _$UserContextFromJson(json);
}
