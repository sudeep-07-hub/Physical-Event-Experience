// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crowd_velocity_vector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CrowdVelocityVectorImpl _$$CrowdVelocityVectorImplFromJson(
        Map<String, dynamic> json) =>
    _$CrowdVelocityVectorImpl(
      zoneId: json['zone_id'] as String,
      sectorHash: json['sector_hash'] as String,
      timestampMs: (json['timestamp_ms'] as num).toInt(),
      tickWindowS: (json['tick_window_s'] as num?)?.toDouble() ?? 2.0,
      densityPpm2: (json['density_ppm2'] as num?)?.toDouble() ?? 0.0,
      velocityX: (json['velocity_x'] as num?)?.toDouble() ?? 0.0,
      velocityY: (json['velocity_y'] as num?)?.toDouble() ?? 0.0,
      speedP95: (json['speed_p95'] as num?)?.toDouble() ?? 0.0,
      headingDeg: (json['heading_deg'] as num?)?.toDouble() ?? 0.0,
      dwellRatio: (json['dwell_ratio'] as num?)?.toDouble() ?? 0.0,
      flowVariance: (json['flow_variance'] as num?)?.toDouble() ?? 0.0,
      bottleneckScore: (json['bottleneck_score'] as num?)?.toDouble() ?? 0.0,
      predictedDensity60s:
          (json['predicted_density_60s'] as num?)?.toDouble() ?? 0.0,
      predictedDensity300s:
          (json['predicted_density_300s'] as num?)?.toDouble() ?? 0.0,
      anomalyFlag: json['anomaly_flag'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      edgeNodeId: json['edge_node_id'] as String? ?? '',
      schemaVersion: json['schema_version'] as String? ?? '2.1.0',
    );

Map<String, dynamic> _$$CrowdVelocityVectorImplToJson(
        _$CrowdVelocityVectorImpl instance) =>
    <String, dynamic>{
      'zone_id': instance.zoneId,
      'sector_hash': instance.sectorHash,
      'timestamp_ms': instance.timestampMs,
      'tick_window_s': instance.tickWindowS,
      'density_ppm2': instance.densityPpm2,
      'velocity_x': instance.velocityX,
      'velocity_y': instance.velocityY,
      'speed_p95': instance.speedP95,
      'heading_deg': instance.headingDeg,
      'dwell_ratio': instance.dwellRatio,
      'flow_variance': instance.flowVariance,
      'bottleneck_score': instance.bottleneckScore,
      'predicted_density_60s': instance.predictedDensity60s,
      'predicted_density_300s': instance.predictedDensity300s,
      'anomaly_flag': instance.anomalyFlag,
      'confidence': instance.confidence,
      'edge_node_id': instance.edgeNodeId,
      'schema_version': instance.schemaVersion,
    };
