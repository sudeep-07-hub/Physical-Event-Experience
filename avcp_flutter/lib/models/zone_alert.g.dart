// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ZoneAlertImpl _$$ZoneAlertImplFromJson(Map<String, dynamic> json) =>
    _$ZoneAlertImpl(
      zoneId: json['zone_id'] as String,
      alertType: $enumDecode(_$AlertTypeEnumMap, json['alert_type']),
      severity: $enumDecode(_$CongestionLevelEnumMap, json['severity']),
      message: json['message'] as String,
      timestampMs: (json['timestamp_ms'] as num).toInt(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );

Map<String, dynamic> _$$ZoneAlertImplToJson(_$ZoneAlertImpl instance) =>
    <String, dynamic>{
      'zone_id': instance.zoneId,
      'alert_type': _$AlertTypeEnumMap[instance.alertType]!,
      'severity': _$CongestionLevelEnumMap[instance.severity]!,
      'message': instance.message,
      'timestamp_ms': instance.timestampMs,
      'acknowledged': instance.acknowledged,
    };

const _$AlertTypeEnumMap = {
  AlertType.congestionWarning: 'congestionWarning',
  AlertType.bottleneckDetected: 'bottleneckDetected',
  AlertType.anomalyDetected: 'anomalyDetected',
  AlertType.predictiveSurge: 'predictiveSurge',
};

const _$CongestionLevelEnumMap = {
  CongestionLevel.free: 'free',
  CongestionLevel.moderate: 'moderate',
  CongestionLevel.high: 'high',
  CongestionLevel.critical: 'critical',
};
