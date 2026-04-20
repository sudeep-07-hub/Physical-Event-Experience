import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// ══════════════════════════════════════════════════════════════════════
// Friend Finder Service (Zero-PII Proximal Metrics)
// ══════════════════════════════════════════════════════════════════════

/// Generates encrypted handshake tokens so friends can find each other via Proximity
/// instead of pushing absolute GPS bounds to the Firebase endpoints.
class FriendFinderService {
  
  /// Generates the QR handshake token combining the secure identity plus epoch constraint.
  String generateHandshakeToken(String deviceSecretId) {
    // Valid for 1 hour physically.
    final timeBlock = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
    
    var bytes = utf8.encode("$deviceSecretId-$timeBlock");
    var digest = sha256.convert(bytes);
    
    // Using hex token for QR transmission.
    return digest.toString();
  }

  /// Calculates "Relative Spatial Distance" preventing exact pinpointing.
  RelativeProximity calculateRelativeDistance(LatLng myCurrentLocation, LatLng friendLastLocation) {
    // We use standard Haversine distance via LatLong2 library.
    final Distance distance = const Distance();
    final double meters = distance.as(LengthUnit.Meter, myCurrentLocation, friendLastLocation);
    
    // Abstract the exact physical meters into "Hot/Cold" zones for Zero-PII adherence.
    if (meters < 20) return RelativeProximity.immediate;
    if (meters < 75) return RelativeProximity.nearby;
    if (meters < 200) return RelativeProximity.section;
    return RelativeProximity.distant;
  }
}

enum RelativeProximity {
  immediate, // < 20m  (Red Hot)
  nearby,    // < 75m  (Warm)
  section,   // < 200m (Cold)
  distant    // > 200m (Unknown)
}

final friendServiceProvider = Provider<FriendFinderService>((ref) {
  return FriendFinderService();
});
