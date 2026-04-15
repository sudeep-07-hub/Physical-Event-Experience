/// Service dependency providers.
///
/// All services are registered as Riverpod providers so widgets never
/// instantiate services directly. Swap implementations for testing.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/crowd_analysis_service.dart';
import '../services/crowd_analysis_service_impl.dart';
import '../services/firebase_service.dart';
import '../services/intent_detection_service.dart';
import '../services/intent_detection_service_impl.dart';
import '../services/maps_service.dart';

/// Firebase RTDB service — override in tests with a mock.
final firebaseServiceProvider = Provider<FirebaseService>(
  (_) => throw UnimplementedError(
    'firebaseServiceProvider must be overridden with a concrete '
    'implementation at app startup (ProviderScope.overrides).',
  ),
);

/// Indoor wayfinding / maps service — override in tests.
final mapsServiceProvider = Provider<MapsService>(
  (_) => throw UnimplementedError(
    'mapsServiceProvider must be overridden with a concrete '
    'implementation at app startup (ProviderScope.overrides).',
  ),
);

/// Crowd analysis service — concrete by default.
final crowdAnalysisServiceProvider = Provider<CrowdAnalysisService>(
  (_) => CrowdAnalysisServiceImpl(),
);

/// Intent detection service — concrete by default.
final intentDetectionServiceProvider = Provider<IntentDetectionService>(
  (_) => IntentDetectionServiceImpl(),
);
