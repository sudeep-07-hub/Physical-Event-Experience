/// Maps / wayfinding service — abstract interface.
///
/// Pure Dart (no Flutter imports). Computes indoor routes using zone graph.
library;

import '../models/indoor_route.dart';
import '../models/wayfinding_request.dart';

/// Computes indoor wayfinding routes between venue zones.
abstract class MapsService {
  /// Compute an indoor route given origin, destination, and avoidance zones.
  Future<IndoorRoute> computeRoute(WayfindingRequest request);
}
