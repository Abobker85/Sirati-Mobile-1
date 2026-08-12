import 'package:flutter/material.dart';

/// Brand / semantic color roles for Sirati light and dark themes.
///
/// Registered on [ThemeData] via [ThemeExtension]. Access with [context.sirati].
@immutable
class SiratiColors extends ThemeExtension<SiratiColors> {
  const SiratiColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryMid,
    required this.primaryContainer,
    required this.onPrimary,
    required this.teal,
    required this.tealLight,
    required this.tealDark,
    required this.amber,
    required this.amberLight,
    required this.amberAccent,
    required this.red,
    required this.redLight,
    required this.tertiary,
    required this.tertiaryLight,
    required this.error,
    required this.errorLight,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.info,
    required this.infoLight,
    required this.surface,
    required this.background,
    required this.surfaceLow,
    required this.surfaceContainer,
    required this.surfaceHigh,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primaryGradient,
    required this.softShadow,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryMid;
  final Color primaryContainer;
  final Color onPrimary;
  final Color teal;
  final Color tealLight;
  final Color tealDark;
  final Color amber;
  final Color amberLight;
  final Color amberAccent;
  final Color red;
  final Color redLight;
  final Color tertiary;
  final Color tertiaryLight;
  final Color error;
  final Color errorLight;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color info;
  final Color infoLight;
  final Color surface;
  final Color background;
  final Color surfaceLow;
  final Color surfaceContainer;
  final Color surfaceHigh;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final LinearGradient primaryGradient;
  final List<BoxShadow> softShadow;

  /// Light palette — mirrors historical [AppColors] constants.
  static const light = SiratiColors(
    primary: Color(0xFF00A898),
    primaryDark: Color(0xFF006A60),
    primaryLight: Color(0xFFDDF6F3),
    primaryMid: Color(0xFF59DAC9),
    primaryContainer: Color(0xFF00A898),
    onPrimary: Color(0xFFFFFFFF),
    teal: Color(0xFF00A898),
    tealLight: Color(0xFFE1F5F2),
    tealDark: Color(0xFF006A60),
    amber: Color(0xFFC97F1B),
    amberLight: Color(0xFFFDE9C7),
    amberAccent: Color(0xFFF2A93D),
    red: Color(0xFFD8403A),
    redLight: Color(0xFFFFE1DE),
    tertiary: Color(0xFF9A4528),
    tertiaryLight: Color(0xFFFFDBD0),
    error: Color(0xFFD8403A),
    errorLight: Color(0xFFFFE1DE),
    success: Color(0xFF2E7D5B),
    successLight: Color(0xFFD7F0E5),
    warning: Color(0xFFC97F1B),
    warningLight: Color(0xFFFDE9C7),
    info: Color(0xFF00A898),
    infoLight: Color(0xFFDDF6F3),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFAF7F2),
    surfaceLow: Color(0xFFF2F1EC),
    surfaceContainer: Color(0xFFEDECE6),
    surfaceHigh: Color(0xFFE7E5DE),
    border: Color(0xFFD3E3DF),
    borderStrong: Color(0xFFBBC9C6),
    textPrimary: Color(0xFF171D1B),
    textSecondary: Color(0xFF3C4947),
    textHint: Color(0xFF6C7A77),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00A898), Color(0xFF006A60)],
    ),
    softShadow: [
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  /// Dark palette — teal brand, WCAG-minded text/surface pairs.
  static const dark = SiratiColors(
    primary: Color(0xFF2FC4B2),
    primaryDark: Color(0xFF1A9E8F),
    primaryLight: Color(0xFF0E3B36),
    primaryMid: Color(0xFF3DD4C2),
    primaryContainer: Color(0xFF2FC4B2),
    onPrimary: Color(0xFF00332D),
    teal: Color(0xFF2FC4B2),
    tealLight: Color(0xFF0E3B36),
    tealDark: Color(0xFF1A9E8F),
    amber: Color(0xFFE0A03A),
    amberLight: Color(0xFF3D2E14),
    amberAccent: Color(0xFFF2A93D),
    red: Color(0xFFF2726C),
    redLight: Color(0xFF4A211F),
    tertiary: Color(0xFFE8957A),
    tertiaryLight: Color(0xFF3D241C),
    error: Color(0xFFF2726C),
    errorLight: Color(0xFF4A211F),
    success: Color(0xFF5FBF92),
    successLight: Color(0xFF1A3D2E),
    warning: Color(0xFFE0A03A),
    warningLight: Color(0xFF3D2E14),
    info: Color(0xFF2FC4B2),
    infoLight: Color(0xFF0E3B36),
    surface: Color(0xFF1A201D),
    background: Color(0xFF121614),
    surfaceLow: Color(0xFF202623),
    surfaceContainer: Color(0xFF252C28),
    surfaceHigh: Color(0xFF2B332E),
    border: Color(0xFF31423E),
    borderStrong: Color(0xFF445753),
    textPrimary: Color(0xFFE6EAE7),
    textSecondary: Color(0xFFAEB8B4),
    textHint: Color(0xFF7E8985),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2FC4B2), Color(0xFF1A9E8F)],
    ),
    softShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  @override
  SiratiColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? primaryMid,
    Color? primaryContainer,
    Color? onPrimary,
    Color? teal,
    Color? tealLight,
    Color? tealDark,
    Color? amber,
    Color? amberLight,
    Color? amberAccent,
    Color? red,
    Color? redLight,
    Color? tertiary,
    Color? tertiaryLight,
    Color? error,
    Color? errorLight,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? info,
    Color? infoLight,
    Color? surface,
    Color? background,
    Color? surfaceLow,
    Color? surfaceContainer,
    Color? surfaceHigh,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    LinearGradient? primaryGradient,
    List<BoxShadow>? softShadow,
  }) {
    return SiratiColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryMid: primaryMid ?? this.primaryMid,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      teal: teal ?? this.teal,
      tealLight: tealLight ?? this.tealLight,
      tealDark: tealDark ?? this.tealDark,
      amber: amber ?? this.amber,
      amberLight: amberLight ?? this.amberLight,
      amberAccent: amberAccent ?? this.amberAccent,
      red: red ?? this.red,
      redLight: redLight ?? this.redLight,
      tertiary: tertiary ?? this.tertiary,
      tertiaryLight: tertiaryLight ?? this.tertiaryLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      softShadow: softShadow ?? this.softShadow,
    );
  }

  @override
  SiratiColors lerp(ThemeExtension<SiratiColors>? other, double t) {
    if (other is! SiratiColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SiratiColors(
      primary: l(primary, other.primary),
      primaryDark: l(primaryDark, other.primaryDark),
      primaryLight: l(primaryLight, other.primaryLight),
      primaryMid: l(primaryMid, other.primaryMid),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimary: l(onPrimary, other.onPrimary),
      teal: l(teal, other.teal),
      tealLight: l(tealLight, other.tealLight),
      tealDark: l(tealDark, other.tealDark),
      amber: l(amber, other.amber),
      amberLight: l(amberLight, other.amberLight),
      amberAccent: l(amberAccent, other.amberAccent),
      red: l(red, other.red),
      redLight: l(redLight, other.redLight),
      tertiary: l(tertiary, other.tertiary),
      tertiaryLight: l(tertiaryLight, other.tertiaryLight),
      error: l(error, other.error),
      errorLight: l(errorLight, other.errorLight),
      success: l(success, other.success),
      successLight: l(successLight, other.successLight),
      warning: l(warning, other.warning),
      warningLight: l(warningLight, other.warningLight),
      info: l(info, other.info),
      infoLight: l(infoLight, other.infoLight),
      surface: l(surface, other.surface),
      background: l(background, other.background),
      surfaceLow: l(surfaceLow, other.surfaceLow),
      surfaceContainer: l(surfaceContainer, other.surfaceContainer),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textHint: l(textHint, other.textHint),
      primaryGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          l(primaryGradient.colors.first, other.primaryGradient.colors.first),
          l(primaryGradient.colors.last, other.primaryGradient.colors.last),
        ],
      ),
      softShadow: t < 0.5 ? softShadow : other.softShadow,
    );
  }
}

/// Theme-aware brand colors: `context.sirati.primary`, etc.
extension SiratiColorsX on BuildContext {
  SiratiColors get sirati =>
      Theme.of(this).extension<SiratiColors>() ?? SiratiColors.light;
}
