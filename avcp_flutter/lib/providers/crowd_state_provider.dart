/// Crowd state providers — real-time zone data from Firebase RTDB.
///
/// All state flows through Riverpod. Zero setState() in the widget tree.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/congestion_level.dart';
import '../models/crowd_velocity_vector.dart';
import '../models/zone_alert.dart';
import 'service_providers.dart';

/// Stream of [CrowdVelocityVector] for a specific zone.
///
/// Usage: `ref.watch(crowdStreamProvider('gate_c_concourse_level2'))`
final crowdStreamProvider =
    StreamProvider.family<CrowdVelocityVector, String>(
  (ref, zoneId) =>
      ref.watch(firebaseServiceProvider).watchZone(zoneId),
);

/// Stream of all active zone vectors (for operator dashboard).
final allZonesStreamProvider =
    StreamProvider<List<CrowdVelocityVector>>(
  (ref) => ref.watch(firebaseServiceProvider).watchAllZones(),
);

/// Derived: congestion level for a specific zone.
final congestionLevelProvider =
    Provider.family<AsyncValue<CongestionLevel>, String>(
  (ref, zoneId) {
    final crowdAsync = ref.watch(crowdStreamProvider(zoneId));
    return crowdAsync.whenData(
      (vector) =>
          ref.watch(crowdAnalysisServiceProvider).classify(vector),
    );
  },
);

/// Derived: estimated wait time in minutes for a zone.
final waitTimeProvider = Provider.family<AsyncValue<int>, String>(
  (ref, zoneId) {
    final crowdAsync = ref.watch(crowdStreamProvider(zoneId));
    return crowdAsync.whenData(
      (vector) => ref
          .watch(crowdAnalysisServiceProvider)
          .estimateWaitMinutes(vector),
    );
  },
);

/// Derived: alerts from all active zones.
final alertsProvider = Provider<AsyncValue<List<ZoneAlert>>>(
  (ref) {
    final allZonesAsync = ref.watch(allZonesStreamProvider);
    return allZonesAsync.whenData(
      (vectors) =>
          ref.watch(crowdAnalysisServiceProvider).getAlerts(vectors),
    );
  },
);
