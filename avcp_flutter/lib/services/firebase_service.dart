/// Firebase RTDB service — abstract interface.
///
/// Pure Dart (no Flutter imports). Produces [CrowdVelocityVector] streams
/// from Firebase Realtime Database zone paths.
library;

import '../models/crowd_velocity_vector.dart';

/// Watches a Firebase RTDB zone node and emits [CrowdVelocityVector] updates.
abstract class FirebaseService {
  /// Stream of crowd vectors for a specific zone.
  ///
  /// Path: `/zones/{zoneId}/latest`
  /// Updates at the edge tick rate (default 2s windows).
  Stream<CrowdVelocityVector> watchZone(String zoneId);

  /// Stream of all active zone vectors (for operator dashboard).
  Stream<List<CrowdVelocityVector>> watchAllZones();
}
