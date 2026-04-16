/// AVCP Glanceable UI — entry point.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:avcp_flutter/firebase_options.dart';
import 'package:avcp_flutter/theme.dart';
import 'package:avcp_flutter/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: AvenuControlApp()));
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
        body: GlanceableDashboard(zoneId: 'gate_c_concourse_l2'),
      ),
    );
  }
}
