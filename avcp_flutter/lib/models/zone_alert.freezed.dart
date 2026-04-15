// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zone_alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ZoneAlert _$ZoneAlertFromJson(Map<String, dynamic> json) {
  return _ZoneAlert.fromJson(json);
}

/// @nodoc
mixin _$ZoneAlert {
  @JsonKey(name: 'zone_id')
  String get zoneId => throw _privateConstructorUsedError;
  @JsonKey(name: 'alert_type')
  AlertType get alertType => throw _privateConstructorUsedError;
  CongestionLevel get severity => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: 'timestamp_ms')
  int get timestampMs => throw _privateConstructorUsedError;

  /// Whether an operator has acknowledged this alert.
  bool get acknowledged => throw _privateConstructorUsedError;

  /// Serializes this ZoneAlert to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ZoneAlert
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ZoneAlertCopyWith<ZoneAlert> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ZoneAlertCopyWith<$Res> {
  factory $ZoneAlertCopyWith(ZoneAlert value, $Res Function(ZoneAlert) then) =
      _$ZoneAlertCopyWithImpl<$Res, ZoneAlert>;
  @useResult
  $Res call(
      {@JsonKey(name: 'zone_id') String zoneId,
      @JsonKey(name: 'alert_type') AlertType alertType,
      CongestionLevel severity,
      String message,
      @JsonKey(name: 'timestamp_ms') int timestampMs,
      bool acknowledged});
}

/// @nodoc
class _$ZoneAlertCopyWithImpl<$Res, $Val extends ZoneAlert>
    implements $ZoneAlertCopyWith<$Res> {
  _$ZoneAlertCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ZoneAlert
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? zoneId = null,
    Object? alertType = null,
    Object? severity = null,
    Object? message = null,
    Object? timestampMs = null,
    Object? acknowledged = null,
  }) {
    return _then(_value.copyWith(
      zoneId: null == zoneId
          ? _value.zoneId
          : zoneId // ignore: cast_nullable_to_non_nullable
              as String,
      alertType: null == alertType
          ? _value.alertType
          : alertType // ignore: cast_nullable_to_non_nullable
              as AlertType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as CongestionLevel,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      timestampMs: null == timestampMs
          ? _value.timestampMs
          : timestampMs // ignore: cast_nullable_to_non_nullable
              as int,
      acknowledged: null == acknowledged
          ? _value.acknowledged
          : acknowledged // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ZoneAlertImplCopyWith<$Res>
    implements $ZoneAlertCopyWith<$Res> {
  factory _$$ZoneAlertImplCopyWith(
          _$ZoneAlertImpl value, $Res Function(_$ZoneAlertImpl) then) =
      __$$ZoneAlertImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'zone_id') String zoneId,
      @JsonKey(name: 'alert_type') AlertType alertType,
      CongestionLevel severity,
      String message,
      @JsonKey(name: 'timestamp_ms') int timestampMs,
      bool acknowledged});
}

/// @nodoc
class __$$ZoneAlertImplCopyWithImpl<$Res>
    extends _$ZoneAlertCopyWithImpl<$Res, _$ZoneAlertImpl>
    implements _$$ZoneAlertImplCopyWith<$Res> {
  __$$ZoneAlertImplCopyWithImpl(
      _$ZoneAlertImpl _value, $Res Function(_$ZoneAlertImpl) _then)
      : super(_value, _then);

  /// Create a copy of ZoneAlert
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? zoneId = null,
    Object? alertType = null,
    Object? severity = null,
    Object? message = null,
    Object? timestampMs = null,
    Object? acknowledged = null,
  }) {
    return _then(_$ZoneAlertImpl(
      zoneId: null == zoneId
          ? _value.zoneId
          : zoneId // ignore: cast_nullable_to_non_nullable
              as String,
      alertType: null == alertType
          ? _value.alertType
          : alertType // ignore: cast_nullable_to_non_nullable
              as AlertType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as CongestionLevel,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      timestampMs: null == timestampMs
          ? _value.timestampMs
          : timestampMs // ignore: cast_nullable_to_non_nullable
              as int,
      acknowledged: null == acknowledged
          ? _value.acknowledged
          : acknowledged // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ZoneAlertImpl implements _ZoneAlert {
  const _$ZoneAlertImpl(
      {@JsonKey(name: 'zone_id') required this.zoneId,
      @JsonKey(name: 'alert_type') required this.alertType,
      required this.severity,
      required this.message,
      @JsonKey(name: 'timestamp_ms') required this.timestampMs,
      this.acknowledged = false});

  factory _$ZoneAlertImpl.fromJson(Map<String, dynamic> json) =>
      _$$ZoneAlertImplFromJson(json);

  @override
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @override
  @JsonKey(name: 'alert_type')
  final AlertType alertType;
  @override
  final CongestionLevel severity;
  @override
  final String message;
  @override
  @JsonKey(name: 'timestamp_ms')
  final int timestampMs;

  /// Whether an operator has acknowledged this alert.
  @override
  @JsonKey()
  final bool acknowledged;

  @override
  String toString() {
    return 'ZoneAlert(zoneId: $zoneId, alertType: $alertType, severity: $severity, message: $message, timestampMs: $timestampMs, acknowledged: $acknowledged)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ZoneAlertImpl &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.alertType, alertType) ||
                other.alertType == alertType) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.timestampMs, timestampMs) ||
                other.timestampMs == timestampMs) &&
            (identical(other.acknowledged, acknowledged) ||
                other.acknowledged == acknowledged));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, zoneId, alertType, severity,
      message, timestampMs, acknowledged);

  /// Create a copy of ZoneAlert
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ZoneAlertImplCopyWith<_$ZoneAlertImpl> get copyWith =>
      __$$ZoneAlertImplCopyWithImpl<_$ZoneAlertImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ZoneAlertImplToJson(
      this,
    );
  }
}

abstract class _ZoneAlert implements ZoneAlert {
  const factory _ZoneAlert(
      {@JsonKey(name: 'zone_id') required final String zoneId,
      @JsonKey(name: 'alert_type') required final AlertType alertType,
      required final CongestionLevel severity,
      required final String message,
      @JsonKey(name: 'timestamp_ms') required final int timestampMs,
      final bool acknowledged}) = _$ZoneAlertImpl;

  factory _ZoneAlert.fromJson(Map<String, dynamic> json) =
      _$ZoneAlertImpl.fromJson;

  @override
  @JsonKey(name: 'zone_id')
  String get zoneId;
  @override
  @JsonKey(name: 'alert_type')
  AlertType get alertType;
  @override
  CongestionLevel get severity;
  @override
  String get message;
  @override
  @JsonKey(name: 'timestamp_ms')
  int get timestampMs;

  /// Whether an operator has acknowledged this alert.
  @override
  bool get acknowledged;

  /// Create a copy of ZoneAlert
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ZoneAlertImplCopyWith<_$ZoneAlertImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
