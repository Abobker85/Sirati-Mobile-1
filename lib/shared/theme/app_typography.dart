import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/sirati_colors.dart';

/// Token type scale (SIRATI-18).
///
/// Arabic needs more vertical room than Latin at the same point size.
/// Always resolve through [AppTypography.of] / [resolve] so line-height
/// follows [Directionality] (RTL ≈ Arabic).
class AppTypeToken {
  const AppTypeToken({
    required this.size,
    required this.weight,
    required this.heightLatin,
    required this.heightArabic,
  });

  final double size;
  final FontWeight weight;
  final double heightLatin;
  final double heightArabic;

  TextStyle resolve({required bool arabic, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: arabic ? heightArabic : heightLatin,
      color: color,
      fontFamily: 'IBM Plex Sans Arabic',
    );
  }
}

/// Display / headline / title / body / label, each with weights.
class AppTypography {
  AppTypography._();

  static const displayLg = AppTypeToken(
    size: 32,
    weight: FontWeight.w800,
    heightLatin: 1.15,
    heightArabic: 1.38,
  );
  static const displayMd = AppTypeToken(
    size: 28,
    weight: FontWeight.w800,
    heightLatin: 1.18,
    heightArabic: 1.4,
  );

  static const headlineLg = AppTypeToken(
    size: 24,
    weight: FontWeight.w800,
    heightLatin: 1.25,
    heightArabic: 1.48,
  );
  static const headlineMd = AppTypeToken(
    size: 20,
    weight: FontWeight.w700,
    heightLatin: 1.28,
    heightArabic: 1.5,
  );

  static const titleLg = AppTypeToken(
    size: 18,
    weight: FontWeight.w800,
    heightLatin: 1.3,
    heightArabic: 1.52,
  );
  static const titleMd = AppTypeToken(
    size: 16,
    weight: FontWeight.w700,
    heightLatin: 1.35,
    heightArabic: 1.55,
  );
  static const titleSm = AppTypeToken(
    size: 14,
    weight: FontWeight.w700,
    heightLatin: 1.35,
    heightArabic: 1.52,
  );

  static const bodyLg = AppTypeToken(
    size: 16,
    weight: FontWeight.w400,
    heightLatin: 1.4,
    heightArabic: 1.65,
  );
  static const bodyMd = AppTypeToken(
    size: 14,
    weight: FontWeight.w400,
    heightLatin: 1.45,
    heightArabic: 1.65,
  );
  static const bodySm = AppTypeToken(
    size: 12.5,
    weight: FontWeight.w400,
    heightLatin: 1.4,
    heightArabic: 1.6,
  );

  static const labelLg = AppTypeToken(
    size: 14,
    weight: FontWeight.w700,
    heightLatin: 1.25,
    heightArabic: 1.42,
  );
  static const labelMd = AppTypeToken(
    size: 12,
    weight: FontWeight.w600,
    heightLatin: 1.3,
    heightArabic: 1.45,
  );
  static const labelSm = AppTypeToken(
    size: 11,
    weight: FontWeight.w600,
    heightLatin: 1.25,
    heightArabic: 1.4,
  );

  static const all = <AppTypeToken>[
    displayLg,
    displayMd,
    headlineLg,
    headlineMd,
    titleLg,
    titleMd,
    titleSm,
    bodyLg,
    bodyMd,
    bodySm,
    labelLg,
    labelMd,
    labelSm,
  ];

  static bool isArabic(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  static TextStyle of(
    BuildContext context,
    AppTypeToken token, {
    Color? color,
  }) {
    final colors = Theme.of(context).extension<SiratiColors>();
    return token.resolve(
      arabic: isArabic(context),
      color: color ?? colors?.textPrimary,
    );
  }

  static TextTheme textTheme(SiratiColors colors, {required bool arabic}) {
    TextStyle t(AppTypeToken token, {Color? color}) => token.resolve(
          arabic: arabic,
          color: color ?? colors.textPrimary,
        );

    return TextTheme(
      displayLarge: t(displayLg),
      displayMedium: t(displayMd),
      headlineLarge: t(headlineLg),
      headlineMedium: t(headlineMd),
      titleLarge: t(titleLg),
      titleMedium: t(titleMd),
      titleSmall: t(titleSm),
      bodyLarge: t(bodyLg),
      bodyMedium: t(bodyMd, color: colors.textSecondary),
      bodySmall: t(bodySm, color: colors.textSecondary),
      labelLarge: t(labelLg),
      labelMedium: t(labelMd, color: colors.textSecondary),
      labelSmall: t(labelSm, color: colors.textHint),
    );
  }
}

/// Corner radius tokens.
class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 18.0;
  static const pill = 24.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

/// Minimum accessible tap target (WCAG / Material).
class AppTouchTarget {
  static const min = 48.0;
}
