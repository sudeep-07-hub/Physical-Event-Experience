/// Theme tests — AVCP Stadium-Dark Design System
///
/// Validates:
/// (a) Standard token contrast ratio ≥ 4.5:1 (WCAG AA)
/// (b) High-contrast token contrast ratio ≥ 7.0:1 (WCAG AAA)
/// (c) lerp at t=0.0 returns self
/// (d) lerp at t=1.0 returns other
/// (e) ThemeToggleNotifier initial value is false
/// (f) StadiumDarkTheme.build produces correct structure
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avcp_flutter/theme.dart';

/// Compute WCAG contrast ratio between two colors.
double _contrastRatio(Color foreground, Color background) {
  final double lF = foreground.computeLuminance();
  final double lB = background.computeLuminance();
  final double lighter = max(lF, lB);
  final double darker = min(lF, lB);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // Mock SharedPreferences for ThemeToggleNotifier tests
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, Object>{};
      }
      return null;
    });
  });

  group('StadiumColorTokens', () {
    // (a) Standard token contrast ratio ≥ 4.5:1
    test('standard primaryGold on background has ≥ 4.5:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.standard.primaryGold,
        StadiumColorTokens.standard.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'WCAG AA requires ≥ 4.5:1, got ${ratio.toStringAsFixed(2)}');
    });

    test('standard textPrimary on background has ≥ 4.5:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.standard.textPrimary,
        StadiumColorTokens.standard.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('standard textSecondary on background has ≥ 4.5:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.standard.textSecondary,
        StadiumColorTokens.standard.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('standard alertRed on background has ≥ 4.5:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.standard.alertRed,
        StadiumColorTokens.standard.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('standard success on background has ≥ 4.5:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.standard.success,
        StadiumColorTokens.standard.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    // (b) High-contrast token contrast ratio ≥ 7.0:1
    test('highContrast primaryGold on background has ≥ 7.0:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.highContrast.primaryGold,
        StadiumColorTokens.highContrast.background,
      );
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'WCAG AAA requires ≥ 7.0:1, got ${ratio.toStringAsFixed(2)}');
    });

    test('highContrast textSecondary on background has ≥ 7.0:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.highContrast.textSecondary,
        StadiumColorTokens.highContrast.background,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('highContrast success on background has ≥ 7.0:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.highContrast.success,
        StadiumColorTokens.highContrast.background,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('highContrast alertRed on background has ≥ 7.0:1 contrast', () {
      final double ratio = _contrastRatio(
        StadiumColorTokens.highContrast.alertRed,
        StadiumColorTokens.highContrast.background,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });
  });

  group('StadiumThemeExtension', () {
    final StadiumThemeExtension standard = const StadiumThemeExtension(
      tokens: StadiumColorTokens.standard,
      isHighContrast: false,
    );
    final StadiumThemeExtension hc = const StadiumThemeExtension(
      tokens: StadiumColorTokens.highContrast,
      isHighContrast: true,
    );

    // (c) lerp at t=0.0 returns self
    test('lerp at t=0.0 returns self tokens', () {
      final StadiumThemeExtension result = standard.lerp(hc, 0.0);
      expect(result.tokens.primaryGold, equals(standard.tokens.primaryGold));
      expect(result.isHighContrast, equals(false));
    });

    // (d) lerp at t=1.0 returns other
    test('lerp at t=1.0 returns other tokens', () {
      final StadiumThemeExtension result = standard.lerp(hc, 1.0);
      expect(result.tokens.primaryGold, equals(hc.tokens.primaryGold));
      expect(result.isHighContrast, equals(true));
    });

    test('lerp with null other returns self', () {
      final StadiumThemeExtension result = standard.lerp(null, 0.5);
      expect(result.tokens.primaryGold, equals(standard.tokens.primaryGold));
    });

    test('copyWith replaces fields correctly', () {
      final StadiumThemeExtension copy = standard.copyWith(
        isHighContrast: true,
      );
      expect(copy.isHighContrast, isTrue);
      expect(copy.tokens, equals(standard.tokens));
    });
  });

  group('StadiumDarkTheme', () {
    // GoogleFonts requires bundled assets in test. Test the theme structure
    // by verifying the extension is correctly attached.
    test('build standard theme has correct brightness', () {
      final ThemeData theme = StadiumDarkTheme.build(isHighContrast: false);
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('build standard theme has extension', () {
      final ThemeData theme = StadiumDarkTheme.build(isHighContrast: false);
      final StadiumThemeExtension? ext =
          theme.extension<StadiumThemeExtension>();
      expect(ext, isNotNull);
      expect(ext!.isHighContrast, isFalse);
    });

    test('build high-contrast theme has extension', () {
      final ThemeData theme = StadiumDarkTheme.build(isHighContrast: true);
      final StadiumThemeExtension? ext =
          theme.extension<StadiumThemeExtension>();
      expect(ext, isNotNull);
      expect(ext!.isHighContrast, isTrue);
    });

    test('scaffold background matches tokens', () {
      final ThemeData theme = StadiumDarkTheme.build(isHighContrast: false);
      expect(
        theme.scaffoldBackgroundColor,
        equals(StadiumColorTokens.standard.background),
      );
    });

    test('primary color is gold', () {
      final ThemeData theme = StadiumDarkTheme.build(isHighContrast: false);
      expect(
        theme.colorScheme.primary,
        equals(StadiumColorTokens.standard.primaryGold),
      );
    });
  });

  // (e) ThemeToggleNotifier initial value
  group('ThemeToggleNotifier', () {
    test('initial state is false', () {
      final ThemeToggleNotifier notifier = ThemeToggleNotifier();
      expect(notifier.state, isFalse);
    });
  });
}
