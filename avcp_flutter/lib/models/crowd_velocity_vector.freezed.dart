// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crowd_velocity_vector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CrowdVelocityVector _$CrowdVelocityVectorFromJson(Map<String, dynamic> json) {
  return _CrowdVelocityVector.fromJson(json);
}

/// @nodoc
mixin _$CrowdVelocityVector {
// ── Spatial identity (zone-level, never device-level) ──────────────
  @JsonKey(name: 'zone_id')
  String get zoneId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sector_hash')
  String get sectorHash => throw _privateConstructorUsedError;
  @JsonKey(name: 'timestamp_ms')
  int get timestampMs => throw _privateConstructorUsedError;
  @JsonKey(name: 'tick_window_s')
  double get tickWindowS =>
      throw _privateConstructorUsedError; // ── Kinematic fields ──────────────────────────────────────────────
  /// People per square metre. Clamped to [0.0, 6.5] (Fruin LoS-F).
  @JsonKey(name: 'density_ppm2')
  double get densityPpm2 => throw _privateConstructorUsedError;

  /// Mean lateral flow m/s, signed (−=west, +=east).
  @JsonKey(name: 'velocity_x')
  double get velocityX => throw _privateConstructorUsedError;

  /// Mean longitudinal flow m/s, signed (−=south, +=north).
  @JsonKey(name: 'velocity_y')
  double get velocityY => throw _privateConstructorUsedError;

  /// 95th-percentile scalar speed m/s.
  @JsonKey(name: 'speed_p95')
  double get speedP95 => throw _privateConstructorUsedError;

  /// Dominant heading [0, 360), 0=North.
  @JsonKey(name: 'heading_deg')
  double get headingDeg =>
      throw _privateConstructorUsedError; // ── Congestion signals ────────────────────────────────────────────
  /// Fraction of population with speed < 0.3 m/s. Range [0, 1].
  @JsonKey(name: 'dwell_ratio')
  double get dwellRatio => throw _privateConstructorUsedError;

  /// Kinetic-energy variance (turbulence proxy).
  @JsonKey(name: 'flow_variance')
  double get flowVariance => throw _privateConstructorUsedError;

  /// 0=free-flow, 1=gridlock. Computed via Greenshields model.
  @JsonKey(name: 'bottleneck_score')
  double get bottleneckScore =>
      throw _privateConstructorUsedError; // ── Predictive annotations (Vertex AI / TFLite at edge) ───────────
  /// Forecast density at T+60 s.
  @JsonKey(name: 'predicted_density_60s')
  double get predictedDensity60s => throw _privateConstructorUsedError;

  /// Forecast density at T+5 min.
  @JsonKey(name: 'predicted_density_300s')
  double get predictedDensity300s => throw _privateConstructorUsedError;

  /// True if deviation > 2σ from a rolling 15-min baseline.
  @JsonKey(name: 'anomaly_flag')
  bool get anomalyFlag => throw _privateConstructorUsedError;

  /// Model confidence [0, 1].
  double get confidence =>
      throw _privateConstructorUsedError; // ── Operational metadata ──────────────────────────────────────────
  /// Anonymized edge-node UUID, regenerated per session startup.
  @JsonKey(name: 'edge_node_id')
  String get edgeNodeId => throw _privateConstructorUsedError;

  /// Semver schema version string.
  @JsonKey(name: 'schema_version')
  String get schemaVersion => throw _privateConstructorUsedError;

  /// Serializes this CrowdVelocityVector to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CrowdVelocityVector
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CrowdVelocityVectorCopyWith<CrowdVelocityVector> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CrowdVelocityVectorCopyWith<$Res> {
  factory $CrowdVelocityVectorCopyWith(
          CrowdVelocityVector value, $Res Function(CrowdVelocityVector) then) =
      _$CrowdVelocityVectorCopyWithImpl<$Res, CrowdVelocityVector>;
  @useResult
  $Res call(
      {@JsonKey(name: 'zone_id') String zoneId,
      @JsonKey(name: 'sector_hash') String sectorHash,
      @JsonKey(name: 'timestamp_ms') int timestampMs,
      @JsonKey(name: 'tick_window_s') double tickWindowS,
      @JsonKey(name: 'density_ppm2') double densityPpm2,
      @JsonKey(name: 'velocity_x') double velocityX,
      @JsonKey(name: 'velocity_y') double velocityY,
      @JsonKey(name: 'speed_p95') double speedP95,
      @JsonKey(name: 'heading_deg') double headingDeg,
      @JsonKey(name: 'dwell_ratio') double dwellRatio,
      @JsonKey(name: 'flow_variance') double flowVariance,
      @JsonKey(name: 'bottleneck_score') double bottleneckScore,
      @JsonKey(name: 'predicted_density_60s') double predictedDensity60s,
      @JsonKey(name: 'predicted_density_300s') double predictedDensity300s,
      @JsonKey(name: 'anomaly_flag') bool anomalyFlag,
      double confidence,
      @JsonKey(name: 'edge_node_id') String edgeNodeId,
      @JsonKey(name: 'schema_version') String schemaVersion});
}

/// @nodoc
class _$CrowdVelocityVectorCopyWithImpl<$Res, $Val extends CrowdVelocityVector>
    implements $CrowdVelocityVectorCopyWith<$Res> {
  _$CrowdVelocityVectorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CrowdVelocityVector
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? zoneId = null,
    Object? sectorHash = null,
    Object? timestampMs = null,
    Object? tickWindowS = null,
    Object? densityPpm2 = null,
    Object? velocityX = null,
    Object? velocityY = null,
    Object? speedP95 = null,
    Object? headingDeg = null,
    Object? dwellRatio = null,
    Object? flowVariance = null,
    Object? bottleneckScore = null,
    Object? predictedDensity60s = null,
    Object? predictedDensity300s = null,
    Object? anomalyFlag = null,
    Object? confidence = null,
    Object? edgeNodeId = null,
    Object? schemaVersion = null,
  }) {
    return _then(_value.copyWith(
      zoneId: null == zoneId
          ? _value.zoneId
          : zoneId // ignore: cast_nullable_to_non_nullable
              as String,
      sectorHash: null == sectorHash
          ? _value.sectorHash
          : sectorHash // ignore: cast_nullable_to_non_nullable
              as String,
      timestampMs: null == timestampMs
          ? _value.timestampMs
          : timestampMs // ignore: cast_nullable_to_non_nullable
              as int,
      tickWindowS: null == tickWindowS
          ? _value.tickWindowS
          : tickWindowS // ignore: cast_nullable_to_non_nullable
              as double,
      densityPpm2: null == densityPpm2
          ? _value.densityPpm2
          : densityPpm2 // ignore: cast_nullable_to_non_nullable
              as double,
      velocityX: null == velocityX
          ? _value.velocityX
          : velocityX // ignore: cast_nullable_to_non_nullable
              as double,
      velocityY: null == velocityY
          ? _value.velocityY
          : velocityY // ignore: cast_nullable_to_non_nullable
              as double,
      speedP95: null == speedP95
          ? _value.speedP95
          : speedP95 // ignore: cast_nullable_to_non_nullable
              as double,
      headingDeg: null == headingDeg
          ? _value.headingDeg
          : headingDeg // ignore: cast_nullable_to_non_nullable
              as double,
      dwellRatio: null == dwellRatio
          ? _value.dwellRatio
          : dwellRatio // ignore: cast_nullable_to_non_nullable
              as double,
      flowVariance: null == flowVariance
          ? _value.flowVariance
          : flowVariance // ignore: cast_nullable_to_non_nullable
              as double,
      bottleneckScore: null == bottleneckScore
          ? _value.bottleneckScore
          : bottleneckScore // ignore: cast_nullable_to_non_nullable
              as double,
      predictedDensity60s: null == predictedDensity60s
          ? _value.predictedDensity60s
          : predictedDensity60s // ignore: cast_nullable_to_non_nullable
              as double,
      predictedDensity300s: null == predictedDensity300s
          ? _value.predictedDensity300s
          : predictedDensity300s // ignore: cast_nullable_to_non_nullable
              as double,
      anomalyFlag: null == anomalyFlag
          ? _value.anomalyFlag
          : anomalyFlag // ignore: cast_nullable_to_non_nullable
              as bool,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      edgeNodeId: null == edgeNodeId
          ? _value.edgeNodeId
          : edgeNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CrowdVelocityVectorImplCopyWith<$Res>
    implements $CrowdVelocityVectorCopyWith<$Res> {
  factory _$$CrowdVelocityVectorImplCopyWith(_$CrowdVelocityVectorImpl value,
          $Res Function(_$CrowdVelocityVectorImpl) then) =
      __$$CrowdVelocityVectorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'zone_id') String zoneId,
      @JsonKey(name: 'sector_hash') String sectorHash,
      @JsonKey(name: 'timestamp_ms') int timestampMs,
      @JsonKey(name: 'tick_window_s') double tickWindowS,
      @JsonKey(name: 'density_ppm2') double densityPpm2,
      @JsonKey(name: 'velocity_x') double velocityX,
      @JsonKey(name: 'velocity_y') double velocityY,
      @JsonKey(name: 'speed_p95') double speedP95,
      @JsonKey(name: 'heading_deg') double headingDeg,
      @JsonKey(name: 'dwell_ratio') double dwellRatio,
      @JsonKey(name: 'flow_variance') double flowVariance,
      @JsonKey(name: 'bottleneck_score') double bottleneckScore,
      @JsonKey(name: 'predicted_density_60s') double predictedDensity60s,
      @JsonKey(name: 'predicted_density_300s') double predictedDensity300s,
      @JsonKey(name: 'anomaly_flag') bool anomalyFlag,
      double confidence,
      @JsonKey(name: 'edge_node_id') String edgeNodeId,
      @JsonKey(name: 'schema_version') String schemaVersion});
}

/// @nodoc
class __$$CrowdVelocityVectorImplCopyWithImpl<$Res>
    extends _$CrowdVelocityVectorCopyWithImpl<$Res, _$CrowdVelocityVectorImpl>
    implements _$$CrowdVelocityVectorImplCopyWith<$Res> {
  __$$CrowdVelocityVectorImplCopyWithImpl(_$CrowdVelocityVectorImpl _value,
      $Res Function(_$CrowdVelocityVectorImpl) _then)
      : super(_value, _then);

  /// Create a copy of CrowdVelocityVector
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? zoneId = null,
    Object? sectorHash = null,
    Object? timestampMs = null,
    Object? tickWindowS = null,
    Object? densityPpm2 = null,
    Object? velocityX = null,
    Object? velocityY = null,
    Object? speedP95 = null,
    Object? headingDeg = null,
    Object? dwellRatio = null,
    Object? flowVariance = null,
    Object? bottleneckScore = null,
    Object? predictedDensity60s = null,
    Object? predictedDensity300s = null,
    Object? anomalyFlag = null,
    Object? confidence = null,
    Object? edgeNodeId = null,
    Object? schemaVersion = null,
  }) {
    return _then(_$CrowdVelocityVectorImpl(
      zoneId: null == zoneId
          ? _value.zoneId
          : zoneId // ignore: cast_nullable_to_non_nullable
              as String,
      sectorHash: null == sectorHash
          ? _value.sectorHash
          : sectorHash // ignore: cast_nullable_to_non_nullable
              as String,
      timestampMs: null == timestampMs
          ? _value.timestampMs
          : timestampMs // ignore: cast_nullable_to_non_nullable
              as int,
      tickWindowS: null == tickWindowS
          ? _value.tickWindowS
          : tickWindowS // ignore: cast_nullable_to_non_nullable
              as double,
      densityPpm2: null == densityPpm2
          ? _value.densityPpm2
          : densityPpm2 // ignore: cast_nullable_to_non_nullable
              as double,
      velocityX: null == velocityX
          ? _value.velocityX
          : velocityX // ignore: cast_nullable_to_non_nullable
              as double,
      velocityY: null == velocityY
          ? _value.velocityY
          : velocityY // ignore: cast_nullable_to_non_nullable
              as double,
      speedP95: null == speedP95
          ? _value.speedP95
          : speedP95 // ignore: cast_nullable_to_non_nullable
              as double,
      headingDeg: null == headingDeg
          ? _value.headingDeg
          : headingDeg // ignore: cast_nullable_to_non_nullable
              as double,
      dwellRatio: null == dwellRatio
          ? _value.dwellRatio
          : dwellRatio // ignore: cast_nullable_to_non_nullable
              as double,
      flowVariance: null == flowVariance
          ? _value.flowVariance
          : flowVariance // ignore: cast_nullable_to_non_nullable
              as double,
      bottleneckScore: null == bottleneckScore
          ? _value.bottleneckScore
          : bottleneckScore // ignore: cast_nullable_to_non_nullable
              as double,
      predictedDensity60s: null == predictedDensity60s
          ? _value.predictedDensity60s
          : predictedDensity60s // ignore: cast_nullable_to_non_nullable
              as double,
      predictedDensity300s: null == predictedDensity300s
          ? _value.predictedDensity300s
          : predictedDensity300s // ignore: cast_nullable_to_non_nullable
              as double,
      anomalyFlag: null == anomalyFlag
          ? _value.anomalyFlag
          : anomalyFlag // ignore: cast_nullable_to_non_nullable
              as bool,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      edgeNodeId: null == edgeNodeId
          ? _value.edgeNodeId
          : edgeNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CrowdVelocityVectorImpl extends _CrowdVelocityVector {
  const _$CrowdVelocityVectorImpl(
      {@JsonKey(name: 'zone_id') required this.zoneId,
      @JsonKey(name: 'sector_hash') required this.sectorHash,
      @JsonKey(name: 'timestamp_ms') required this.timestampMs,
      @JsonKey(name: 'tick_window_s') this.tickWindowS = 2.0,
      @JsonKey(name: 'density_ppm2') this.densityPpm2 = 0.0,
      @JsonKey(name: 'velocity_x') this.velocityX = 0.0,
      @JsonKey(name: 'velocity_y') this.velocityY = 0.0,
      @JsonKey(name: 'speed_p95') this.speedP95 = 0.0,
      @JsonKey(name: 'heading_deg') this.headingDeg = 0.0,
      @JsonKey(name: 'dwell_ratio') this.dwellRatio = 0.0,
      @JsonKey(name: 'flow_variance') this.flowVariance = 0.0,
      @JsonKey(name: 'bottleneck_score') this.bottleneckScore = 0.0,
      @JsonKey(name: 'predicted_density_60s') this.predictedDensity60s = 0.0,
      @JsonKey(name: 'predicted_density_300s') this.predictedDensity300s = 0.0,
      @JsonKey(name: 'anomaly_flag') this.anomalyFlag = false,
      this.confidence = 0.0,
      @JsonKey(name: 'edge_node_id') this.edgeNodeId = '',
      @JsonKey(name: 'schema_version') this.schemaVersion = '2.1.0'})
      : super._();

  factory _$CrowdVelocityVectorImpl.fromJson(Map<String, dynamic> json) =>
      _$$CrowdVelocityVectorImplFromJson(json);

// ── Spatial identity (zone-level, never device-level) ──────────────
  @override
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @override
  @JsonKey(name: 'sector_hash')
  final String sectorHash;
  @override
  @JsonKey(name: 'timestamp_ms')
  final int timestampMs;
  @override
  @JsonKey(name: 'tick_window_s')
  final double tickWindowS;
// ── Kinematic fields ──────────────────────────────────────────────
  /// People per square metre. Clamped to [0.0, 6.5] (Fruin LoS-F).
  @override
  @JsonKey(name: 'density_ppm2')
  final double densityPpm2;

  /// Mean lateral flow m/s, signed (−=west, +=east).
  @override
  @JsonKey(name: 'velocity_x')
  final double velocityX;

  /// Mean longitudinal flow m/s, signed (−=south, +=north).
  @override
  @JsonKey(name: 'velocity_y')
  final double velocityY;

  /// 95th-percentile scalar speed m/s.
  @override
  @JsonKey(name: 'speed_p95')
  final double speedP95;

  /// Dominant heading [0, 360), 0=North.
  @override
  @JsonKey(name: 'heading_deg')
  final double headingDeg;
// ── Congestion signals ────────────────────────────────────────────
  /// Fraction of population with speed < 0.3 m/s. Range [0, 1].
  @override
  @JsonKey(name: 'dwell_ratio')
  final double dwellRatio;

  /// Kinetic-energy variance (turbulence proxy).
  @override
  @JsonKey(name: 'flow_variance')
  final double flowVariance;

  /// 0=free-flow, 1=gridlock. Computed via Greenshields model.
  @override
  @JsonKey(name: 'bottleneck_score')
  final double bottleneckScore;
// ── Predictive annotations (Vertex AI / TFLite at edge) ───────────
  /// Forecast density at T+60 s.
  @override
  @JsonKey(name: 'predicted_density_60s')
  final double predictedDensity60s;

  /// Forecast density at T+5 min.
  @override
  @JsonKey(name: 'predicted_density_300s')
  final double predictedDensity300s;

  /// True if deviation > 2σ from a rolling 15-min baseline.
  @override
  @JsonKey(name: 'anomaly_flag')
  final bool anomalyFlag;

  /// Model confidence [0, 1].
  @override
  @JsonKey()
  final double confidence;
// ── Operational metadata ──────────────────────────────────────────
  /// Anonymized edge-node UUID, regenerated per session startup.
  @override
  @JsonKey(name: 'edge_node_id')
  final String edgeNodeId;

  /// Semver schema version string.
  @override
  @JsonKey(name: 'schema_version')
  final String schemaVersion;

  @override
  String toString() {
    return 'CrowdVelocityVector(zoneId: $zoneId, sectorHash: $sectorHash, timestampMs: $timestampMs, tickWindowS: $tickWindowS, densityPpm2: $densityPpm2, velocityX: $velocityX, velocityY: $velocityY, speedP95: $speedP95, headingDeg: $headingDeg, dwellRatio: $dwellRatio, flowVariance: $flowVariance, bottleneckScore: $bottleneckScore, predictedDensity60s: $predictedDensity60s, predictedDensity300s: $predictedDensity300s, anomalyFlag: $anomalyFlag, confidence: $confidence, edgeNodeId: $edgeNodeId, schemaVersion: $schemaVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CrowdVelocityVectorImpl &&
            (identical(other.zoneId, zoneId) || other.zoneId == zoneId) &&
            (identical(other.sectorHash, sectorHash) ||
                other.sectorHash == sectorHash) &&
            (identical(other.timestampMs, timestampMs) ||
                other.timestampMs == timestampMs) &&
            (identical(other.tickWindowS, tickWindowS) ||
                other.tickWindowS == tickWindowS) &&
            (identical(other.densityPpm2, densityPpm2) ||
                other.densityPpm2 == densityPpm2) &&
            (identical(other.velocityX, velocityX) ||
                other.velocityX == velocityX) &&
            (identical(other.velocityY, velocityY) ||
                other.velocityY == velocityY) &&
            (identical(other.speedP95, speedP95) ||
                other.speedP95 == speedP95) &&
            (identical(other.headingDeg, headingDeg) ||
                other.headingDeg == headingDeg) &&
            (identical(other.dwellRatio, dwellRatio) ||
                other.dwellRatio == dwellRatio) &&
            (identical(other.flowVariance, flowVariance) ||
                other.flowVariance == flowVariance) &&
            (identical(other.bottleneckScore, bottleneckScore) ||
                other.bottleneckScore == bottleneckScore) &&
            (identical(other.predictedDensity60s, predictedDensity60s) ||
                other.predictedDensity60s == predictedDensity60s) &&
            (identical(other.predictedDensity300s, predictedDensity300s) ||
                other.predictedDensity300s == predictedDensity300s) &&
            (identical(other.anomalyFlag, anomalyFlag) ||
                other.anomalyFlag == anomalyFlag) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.edgeNodeId, edgeNodeId) ||
                other.edgeNodeId == edgeNodeId) &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      zoneId,
      sectorHash,
      timestampMs,
      tickWindowS,
      densityPpm2,
      velocityX,
      velocityY,
      speedP95,
      headingDeg,
      dwellRatio,
      flowVariance,
      bottleneckScore,
      predictedDensity60s,
      predictedDensity300s,
      anomalyFlag,
      confidence,
      edgeNodeId,
      schemaVersion);

  /// Create a copy of CrowdVelocityVector
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CrowdVelocityVectorImplCopyWith<_$CrowdVelocityVectorImpl> get copyWith =>
      __$$CrowdVelocityVectorImplCopyWithImpl<_$CrowdVelocityVectorImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CrowdVelocityVectorImplToJson(
      this,
    );
  }
}

abstract class _CrowdVelocityVector extends CrowdVelocityVector {
  const factory _CrowdVelocityVector(
      {@JsonKey(name: 'zone_id') required final String zoneId,
      @JsonKey(name: 'sector_hash') required final String sectorHash,
      @JsonKey(name: 'timestamp_ms') required final int timestampMs,
      @JsonKey(name: 'tick_window_s') final double tickWindowS,
      @JsonKey(name: 'density_ppm2') final double densityPpm2,
      @JsonKey(name: 'velocity_x') final double velocityX,
      @JsonKey(name: 'velocity_y') final double velocityY,
      @JsonKey(name: 'speed_p95') final double speedP95,
      @JsonKey(name: 'heading_deg') final double headingDeg,
      @JsonKey(name: 'dwell_ratio') final double dwellRatio,
      @JsonKey(name: 'flow_variance') final double flowVariance,
      @JsonKey(name: 'bottleneck_score') final double bottleneckScore,
      @JsonKey(name: 'predicted_density_60s') final double predictedDensity60s,
      @JsonKey(name: 'predicted_density_300s')
      final double predictedDensity300s,
      @JsonKey(name: 'anomaly_flag') final bool anomalyFlag,
      final double confidence,
      @JsonKey(name: 'edge_node_id') final String edgeNodeId,
      @JsonKey(name: 'schema_version')
      final String schemaVersion}) = _$CrowdVelocityVectorImpl;
  const _CrowdVelocityVector._() : super._();

  factory _CrowdVelocityVector.fromJson(Map<String, dynamic> json) =
      _$CrowdVelocityVectorImpl.fromJson;

// ── Spatial identity (zone-level, never device-level) ──────────────
  @override
  @JsonKey(name: 'zone_id')
  String get zoneId;
  @override
  @JsonKey(name: 'sector_hash')
  String get sectorHash;
  @override
  @JsonKey(name: 'timestamp_ms')
  int get timestampMs;
  @override
  @JsonKey(name: 'tick_window_s')
  double
      get tickWindowS; // ── Kinematic fields ──────────────────────────────────────────────
  /// People per square metre. Clamped to [0.0, 6.5] (Fruin LoS-F).
  @override
  @JsonKey(name: 'density_ppm2')
  double get densityPpm2;

  /// Mean lateral flow m/s, signed (−=west, +=east).
  @override
  @JsonKey(name: 'velocity_x')
  double get velocityX;

  /// Mean longitudinal flow m/s, signed (−=south, +=north).
  @override
  @JsonKey(name: 'velocity_y')
  double get velocityY;

  /// 95th-percentile scalar speed m/s.
  @override
  @JsonKey(name: 'speed_p95')
  double get speedP95;

  /// Dominant heading [0, 360), 0=North.
  @override
  @JsonKey(name: 'heading_deg')
  double
      get headingDeg; // ── Congestion signals ────────────────────────────────────────────
  /// Fraction of population with speed < 0.3 m/s. Range [0, 1].
  @override
  @JsonKey(name: 'dwell_ratio')
  double get dwellRatio;

  /// Kinetic-energy variance (turbulence proxy).
  @override
  @JsonKey(name: 'flow_variance')
  double get flowVariance;

  /// 0=free-flow, 1=gridlock. Computed via Greenshields model.
  @override
  @JsonKey(name: 'bottleneck_score')
  double
      get bottleneckScore; // ── Predictive annotations (Vertex AI / TFLite at edge) ───────────
  /// Forecast density at T+60 s.
  @override
  @JsonKey(name: 'predicted_density_60s')
  double get predictedDensity60s;

  /// Forecast density at T+5 min.
  @override
  @JsonKey(name: 'predicted_density_300s')
  double get predictedDensity300s;

  /// True if deviation > 2σ from a rolling 15-min baseline.
  @override
  @JsonKey(name: 'anomaly_flag')
  bool get anomalyFlag;

  /// Model confidence [0, 1].
  @override
  double
      get confidence; // ── Operational metadata ──────────────────────────────────────────
  /// Anonymized edge-node UUID, regenerated per session startup.
  @override
  @JsonKey(name: 'edge_node_id')
  String get edgeNodeId;

  /// Semver schema version string.
  @override
  @JsonKey(name: 'schema_version')
  String get schemaVersion;

  /// Create a copy of CrowdVelocityVector
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CrowdVelocityVectorImplCopyWith<_$CrowdVelocityVectorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
