// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wayfinding_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WayfindingRequest _$WayfindingRequestFromJson(Map<String, dynamic> json) {
  return _WayfindingRequest.fromJson(json);
}

/// @nodoc
mixin _$WayfindingRequest {
  @JsonKey(name: 'from_zone_id')
  String get fromZoneId => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_zone_id')
  String get toZoneId => throw _privateConstructorUsedError;

  /// Zone IDs to avoid (e.g., congested zones).
  @JsonKey(name: 'avoid_zones')
  List<String> get avoidZones => throw _privateConstructorUsedError;

  /// Serializes this WayfindingRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WayfindingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WayfindingRequestCopyWith<WayfindingRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WayfindingRequestCopyWith<$Res> {
  factory $WayfindingRequestCopyWith(
          WayfindingRequest value, $Res Function(WayfindingRequest) then) =
      _$WayfindingRequestCopyWithImpl<$Res, WayfindingRequest>;
  @useResult
  $Res call(
      {@JsonKey(name: 'from_zone_id') String fromZoneId,
      @JsonKey(name: 'to_zone_id') String toZoneId,
      @JsonKey(name: 'avoid_zones') List<String> avoidZones});
}

/// @nodoc
class _$WayfindingRequestCopyWithImpl<$Res, $Val extends WayfindingRequest>
    implements $WayfindingRequestCopyWith<$Res> {
  _$WayfindingRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WayfindingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromZoneId = null,
    Object? toZoneId = null,
    Object? avoidZones = null,
  }) {
    return _then(_value.copyWith(
      fromZoneId: null == fromZoneId
          ? _value.fromZoneId
          : fromZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      toZoneId: null == toZoneId
          ? _value.toZoneId
          : toZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      avoidZones: null == avoidZones
          ? _value.avoidZones
          : avoidZones // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WayfindingRequestImplCopyWith<$Res>
    implements $WayfindingRequestCopyWith<$Res> {
  factory _$$WayfindingRequestImplCopyWith(_$WayfindingRequestImpl value,
          $Res Function(_$WayfindingRequestImpl) then) =
      __$$WayfindingRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'from_zone_id') String fromZoneId,
      @JsonKey(name: 'to_zone_id') String toZoneId,
      @JsonKey(name: 'avoid_zones') List<String> avoidZones});
}

/// @nodoc
class __$$WayfindingRequestImplCopyWithImpl<$Res>
    extends _$WayfindingRequestCopyWithImpl<$Res, _$WayfindingRequestImpl>
    implements _$$WayfindingRequestImplCopyWith<$Res> {
  __$$WayfindingRequestImplCopyWithImpl(_$WayfindingRequestImpl _value,
      $Res Function(_$WayfindingRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of WayfindingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromZoneId = null,
    Object? toZoneId = null,
    Object? avoidZones = null,
  }) {
    return _then(_$WayfindingRequestImpl(
      fromZoneId: null == fromZoneId
          ? _value.fromZoneId
          : fromZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      toZoneId: null == toZoneId
          ? _value.toZoneId
          : toZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      avoidZones: null == avoidZones
          ? _value._avoidZones
          : avoidZones // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WayfindingRequestImpl implements _WayfindingRequest {
  const _$WayfindingRequestImpl(
      {@JsonKey(name: 'from_zone_id') required this.fromZoneId,
      @JsonKey(name: 'to_zone_id') required this.toZoneId,
      @JsonKey(name: 'avoid_zones') final List<String> avoidZones = const []})
      : _avoidZones = avoidZones;

  factory _$WayfindingRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$WayfindingRequestImplFromJson(json);

  @override
  @JsonKey(name: 'from_zone_id')
  final String fromZoneId;
  @override
  @JsonKey(name: 'to_zone_id')
  final String toZoneId;

  /// Zone IDs to avoid (e.g., congested zones).
  final List<String> _avoidZones;

  /// Zone IDs to avoid (e.g., congested zones).
  @override
  @JsonKey(name: 'avoid_zones')
  List<String> get avoidZones {
    if (_avoidZones is EqualUnmodifiableListView) return _avoidZones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_avoidZones);
  }

  @override
  String toString() {
    return 'WayfindingRequest(fromZoneId: $fromZoneId, toZoneId: $toZoneId, avoidZones: $avoidZones)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WayfindingRequestImpl &&
            (identical(other.fromZoneId, fromZoneId) ||
                other.fromZoneId == fromZoneId) &&
            (identical(other.toZoneId, toZoneId) ||
                other.toZoneId == toZoneId) &&
            const DeepCollectionEquality()
                .equals(other._avoidZones, _avoidZones));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fromZoneId, toZoneId,
      const DeepCollectionEquality().hash(_avoidZones));

  /// Create a copy of WayfindingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WayfindingRequestImplCopyWith<_$WayfindingRequestImpl> get copyWith =>
      __$$WayfindingRequestImplCopyWithImpl<_$WayfindingRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WayfindingRequestImplToJson(
      this,
    );
  }
}

abstract class _WayfindingRequest implements WayfindingRequest {
  const factory _WayfindingRequest(
          {@JsonKey(name: 'from_zone_id') required final String fromZoneId,
          @JsonKey(name: 'to_zone_id') required final String toZoneId,
          @JsonKey(name: 'avoid_zones') final List<String> avoidZones}) =
      _$WayfindingRequestImpl;

  factory _WayfindingRequest.fromJson(Map<String, dynamic> json) =
      _$WayfindingRequestImpl.fromJson;

  @override
  @JsonKey(name: 'from_zone_id')
  String get fromZoneId;
  @override
  @JsonKey(name: 'to_zone_id')
  String get toZoneId;

  /// Zone IDs to avoid (e.g., congested zones).
  @override
  @JsonKey(name: 'avoid_zones')
  List<String> get avoidZones;

  /// Create a copy of WayfindingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WayfindingRequestImplCopyWith<_$WayfindingRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
