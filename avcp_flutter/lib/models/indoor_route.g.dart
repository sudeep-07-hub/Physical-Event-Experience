// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indoor_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteWaypointImpl _$$RouteWaypointImplFromJson(Map<String, dynamic> json) =>
    _$RouteWaypointImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      floor: (json['floor'] as num?)?.toInt() ?? 0,
      instruction: json['instruction'] as String?,
    );

Map<String, dynamic> _$$RouteWaypointImplToJson(_$RouteWaypointImpl instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'floor': instance.floor,
      'instruction': instance.instruction,
    };

_$IndoorRouteImpl _$$IndoorRouteImplFromJson(Map<String, dynamic> json) =>
    _$IndoorRouteImpl(
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => RouteWaypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedTimeMinutes: (json['estimated_time_minutes'] as num).toDouble(),
      distanceM: (json['distance_m'] as num).toDouble(),
    );

Map<String, dynamic> _$$IndoorRouteImplToJson(_$IndoorRouteImpl instance) =>
    <String, dynamic>{
      'waypoints': instance.waypoints,
      'estimated_time_minutes': instance.estimatedTimeMinutes,
      'distance_m': instance.distanceM,
    };
