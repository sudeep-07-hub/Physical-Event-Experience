/// Concrete Firebase RTDB implementation of [FirebaseService].
///
/// Reads crowd vectors from:
///   /venues/{venueId}/zones/{zoneId}/current_vector
///
/// Security rules enforce:
/// - Zone-read only for fan role (auth != null)
/// - system_health read for operator role only
library;

import 'package:firebase_database/firebase_database.dart';

import '../models/crowd_velocity_vector.dart';
import 'firebase_service.dart';

class FirebaseCrowdService implements FirebaseService {
  FirebaseCrowdService({
    required this.venueId,
    DatabaseReference? rootRef,
  }) : _root = rootRef ?? FirebaseDatabase.instance.ref();

  final String venueId;
  final DatabaseReference _root;

  /// Base path for this venue's zone data.
  DatabaseReference get _venueRef => _root.child('venues/$venueId');

  @override
  Stream<CrowdVelocityVector> watchZone(String zoneId) {
    return _venueRef
        .child('zones/$zoneId/current_vector')
        .onValue
        .where((event) => event.snapshot.value != null)
        .map((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      return CrowdVelocityVector.fromJson(data);
    });
  }

  @override
  Stream<List<CrowdVelocityVector>> watchAllZones() {
    return _venueRef.child('zones').onValue.map((event) {
      if (event.snapshot.value == null) return <CrowdVelocityVector>[];

      final zonesMap = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );

      return zonesMap.entries
          .where((e) => e.value is Map && (e.value as Map).containsKey('current_vector'))
          .map((e) {
        final vectorData = Map<String, dynamic>.from(
          (e.value as Map)['current_vector'] as Map,
        );
        return CrowdVelocityVector.fromJson(vectorData);
      }).toList();
    });
  }
}
