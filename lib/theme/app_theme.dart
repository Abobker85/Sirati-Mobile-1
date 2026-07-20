import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/form_fields.dart';
import '../widgets/motion.dart';
import 'sirati_colors.dart';

export 'sirati_colors.dart';

/// Light-mode static palette — source of truth for [SiratiColors.light].
/// Prefer [context.sirati] in widgets so dark mode resolves correctly.
class AppColors {
  // ── Brand teal ──
  static const primary = Color(0xFF00A898);
  static const primaryDark = Color(0xFF006A60);
  static const primaryLight = Color(0xFFDDF6F3);
  static const primaryMid = Color(0xFF59DAC9);
  static const primaryContainer = Color(0xFF00A898);
  static const onPrimary = Color(0xFFFFFFFF);

  static const teal = Color(0xFF00A898);
  static const tealLight = Color(0xFFE1F5F2);
  static const tealDark = Color(0xFF006A60);

  static const amber = Color(0xFFC97F1B);
  static const amberLight = Color(0xFFFDE9C7);
  static const amberAccent = Color(0xFFF2A93D);

  static const red = Color(0xFFD8403A);
  static const redLight = Color(0xFFFFE1DE);

  static const tertiary = Color(0xFF9A4528);
  static const tertiaryLight = Color(0xFFFFDBD0);

  static const error = red;
  static const errorLight = redLight;
  static const success = Color(0xFF2E7D5B);
  static const successLight = Color(0xFFD7F0E5);
  static const warning = Color(0xFFC97F1B);
  static const warningLight = Color(0xFFFDE9C7);
  static const info = Color(0xFF00A898);
  static const infoLight = Color(0xFFDDF6F3);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAF7F2);
  static const surfaceLow = Color(0xFFF2F1EC);
  static const surfaceContainer = Color(0xFFEDECE6);
  static const surfaceHigh = Color(0xFFE7E5DE);
  static const border = Color(0xFFD3E3DF);
  static const borderStrong = Color(0xFFBBC9C6);

  static const textPrimary = Color(0xFF171D1B);
  static const textSecondary = Color(0xFF3C4947);
  static const textHint = Color(0xFF6C7A77);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A898), Color(0xFF006A60)],
  );

  static const softShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Spacing scale — use only these values for layout padding/gaps.
class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static double pageGutter(double width) => width >= 780 ? lg + 4 : lg;

  static const scrollBottomNav = 104.0;
  static const scrollBottomNavFab = 156.0;
}

/// Shared type ramp. Pass [colors] (e.g. `context.sirati`) for theme-aware text.
/// Defaults to light palette when omitted (safe for unmigrated call sites).
class AppTextStyles {
  static TextStyle titleLg([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 18,
      height: 1.35,
      fontWeight: FontWeight.w800,
      color: c.textPrimary,
    );
  }

  static TextStyle titleMd([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: c.textPrimary,
    );
  }

  static TextStyle titleSm([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: c.textPrimary,
    );
  }

  static TextStyle bodyMd([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 14,
      height: 1.55,
      fontWeight: FontWeight.w400,
      color: c.textPrimary,
    );
  }

  static TextStyle bodySm([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 12.5,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
  }

  static TextStyle labelMd([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: c.textSecondary,
    );
  }

  static TextStyle displayStat([SiratiColors? colors]) {
    final c = colors ?? SiratiColors.light;
    return TextStyle(
      fontSize: 28,
      height: 1.1,
      fontWeight: FontWeight.w800,
      color: c.textPrimary,
    );
  }
}

class AppTheme {
  static ThemeData get light => _build(SiratiColors.light, Brightness.light);

  static ThemeData get dark => _build(SiratiColors.dark, Brightness.dark);

  static ThemeData _build(SiratiColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.amber,
        onSecondary: isDark ? c.textPrimary : Color(0xFF1A1200),
        tertiary: c.tertiary,
        onTertiary: c.onPrimary,
        error: c.error,
        onError: isDark ? c.textPrimary : Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      scaffoldBackgroundColor: c.background,
      fontFamily: 'IBM Plex Sans Arabic',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          height: 1.3,
          fontWeight: FontWeight.w800,
          color: c.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          height: 1.35,
          fontWeight: FontWeight.w800,
          color: c.textPrimary,
        ),
        titleLarge: AppTextStyles.titleLg(c),
        titleMedium: AppTextStyles.titleMd(c),
        titleSmall: AppTextStyles.titleSm(c),
        bodyLarge: AppTextStyles.bodyMd(c),
        bodyMedium: AppTextStyles.bodySm(c),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        labelMedium: AppTextStyles.labelMd(c),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: systemUiOverlayStyle(c, brightness),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
          fontFamily: 'IBM Plex Sans Arabic',
        ),
        iconTheme: IconThemeData(color: c.textSecondary, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: AppFormStyles.inputThemeFor(c),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.primaryLight,
        labelStyle: TextStyle(
            color: c.primaryDark, fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textHint,
        selectedLabelStyle:
            TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11.5),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.textHint,
        indicatorColor: c.primary,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? c.surfaceHigh : c.textPrimary,
        contentTextStyle:
            TextStyle(color: isDark ? c.textPrimary : Colors.white),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SiratiPageTransitionsBuilder(),
          TargetPlatform.iOS: SiratiPageTransitionsBuilder(),
          TargetPlatform.macOS: SiratiPageTransitionsBuilder(),
          TargetPlatform.windows: SiratiPageTransitionsBuilder(),
          TargetPlatform.linux: SiratiPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Global status / navigation bar styling for every route (also on
  /// [AppBarTheme.systemOverlayStyle]). Transparent bars support edge-to-edge;
  /// icon brightness follows theme.
  static SystemUiOverlayStyle systemUiOverlayStyle(
    SiratiColors c,
    Brightness brightness,
  ) {
    final lightIcons = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: lightIcons ? Brightness.light : Brightness.dark,
      statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
      // Transparent for SystemUiMode.edgeToEdge; content uses SafeArea.
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          lightIcons ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }
}

// ── Reusable Widget Helpers ──────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Material(
      color: color ?? c.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
            boxShadow: c.softShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SiratiMark extends StatelessWidget {
  final double size;
  final bool elevated;

  const SiratiMark({super.key, this.size = 56, this.elevated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12384F), Color(0xFF0E8F86)],
        ),
        borderRadius: BorderRadius.circular(size * .26),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x3312384F),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                )
              ]
            : null,
      ),
      child: CustomPaint(painter: _SiratiMarkPainter()),
    );
  }
}

class _SiratiMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mark = Path()
      ..moveTo(size.width * .22, size.height * .56)
      ..cubicTo(
        size.width * .26,
        size.height * .66,
        size.width * .34,
        size.height * .75,
        size.width * .41,
        size.height * .75,
      )
      ..cubicTo(
        size.width * .47,
        size.height * .75,
        size.width * .51,
        size.height * .67,
        size.width * .56,
        size.height * .59,
      )
      ..cubicTo(
        size.width * .63,
        size.height * .47,
        size.width * .69,
        size.height * .36,
        size.width * .75,
        size.height * .27,
      );

    canvas.drawPath(mark, stroke);
    canvas.drawCircle(
      Offset(size.width * .79, size.height * .23),
      size.width * .07,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.sirati.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const StatusChip(
      {super.key, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
