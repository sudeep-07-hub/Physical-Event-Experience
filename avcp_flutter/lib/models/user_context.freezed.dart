// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserContext _$UserContextFromJson(Map<String, dynamic> json) {
  return _UserContext.fromJson(json);
}

/// @nodoc
mixin _$UserContext {
  /// Current zone the user is physically in.
  @JsonKey(name: 'current_zone_id')
  String get currentZoneId => throw _privateConstructorUsedError;

  /// UWB-derived distance to the user's assigned gate, in metres.
  /// `null` if UWB is unavailable.
  @JsonKey(name: 'uwb_proximity_to_gate_m')
  double? get uwbProximityToGateM => throw _privateConstructorUsedError;

  /// Gate ID from the user's ticket.
  @JsonKey(name: 'assigned_gate_id')
  String? get assignedGateId => throw _privateConstructorUsedError;

  /// How long the user has been stationary in the current zone, in seconds.
  @JsonKey(name: 'dwell_time_s')
  double get dwellTimeS => throw _privateConstructorUsedError;

  /// Current zone's dwell ratio (from crowd vector).
  @JsonKey(name: 'zone_dwell_ratio')
  double get zoneDwellRatio => throw _privateConstructorUsedError;

  /// Current zone's bottleneck score (from crowd vector).
  @JsonKey(name: 'zone_bottleneck_score')
  double get zoneBottleneckScore => throw _privateConstructorUsedError;

  /// User role — determines UI surface visibility.
  UserRole get role => throw _privateConstructorUsedError;

  /// Serializes this UserContext to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserContextCopyWith<UserContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserContextCopyWith<$Res> {
  factory $UserContextCopyWith(
          UserContext value, $Res Function(UserContext) then) =
      _$UserContextCopyWithImpl<$Res, UserContext>;
  @useResult
  $Res call(
      {@JsonKey(name: 'current_zone_id') String currentZoneId,
      @JsonKey(name: 'uwb_proximity_to_gate_m') double? uwbProximityToGateM,
      @JsonKey(name: 'assigned_gate_id') String? assignedGateId,
      @JsonKey(name: 'dwell_time_s') double dwellTimeS,
      @JsonKey(name: 'zone_dwell_ratio') double zoneDwellRatio,
      @JsonKey(name: 'zone_bottleneck_score') double zoneBottleneckScore,
      UserRole role});
}

/// @nodoc
class _$UserContextCopyWithImpl<$Res, $Val extends UserContext>
    implements $UserContextCopyWith<$Res> {
  _$UserContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentZoneId = null,
    Object? uwbProximityToGateM = freezed,
    Object? assignedGateId = freezed,
    Object? dwellTimeS = null,
    Object? zoneDwellRatio = null,
    Object? zoneBottleneckScore = null,
    Object? role = null,
  }) {
    return _then(_value.copyWith(
      currentZoneId: null == currentZoneId
          ? _value.currentZoneId
          : currentZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      uwbProximityToGateM: freezed == uwbProximityToGateM
          ? _value.uwbProximityToGateM
          : uwbProximityToGateM // ignore: cast_nullable_to_non_nullable
              as double?,
      assignedGateId: freezed == assignedGateId
          ? _value.assignedGateId
          : assignedGateId // ignore: cast_nullable_to_non_nullable
              as String?,
      dwellTimeS: null == dwellTimeS
          ? _value.dwellTimeS
          : dwellTimeS // ignore: cast_nullable_to_non_nullable
              as double,
      zoneDwellRatio: null == zoneDwellRatio
          ? _value.zoneDwellRatio
          : zoneDwellRatio // ignore: cast_nullable_to_non_nullable
              as double,
      zoneBottleneckScore: null == zoneBottleneckScore
          ? _value.zoneBottleneckScore
          : zoneBottleneckScore // ignore: cast_nullable_to_non_nullable
              as double,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserContextImplCopyWith<$Res>
    implements $UserContextCopyWith<$Res> {
  factory _$$UserContextImplCopyWith(
          _$UserContextImpl value, $Res Function(_$UserContextImpl) then) =
      __$$UserContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'current_zone_id') String currentZoneId,
      @JsonKey(name: 'uwb_proximity_to_gate_m') double? uwbProximityToGateM,
      @JsonKey(name: 'assigned_gate_id') String? assignedGateId,
      @JsonKey(name: 'dwell_time_s') double dwellTimeS,
      @JsonKey(name: 'zone_dwell_ratio') double zoneDwellRatio,
      @JsonKey(name: 'zone_bottleneck_score') double zoneBottleneckScore,
      UserRole role});
}

/// @nodoc
class __$$UserContextImplCopyWithImpl<$Res>
    extends _$UserContextCopyWithImpl<$Res, _$UserContextImpl>
    implements _$$UserContextImplCopyWith<$Res> {
  __$$UserContextImplCopyWithImpl(
      _$UserContextImpl _value, $Res Function(_$UserContextImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentZoneId = null,
    Object? uwbProximityToGateM = freezed,
    Object? assignedGateId = freezed,
    Object? dwellTimeS = null,
    Object? zoneDwellRatio = null,
    Object? zoneBottleneckScore = null,
    Object? role = null,
  }) {
    return _then(_$UserContextImpl(
      currentZoneId: null == currentZoneId
          ? _value.currentZoneId
          : currentZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      uwbProximityToGateM: freezed == uwbProximityToGateM
          ? _value.uwbProximityToGateM
          : uwbProximityToGateM // ignore: cast_nullable_to_non_nullable
              as double?,
      assignedGateId: freezed == assignedGateId
          ? _value.assignedGateId
          : assignedGateId // ignore: cast_nullable_to_non_nullable
              as String?,
      dwellTimeS: null == dwellTimeS
          ? _value.dwellTimeS
          : dwellTimeS // ignore: cast_nullable_to_non_nullable
              as double,
      zoneDwellRatio: null == zoneDwellRatio
          ? _value.zoneDwellRatio
          : zoneDwellRatio // ignore: cast_nullable_to_non_nullable
              as double,
      zoneBottleneckScore: null == zoneBottleneckScore
          ? _value.zoneBottleneckScore
          : zoneBottleneckScore // ignore: cast_nullable_to_non_nullable
              as double,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserContextImpl implements _UserContext {
  const _$UserContextImpl(
      {@JsonKey(name: 'current_zone_id') required this.currentZoneId,
      @JsonKey(name: 'uwb_proximity_to_gate_m') this.uwbProximityToGateM,
      @JsonKey(name: 'assigned_gate_id') this.assignedGateId,
      @JsonKey(name: 'dwell_time_s') this.dwellTimeS = 0.0,
      @JsonKey(name: 'zone_dwell_ratio') this.zoneDwellRatio = 0.0,
      @JsonKey(name: 'zone_bottleneck_score') this.zoneBottleneckScore = 0.0,
      this.role = UserRole.attendee});

  factory _$UserContextImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserContextImplFromJson(json);

  /// Current zone the user is physically in.
  @override
  @JsonKey(name: 'current_zone_id')
  final String currentZoneId;

  /// UWB-derived distance to the user's assigned gate, in metres.
  /// `null` if UWB is unavailable.
  @override
  @JsonKey(name: 'uwb_proximity_to_gate_m')
  final double? uwbProximityToGateM;

  /// Gate ID from the user's ticket.
  @override
  @JsonKey(name: 'assigned_gate_id')
  final String? assignedGateId;

  /// How long the user has been stationary in the current zone, in seconds.
  @override
  @JsonKey(name: 'dwell_time_s')
  final double dwellTimeS;

  /// Current zone's dwell ratio (from crowd vector).
  @override
  @JsonKey(name: 'zone_dwell_ratio')
  final double zoneDwellRatio;

  /// Current zone's bottleneck score (from crowd vector).
  @override
  @JsonKey(name: 'zone_bottleneck_score')
  final double zoneBottleneckScore;

  /// User role — determines UI surface visibility.
  @override
  @JsonKey()
  final UserRole role;

  @override
  String toString() {
    return 'UserContext(currentZoneId: $currentZoneId, uwbProximityToGateM: $uwbProximityToGateM, assignedGateId: $assignedGateId, dwellTimeS: $dwellTimeS, zoneDwellRatio: $zoneDwellRatio, zoneBottleneckScore: $zoneBottleneckScore, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserContextImpl &&
            (identical(other.currentZoneId, currentZoneId) ||
                other.currentZoneId == currentZoneId) &&
            (identical(other.uwbProximityToGateM, uwbProximityToGateM) ||
                other.uwbProximityToGateM == uwbProximityToGateM) &&
            (identical(other.assignedGateId, assignedGateId) ||
                other.assignedGateId == assignedGateId) &&
            (identical(other.dwellTimeS, dwellTimeS) ||
                other.dwellTimeS == dwellTimeS) &&
            (identical(other.zoneDwellRatio, zoneDwellRatio) ||
                other.zoneDwellRatio == zoneDwellRatio) &&
            (identical(other.zoneBottleneckScore, zoneBottleneckScore) ||
                other.zoneBottleneckScore == zoneBottleneckScore) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentZoneId,
      uwbProximityToGateM,
      assignedGateId,
      dwellTimeS,
      zoneDwellRatio,
      zoneBottleneckScore,
      role);

  /// Create a copy of UserContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserContextImplCopyWith<_$UserContextImpl> get copyWith =>
      __$$UserContextImplCopyWithImpl<_$UserContextImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserContextImplToJson(
      this,
    );
  }
}

abstract class _UserContext implements UserContext {
  const factory _UserContext(
      {@JsonKey(name: 'current_zone_id') required final String currentZoneId,
      @JsonKey(name: 'uwb_proximity_to_gate_m')
      final double? uwbProximityToGateM,
      @JsonKey(name: 'assigned_gate_id') final String? assignedGateId,
      @JsonKey(name: 'dwell_time_s') final double dwellTimeS,
      @JsonKey(name: 'zone_dwell_ratio') final double zoneDwellRatio,
      @JsonKey(name: 'zone_bottleneck_score') final double zoneBottleneckScore,
      final UserRole role}) = _$UserContextImpl;

  factory _UserContext.fromJson(Map<String, dynamic> json) =
      _$UserContextImpl.fromJson;

  /// Current zone the user is physically in.
  @override
  @JsonKey(name: 'current_zone_id')
  String get currentZoneId;

  /// UWB-derived distance to the user's assigned gate, in metres.
  /// `null` if UWB is unavailable.
  @override
  @JsonKey(name: 'uwb_proximity_to_gate_m')
  double? get uwbProximityToGateM;

  /// Gate ID from the user's ticket.
  @override
  @JsonKey(name: 'assigned_gate_id')
  String? get assignedGateId;

  /// How long the user has been stationary in the current zone, in seconds.
  @override
  @JsonKey(name: 'dwell_time_s')
  double get dwellTimeS;

  /// Current zone's dwell ratio (from crowd vector).
  @override
  @JsonKey(name: 'zone_dwell_ratio')
  double get zoneDwellRatio;

  /// Current zone's bottleneck score (from crowd vector).
  @override
  @JsonKey(name: 'zone_bottleneck_score')
  double get zoneBottleneckScore;

  /// User role — determines UI surface visibility.
  @override
  UserRole get role;

  /// Create a copy of UserContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserContextImplCopyWith<_$UserContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
