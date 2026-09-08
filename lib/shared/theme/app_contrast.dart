import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/sirati_colors.dart';

/// WCAG contrast for semantic token pairs (SIRATI-17).
///
/// Ratios are measured from [Color.computeLuminance] (sRGB relative luminance).
/// AA: 4.5:1 body text, 3.0:1 large text / UI chrome.
class ContrastPair {
  const ContrastPair({
    required this.name,
    required this.foreground,
    required this.background,
    required this.minRatio,
  });

  final String name;
  final Color foreground;
  final Color background;
  final double minRatio;

  double get ratio => AppContrast.ratio(foreground, background);

  bool get passes => ratio >= minRatio;
}

class AppContrast {
  AppContrast._();

  static double ratio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final light = l1 > l2 ? l1 : l2;
    final dark = l1 > l2 ? l2 : l1;
    return (light + 0.05) / (dark + 0.05);
  }

  /// Foreground/background pairs that must stay WCAG AA.
  static List<ContrastPair> pairs(SiratiColors c) {
    return [
      ContrastPair(
        name: 'onSurface / background',
        foreground: c.onSurface,
        background: c.background,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onSurface / surface',
        foreground: c.onSurface,
        background: c.surface,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onSurfaceVariant / background',
        foreground: c.onSurfaceVariant,
        background: c.background,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onSurfaceVariant / surface',
        foreground: c.onSurfaceVariant,
        background: c.surface,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onSurfaceMuted / background',
        foreground: c.onSurfaceMuted,
        background: c.background,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onSurfaceMuted / surface',
        foreground: c.onSurfaceMuted,
        background: c.surface,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onPrimary / primary',
        foreground: c.onPrimary,
        background: c.primary,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'onError / error',
        foreground: c.onError,
        background: c.error,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'error / surface',
        foreground: c.error,
        background: c.surface,
        minRatio: 3.0,
      ),
      ContrastPair(
        name: 'primaryDark / surface',
        foreground: c.primaryDark,
        background: c.surface,
        minRatio: 4.5,
      ),
      ContrastPair(
        name: 'primaryDark / background',
        foreground: c.primaryDark,
        background: c.background,
        minRatio: 4.5,
      ),
    ];
  }
}
