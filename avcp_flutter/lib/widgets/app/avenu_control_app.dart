/// Root application widget.
///
/// Wraps the entire app in [ProviderScope] and applies [avenuTheme].
/// No business logic lives here — purely configuration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/avenu_theme.dart';
import '../scaffold/adaptive_scaffold.dart';

class AvenuControlApp extends StatelessWidget {
  const AvenuControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // In production, override firebaseServiceProvider and mapsServiceProvider
      // with concrete implementations here.
      child: MaterialApp(
        title: 'AVCP — Venue Intelligence',
        debugShowCheckedModeBanner: false,
        theme: avenuTheme(),
        highContrastTheme: avenuTheme(highContrast: true),
        home: const AdaptiveScaffold(),
      ),
    );
  }
}
