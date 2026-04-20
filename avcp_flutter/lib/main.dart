/// AVCP Glanceable UI — entry point.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:avcp_flutter/firebase_options.dart';
import 'package:avcp_flutter/theme.dart';
import 'package:avcp_flutter/wayfinding/wayfinding_screen.dart';
import 'package:avcp_flutter/providers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Android Map Renderer for advanced polyline patterns
  if (defaultTargetPlatform == TargetPlatform.android) {
    await AndroidGoogleMapsFlutter.init(
      renderer: AndroidMapRenderer.latest,
    );
  }
  
  final container = ProviderContainer();
  // Pre-warm marker bitmaps to ensure first-frame visibility
  await container.read(gateBitmapsProvider.future);
  
  runApp(UncontrolledProviderScope(container: container, child: const AvenuControlApp()));
}

class AvenuControlApp extends ConsumerWidget {
  const AvenuControlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isHighContrast = ref.watch(themeToggleProvider);
    
    return MaterialApp(
      title: 'AVCP — Venue Intelligence',
      debugShowCheckedModeBanner: false,
      theme: StadiumDarkTheme.build(isHighContrast: isHighContrast),
      home: const Scaffold(
        body: WayfindingScreen(zoneId: 'gate_c_concourse_l2', venueCenter: LatLng(47.5952, -122.3316)),
      ),
    );
  }
}
