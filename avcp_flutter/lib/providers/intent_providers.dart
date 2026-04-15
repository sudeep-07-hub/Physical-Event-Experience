/// Intent and wayfinding providers.
///
/// Derives the active user intent from [UserContext] and provides
/// wayfinding route computation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/indoor_route.dart';
import '../models/user_context.dart';
import '../models/user_intent.dart';
import '../models/wayfinding_request.dart';
import 'service_providers.dart';

/// Current user context — updated by device-local signals (UWB, zone, role).
///
/// In production, this is fed by a platform channel from the UWB SDK.
/// Override in tests to simulate different scenarios.
final userContextProvider = StateProvider<UserContext>(
  (_) => const UserContext(currentZoneId: 'unknown'),
);

/// Derived: active user intent from current context.
final activeIntentProvider = Provider<UserIntent>(
  (ref) {
    final ctx = ref.watch(userContextProvider);
    return ref
        .watch(intentDetectionServiceProvider)
        .detectFromContext(ctx);
  },
);

/// Wayfinding route computation — on-demand.
final wayfindingProvider =
    FutureProvider.family<IndoorRoute, WayfindingRequest>(
  (ref, request) =>
      ref.watch(mapsServiceProvider).computeRoute(request),
);
