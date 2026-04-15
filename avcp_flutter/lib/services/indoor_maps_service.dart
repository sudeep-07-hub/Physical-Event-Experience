/// Concrete indoor maps/wayfinding service.
///
/// Computes routes factoring live congestion avoidance:
/// avoids zones with bottleneck_score > 0.75.
///
/// In production, this integrates with Google Maps Indoor API
/// or a custom venue graph. This implementation uses a simplified
/// zone-based graph for demonstration.
library;

import '../models/indoor_route.dart';
import '../models/wayfinding_request.dart';
import 'maps_service.dart';

class IndoorMapsService implements MapsService {
  IndoorMapsService({
    this.venueGraph = const {},
  });

  /// Adjacency graph: zone_id → list of connected zone_ids.
  /// In production, loaded from venue configuration.
  final Map<String, List<String>> venueGraph;

  @override
  Future<IndoorRoute> computeRoute(WayfindingRequest request) async {
    // Simplified BFS route finding avoiding congested zones
    final avoidSet = request.avoidZones.toSet();
    final path = _bfs(
      request.fromZoneId,
      request.toZoneId,
      avoidSet,
    );

    if (path == null) {
      // No route found — return direct route as fallback
      return IndoorRoute(
        waypoints: [
          RouteWaypoint(lat: 0, lng: 0, instruction: 'Start: ${request.fromZoneId}'),
          RouteWaypoint(lat: 0, lng: 0, instruction: 'End: ${request.toZoneId}'),
        ],
        estimatedTimeMinutes: 5.0,
        distanceM: 200.0,
      );
    }

    // Convert path to waypoints
    final waypoints = path.map((zoneId) {
      return RouteWaypoint(
        lat: 0, // In production: from venue coordinate database
        lng: 0,
        instruction: 'Continue through $zoneId',
      );
    }).toList();

    return IndoorRoute(
      waypoints: waypoints,
      // Estimate: 30 seconds per zone traversal
      estimatedTimeMinutes: (path.length * 0.5),
      // Estimate: 50m per zone
      distanceM: path.length * 50.0,
    );
  }

  /// Simple BFS pathfinding avoiding congested zones.
  List<String>? _bfs(
    String from,
    String to,
    Set<String> avoid,
  ) {
    if (from == to) return [from];
    if (!venueGraph.containsKey(from)) return null;

    final visited = <String>{from};
    final queue = <List<String>>[[from]];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      for (final neighbor in venueGraph[current] ?? <String>[]) {
        if (visited.contains(neighbor) || avoid.contains(neighbor)) {
          continue;
        }

        final newPath = [...path, neighbor];
        if (neighbor == to) return newPath;

        visited.add(neighbor);
        queue.add(newPath);
      }
    }

    return null; // No path found
  }
}
