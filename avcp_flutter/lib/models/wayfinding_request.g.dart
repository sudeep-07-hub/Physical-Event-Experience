// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wayfinding_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WayfindingRequestImpl _$$WayfindingRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$WayfindingRequestImpl(
      fromZoneId: json['from_zone_id'] as String,
      toZoneId: json['to_zone_id'] as String,
      avoidZones: (json['avoid_zones'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WayfindingRequestImplToJson(
        _$WayfindingRequestImpl instance) =>
    <String, dynamic>{
      'from_zone_id': instance.fromZoneId,
      'to_zone_id': instance.toZoneId,
      'avoid_zones': instance.avoidZones,
    };
