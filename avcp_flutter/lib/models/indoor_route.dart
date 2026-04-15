/// Indoor route computed by [MapsService].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'indoor_route.freezed.dart';
part 'indoor_route.g.dart';

@freezed
class RouteWaypoint with _$RouteWaypoint {
  const factory RouteWaypoint({
    required double lat,
    required double lng,

    /// Floor level (0 = ground).
    @Default(0) int floor,

    /// Optional label, e.g. "Turn left at Gate C".
    String? instruction,
  }) = _RouteWaypoint;

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) =>
      _$RouteWaypointFromJson(json);
}

@freezed
class IndoorRoute with _$IndoorRoute {
  const factory IndoorRoute({
    required List<RouteWaypoint> waypoints,

    /// Estimated travel time in minutes.
    @JsonKey(name: 'estimated_time_minutes')
    required double estimatedTimeMinutes,

    /// Total distance in metres.
    @JsonKey(name: 'distance_m') required double distanceM,
  }) = _IndoorRoute;

  factory IndoorRoute.fromJson(Map<String, dynamic> json) =>
      _$IndoorRouteFromJson(json);
}
