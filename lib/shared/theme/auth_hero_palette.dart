import 'package:flutter/material.dart';

/// Colours of the gradient hero shared by the sign-in screens.
///
/// The hero is the same in light and dark mode: it echoes the logo, and
/// white text is checked against both gradient stops for WCAG AA.
abstract final class AuthHeroPalette {
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12384F), Color(0xFF0B7A72)],
  );

  /// Text and icons on the hero.
  static const onHero = Colors.white;

  /// The language pill on the hero.
  static const pillBackground = Color(0x24000000);
  static const pillBorder = Color(0x4DFFFFFF);

  /// The grid lines, fading out toward the bottom of the hero.
  static const gridFade = [Color(0x1FFFFFFF), Color(0x00FFFFFF)];

  /// Shadow under the form card that overlaps the hero.
  static const cardShadow = Color(0x14000000);

  /// Google's brand colours for its "G" mark (fixed by Google's guidelines).
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC05);
  static const googleGreen = Color(0xFF34A853);
  static const googleBlue = Color(0xFF4285F4);
}
