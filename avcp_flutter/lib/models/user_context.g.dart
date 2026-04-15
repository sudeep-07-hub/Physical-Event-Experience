// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserContextImpl _$$UserContextImplFromJson(Map<String, dynamic> json) =>
    _$UserContextImpl(
      currentZoneId: json['current_zone_id'] as String,
      uwbProximityToGateM:
          (json['uwb_proximity_to_gate_m'] as num?)?.toDouble(),
      assignedGateId: json['assigned_gate_id'] as String?,
      dwellTimeS: (json['dwell_time_s'] as num?)?.toDouble() ?? 0.0,
      zoneDwellRatio: (json['zone_dwell_ratio'] as num?)?.toDouble() ?? 0.0,
      zoneBottleneckScore:
          (json['zone_bottleneck_score'] as num?)?.toDouble() ?? 0.0,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.attendee,
    );

Map<String, dynamic> _$$UserContextImplToJson(_$UserContextImpl instance) =>
    <String, dynamic>{
      'current_zone_id': instance.currentZoneId,
      'uwb_proximity_to_gate_m': instance.uwbProximityToGateM,
      'assigned_gate_id': instance.assignedGateId,
      'dwell_time_s': instance.dwellTimeS,
      'zone_dwell_ratio': instance.zoneDwellRatio,
      'zone_bottleneck_score': instance.zoneBottleneckScore,
      'role': _$UserRoleEnumMap[instance.role]!,
    };

const _$UserRoleEnumMap = {
  UserRole.attendee: 'attendee',
  UserRole.staff: 'staff',
  UserRole.operator: 'operator',
};
