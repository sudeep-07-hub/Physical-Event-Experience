/// Theme configuration for AVCP Glanceable UI.
///
/// Dark theme optimized for stadium environments with high-contrast
/// accessibility override support.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../accessibility/wcag_tokens.dart';

/// Builds the standard AVCP dark theme.
ThemeData avenuTheme({bool highContrast = false}) {
  final colorScheme = highContrast
      ? ColorScheme.highContrastDark()
      : const ColorScheme.dark(
          surface: AvenuColors.surfaceDark,
          primary: AvenuColors.accentBlue,
          secondary: AvenuColors.accentGreen,
          error: AvenuColors.crowdCritical,
          onSurface: AvenuColors.textPrimary,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
        );

  final textTheme = highContrast
      ? GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme)
      : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  return ThemeData.from(colorScheme: colorScheme).copyWith(
    textTheme: textTheme.apply(
      bodyColor: AvenuColors.textPrimary,
      displayColor: AvenuColors.textPrimary,
    ),
    cardTheme: const CardThemeData(
      color: AvenuColors.surfaceCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AvenuColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    extensions: [
      if (highContrast) AvenuHighContrastTheme.highContrast(),
    ],
  );
}
