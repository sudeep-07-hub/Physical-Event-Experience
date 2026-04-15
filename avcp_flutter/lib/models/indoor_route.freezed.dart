// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'indoor_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RouteWaypoint _$RouteWaypointFromJson(Map<String, dynamic> json) {
  return _RouteWaypoint.fromJson(json);
}

/// @nodoc
mixin _$RouteWaypoint {
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;

  /// Floor level (0 = ground).
  int get floor => throw _privateConstructorUsedError;

  /// Optional label, e.g. "Turn left at Gate C".
  String? get instruction => throw _privateConstructorUsedError;

  /// Serializes this RouteWaypoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteWaypointCopyWith<RouteWaypoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteWaypointCopyWith<$Res> {
  factory $RouteWaypointCopyWith(
          RouteWaypoint value, $Res Function(RouteWaypoint) then) =
      _$RouteWaypointCopyWithImpl<$Res, RouteWaypoint>;
  @useResult
  $Res call({double lat, double lng, int floor, String? instruction});
}

/// @nodoc
class _$RouteWaypointCopyWithImpl<$Res, $Val extends RouteWaypoint>
    implements $RouteWaypointCopyWith<$Res> {
  _$RouteWaypointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? floor = null,
    Object? instruction = freezed,
  }) {
    return _then(_value.copyWith(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      floor: null == floor
          ? _value.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as int,
      instruction: freezed == instruction
          ? _value.instruction
          : instruction // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RouteWaypointImplCopyWith<$Res>
    implements $RouteWaypointCopyWith<$Res> {
  factory _$$RouteWaypointImplCopyWith(
          _$RouteWaypointImpl value, $Res Function(_$RouteWaypointImpl) then) =
      __$$RouteWaypointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double lat, double lng, int floor, String? instruction});
}

/// @nodoc
class __$$RouteWaypointImplCopyWithImpl<$Res>
    extends _$RouteWaypointCopyWithImpl<$Res, _$RouteWaypointImpl>
    implements _$$RouteWaypointImplCopyWith<$Res> {
  __$$RouteWaypointImplCopyWithImpl(
      _$RouteWaypointImpl _value, $Res Function(_$RouteWaypointImpl) _then)
      : super(_value, _then);

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? floor = null,
    Object? instruction = freezed,
  }) {
    return _then(_$RouteWaypointImpl(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      floor: null == floor
          ? _value.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as int,
      instruction: freezed == instruction
          ? _value.instruction
          : instruction // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteWaypointImpl implements _RouteWaypoint {
  const _$RouteWaypointImpl(
      {required this.lat, required this.lng, this.floor = 0, this.instruction});

  factory _$RouteWaypointImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteWaypointImplFromJson(json);

  @override
  final double lat;
  @override
  final double lng;

  /// Floor level (0 = ground).
  @override
  @JsonKey()
  final int floor;

  /// Optional label, e.g. "Turn left at Gate C".
  @override
  final String? instruction;

  @override
  String toString() {
    return 'RouteWaypoint(lat: $lat, lng: $lng, floor: $floor, instruction: $instruction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteWaypointImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.instruction, instruction) ||
                other.instruction == instruction));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, lat, lng, floor, instruction);

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteWaypointImplCopyWith<_$RouteWaypointImpl> get copyWith =>
      __$$RouteWaypointImplCopyWithImpl<_$RouteWaypointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteWaypointImplToJson(
      this,
    );
  }
}

abstract class _RouteWaypoint implements RouteWaypoint {
  const factory _RouteWaypoint(
      {required final double lat,
      required final double lng,
      final int floor,
      final String? instruction}) = _$RouteWaypointImpl;

  factory _RouteWaypoint.fromJson(Map<String, dynamic> json) =
      _$RouteWaypointImpl.fromJson;

  @override
  double get lat;
  @override
  double get lng;

  /// Floor level (0 = ground).
  @override
  int get floor;

  /// Optional label, e.g. "Turn left at Gate C".
  @override
  String? get instruction;

  /// Create a copy of RouteWaypoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteWaypointImplCopyWith<_$RouteWaypointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IndoorRoute _$IndoorRouteFromJson(Map<String, dynamic> json) {
  return _IndoorRoute.fromJson(json);
}

/// @nodoc
mixin _$IndoorRoute {
  List<RouteWaypoint> get waypoints => throw _privateConstructorUsedError;

  /// Estimated travel time in minutes.
  @JsonKey(name: 'estimated_time_minutes')
  double get estimatedTimeMinutes => throw _privateConstructorUsedError;

  /// Total distance in metres.
  @JsonKey(name: 'distance_m')
  double get distanceM => throw _privateConstructorUsedError;

  /// Serializes this IndoorRoute to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IndoorRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IndoorRouteCopyWith<IndoorRoute> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndoorRouteCopyWith<$Res> {
  factory $IndoorRouteCopyWith(
          IndoorRoute value, $Res Function(IndoorRoute) then) =
      _$IndoorRouteCopyWithImpl<$Res, IndoorRoute>;
  @useResult
  $Res call(
      {List<RouteWaypoint> waypoints,
      @JsonKey(name: 'estimated_time_minutes') double estimatedTimeMinutes,
      @JsonKey(name: 'distance_m') double distanceM});
}

/// @nodoc
class _$IndoorRouteCopyWithImpl<$Res, $Val extends IndoorRoute>
    implements $IndoorRouteCopyWith<$Res> {
  _$IndoorRouteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IndoorRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? waypoints = null,
    Object? estimatedTimeMinutes = null,
    Object? distanceM = null,
  }) {
    return _then(_value.copyWith(
      waypoints: null == waypoints
          ? _value.waypoints
          : waypoints // ignore: cast_nullable_to_non_nullable
              as List<RouteWaypoint>,
      estimatedTimeMinutes: null == estimatedTimeMinutes
          ? _value.estimatedTimeMinutes
          : estimatedTimeMinutes // ignore: cast_nullable_to_non_nullable
              as double,
      distanceM: null == distanceM
          ? _value.distanceM
          : distanceM // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IndoorRouteImplCopyWith<$Res>
    implements $IndoorRouteCopyWith<$Res> {
  factory _$$IndoorRouteImplCopyWith(
          _$IndoorRouteImpl value, $Res Function(_$IndoorRouteImpl) then) =
      __$$IndoorRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<RouteWaypoint> waypoints,
      @JsonKey(name: 'estimated_time_minutes') double estimatedTimeMinutes,
      @JsonKey(name: 'distance_m') double distanceM});
}

/// @nodoc
class __$$IndoorRouteImplCopyWithImpl<$Res>
    extends _$IndoorRouteCopyWithImpl<$Res, _$IndoorRouteImpl>
    implements _$$IndoorRouteImplCopyWith<$Res> {
  __$$IndoorRouteImplCopyWithImpl(
      _$IndoorRouteImpl _value, $Res Function(_$IndoorRouteImpl) _then)
      : super(_value, _then);

  /// Create a copy of IndoorRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? waypoints = null,
    Object? estimatedTimeMinutes = null,
    Object? distanceM = null,
  }) {
    return _then(_$IndoorRouteImpl(
      waypoints: null == waypoints
          ? _value._waypoints
          : waypoints // ignore: cast_nullable_to_non_nullable
              as List<RouteWaypoint>,
      estimatedTimeMinutes: null == estimatedTimeMinutes
          ? _value.estimatedTimeMinutes
          : estimatedTimeMinutes // ignore: cast_nullable_to_non_nullable
              as double,
      distanceM: null == distanceM
          ? _value.distanceM
          : distanceM // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IndoorRouteImpl implements _IndoorRoute {
  const _$IndoorRouteImpl(
      {required final List<RouteWaypoint> waypoints,
      @JsonKey(name: 'estimated_time_minutes')
      required this.estimatedTimeMinutes,
      @JsonKey(name: 'distance_m') required this.distanceM})
      : _waypoints = waypoints;

  factory _$IndoorRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$IndoorRouteImplFromJson(json);

  final List<RouteWaypoint> _waypoints;
  @override
  List<RouteWaypoint> get waypoints {
    if (_waypoints is EqualUnmodifiableListView) return _waypoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_waypoints);
  }

  /// Estimated travel time in minutes.
  @override
  @JsonKey(name: 'estimated_time_minutes')
  final double estimatedTimeMinutes;

  /// Total distance in metres.
  @override
  @JsonKey(name: 'distance_m')
  final double distanceM;

  @override
  String toString() {
    return 'IndoorRoute(waypoints: $waypoints, estimatedTimeMinutes: $estimatedTimeMinutes, distanceM: $distanceM)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IndoorRouteImpl &&
            const DeepCollectionEquality()
                .equals(other._waypoints, _waypoints) &&
            (identical(other.estimatedTimeMinutes, estimatedTimeMinutes) ||
                other.estimatedTimeMinutes == estimatedTimeMinutes) &&
            (identical(other.distanceM, distanceM) ||
                other.distanceM == distanceM));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_waypoints),
      estimatedTimeMinutes,
      distanceM);

  /// Create a copy of IndoorRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IndoorRouteImplCopyWith<_$IndoorRouteImpl> get copyWith =>
      __$$IndoorRouteImplCopyWithImpl<_$IndoorRouteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IndoorRouteImplToJson(
      this,
    );
  }
}

abstract class _IndoorRoute implements IndoorRoute {
  const factory _IndoorRoute(
          {required final List<RouteWaypoint> waypoints,
          @JsonKey(name: 'estimated_time_minutes')
          required final double estimatedTimeMinutes,
          @JsonKey(name: 'distance_m') required final double distanceM}) =
      _$IndoorRouteImpl;

  factory _IndoorRoute.fromJson(Map<String, dynamic> json) =
      _$IndoorRouteImpl.fromJson;

  @override
  List<RouteWaypoint> get waypoints;

  /// Estimated travel time in minutes.
  @override
  @JsonKey(name: 'estimated_time_minutes')
  double get estimatedTimeMinutes;

  /// Total distance in metres.
  @override
  @JsonKey(name: 'distance_m')
  double get distanceM;

  /// Create a copy of IndoorRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IndoorRouteImplCopyWith<_$IndoorRouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
