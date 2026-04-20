/// AVCP Stadium-Dark Theme — Triple-Threat UI Design System v1.0.0
///
/// Provides:
/// - [StadiumColorTokens] — immutable color palette (standard + high-contrast)
/// - [StadiumThemeExtension] — ThemeExtension with lerp/copyWith
/// - [StadiumDarkTheme] — ThemeData builder
/// - [AvenuTypography] — context-aware text styles (never hardcoded colors)
/// - [themeToggleProvider] — Riverpod StateProvider persisted to SharedPreferences
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui';
// ══════════════════════════════════════════════════════════════════════
// Glassmorphism Blur System
// ══════════════════════════════════════════════════════════════════════

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            border: Border.all(
              color: Colors.white.withOpacity(opacity * 2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Color Token System
// ══════════════════════════════════════════════════════════════════════

/// Immutable, const-constructible color palette for the Stadium-Dark system.
@immutable
class StadiumColorTokens {
  const StadiumColorTokens._({
    required this.primaryGold,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.success,
    required this.alertRed,
    required this.uwbBlue,
    required this.kpiOverlay,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color primaryGold;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color success;
  final Color alertRed;
  final Color uwbBlue;
  final Color kpiOverlay;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;

  /// Standard palette
  static const StadiumColorTokens standard = StadiumColorTokens._(
    primaryGold: Color(0xFFFFD700),
    background: Color(0xFF0F1117),
    surface: Color(0xFF13161F),
    surfaceAlt: Color(0xFF1A1D26),
    success: Color(0xFF00E676),
    alertRed: Color(0xFFFF5252),
    uwbBlue: Color(0xFF4FC3F7),
    kpiOverlay: Color(0xE00F1117), // rgba(15,17,23,0.88)
    onPrimary: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
  );

  /// High-contrast palette — WCAG AAA (≥ 7.0:1) on pure black.
  static const StadiumColorTokens highContrast = StadiumColorTokens._(
    primaryGold: Color(0xFFFFE44D),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceAlt: Color(0xFF111111),
    success: Color(0xFF69FF47),
    alertRed: Color(0xFFFF6E6E),
    uwbBlue: Color(0xFF4FC3F7),
    kpiOverlay: Color(0xE0000000),
    onPrimary: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
  );

  /// Linearly interpolate between two token sets.
  static StadiumColorTokens lerp(
    StadiumColorTokens a,
    StadiumColorTokens b,
    double t,
  ) {
    return StadiumColorTokens._(
      primaryGold: Color.lerp(a.primaryGold, b.primaryGold, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceAlt: Color.lerp(a.surfaceAlt, b.surfaceAlt, t)!,
      success: Color.lerp(a.success, b.success, t)!,
      alertRed: Color.lerp(a.alertRed, b.alertRed, t)!,
      uwbBlue: Color.lerp(a.uwbBlue, b.uwbBlue, t)!,
      kpiOverlay: Color.lerp(a.kpiOverlay, b.kpiOverlay, t)!,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Theme Extension
// ══════════════════════════════════════════════════════════════════════

/// ThemeExtension attaching [StadiumColorTokens] to any [ThemeData].
///
/// Access via `Theme.of(context).extension<StadiumThemeExtension>()!.tokens`.
@immutable
class StadiumThemeExtension extends ThemeExtension<StadiumThemeExtension> {
  const StadiumThemeExtension({
    required this.tokens,
    required this.isHighContrast,
  });

  final StadiumColorTokens tokens;
  final bool isHighContrast;

  @override
  StadiumThemeExtension copyWith({
    StadiumColorTokens? tokens,
    bool? isHighContrast,
  }) {
    return StadiumThemeExtension(
      tokens: tokens ?? this.tokens,
      isHighContrast: isHighContrast ?? this.isHighContrast,
    );
  }

  @override
  StadiumThemeExtension lerp(
    covariant ThemeExtension<StadiumThemeExtension>? other,
    double t,
  ) {
    if (other is! StadiumThemeExtension) return this;
    return StadiumThemeExtension(
      tokens: StadiumColorTokens.lerp(tokens, other.tokens, t),
      isHighContrast: t < 0.5 ? isHighContrast : other.isHighContrast,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Theme Builder
// ══════════════════════════════════════════════════════════════════════

/// Builds the complete [ThemeData] for the Stadium-Dark design system.
abstract final class StadiumDarkTheme {
  /// Build a fully-configured dark theme.
  ///
  /// Set [isHighContrast] to `true` for WCAG AAA (7.0:1 minimum).
  static ThemeData build({required bool isHighContrast}) {
    final StadiumColorTokens tokens = isHighContrast
        ? StadiumColorTokens.highContrast
        : StadiumColorTokens.standard;

    // Skip GoogleFonts in tests or offline conditions to ensure pure rendering.
    final bool isTest = const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    final TextTheme baseTextTheme = isTest || kIsWeb
        ? ThemeData.dark().textTheme
        : GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme);

    final TextTheme styledTextTheme = baseTextTheme.copyWith(
      // KPI value style: large, bold, gold
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: tokens.primaryGold,
      ),
      // Label style: medium weight, primary text
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      // Caption style: small, secondary text
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: tokens.textSecondary,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tokens.background,
      colorScheme: ColorScheme.dark(
        primary: tokens.primaryGold,
        secondary: tokens.success,
        error: tokens.alertRed,
        surface: tokens.surface,
        onPrimary: tokens.onPrimary,
        onSurface: tokens.textPrimary,
        onError: tokens.textPrimary,
      ),
      textTheme: styledTextTheme,
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primaryGold,
          foregroundColor: tokens.onPrimary,
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        StadiumThemeExtension(
          tokens: tokens,
          isHighContrast: isHighContrast,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Typography Helper
// ══════════════════════════════════════════════════════════════════════

/// Context-aware typography that reads colors from [StadiumColorTokens].
///
/// Never hardcodes colors — always derives from the current theme extension.
/// Usage: `AvenuTypography.kpi(context)` to get the KPI display style.
abstract final class AvenuTypography {
  /// Large KPI value style (32px, bold, primaryGold).
  static TextStyle kpi(BuildContext context) {
    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;
    return TextStyle(
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: ext.tokens.primaryGold,
    );
  }

  /// Label style (14px, medium, textPrimary).
  static TextStyle label(BuildContext context) {
    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;
    return TextStyle(
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: ext.tokens.textPrimary,
    );
  }

  /// Caption style (11px, regular, textSecondary).
  static TextStyle caption(BuildContext context) {
    final StadiumThemeExtension ext =
        Theme.of(context).extension<StadiumThemeExtension>()!;
    return TextStyle(
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: ext.tokens.textSecondary,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Theme Toggle Provider
// ══════════════════════════════════════════════════════════════════════

/// SharedPreferences key for the high-contrast toggle.
const String _kHighContrastKey = 'avcp_high_contrast';

/// Riverpod StateProvider that persists the high-contrast preference.
///
/// Initial value is read from SharedPreferences. Changes are written back
/// on every toggle.
final themeToggleProvider =
    StateNotifierProvider<ThemeToggleNotifier, bool>((ref) {
  return ThemeToggleNotifier();
});

/// StateNotifier for the theme toggle — loads from and persists to disk.
class ThemeToggleNotifier extends StateNotifier<bool> {
  ThemeToggleNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kHighContrastKey) ?? false;
  }

  /// Toggle high-contrast mode and persist the change.
  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrastKey, state);
  }
}
