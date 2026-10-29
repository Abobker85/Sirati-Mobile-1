import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/theme/auth_hero_palette.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';

/// How much room the hero takes: tall on Welcome, regular on Login, compact
/// on Register where the form is long.
enum AuthHeroSize { tall, regular, compact }

/// Below this viewport height every hero collapses to [AuthHeroSize.compact]
/// so the card can move up (e.g. while the keyboard is open).
const _compactHeaderExtent = 520.0;

const _heroRadius = 32.0;
const _cardRadius = 24.0;

/// How far the card rides up over the hero's rounded edge.
const authHeroCardOverlap = 28.0;

/// The signed-out page shared by Welcome, Login and Register: a full-bleed
/// gradient hero with the mark and copy, a white [card] overlapping its
/// rounded edge, then [below] on the page background.
///
/// It is a page body, not a [Scaffold], so hosts keep their own scaffold.
class AuthHeroPage extends StatelessWidget {
  final AuthHeroSize size;
  final String title;
  final String subtitle;
  final Widget card;
  final List<Widget> below;

  /// Shows the back button and runs on tap. When null the button shows only
  /// if the route can pop.
  final VoidCallback? onBack;

  /// Overrides when the back button shows; false inside a tab, where there
  /// is nothing to go back to.
  final bool? showBack;

  final Key? markKey;
  final Key? subtitleKey;
  final Key? cardKey;

  const AuthHeroPage({
    super.key,
    required this.size,
    required this.title,
    required this.subtitle,
    required this.card,
    this.below = const [],
    this.onBack,
    this.showBack,
    this.markKey,
    this.subtitleKey,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the dark hero.
      value: SystemUiOverlayStyle.light,
      child: AuthFormConstraint(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Height the body can actually use, including a keyboard that
            // shrinks the scaffold. Full-screen size stays tall while typing.
            final effective = constraints.maxHeight < _compactHeaderExtent
                ? AuthHeroSize.compact
                : size;
            final compact = effective == AuthHeroSize.compact;
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: insets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHero(
                    size: effective,
                    topInset: insets.top,
                    title: title,
                    subtitle: subtitle,
                    onBack: onBack,
                    showBack: showBack,
                    markKey: markKey,
                    subtitleKey: subtitleKey,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -authHeroCardOverlap),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DecoratedBox(
                            key: cardKey,
                            decoration: BoxDecoration(
                              color: context.sirati.surface,
                              borderRadius: BorderRadius.circular(_cardRadius),
                              border: Border.all(color: context.sirati.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: AuthHeroPalette.cardShadow,
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                  compact ? AppSpacing.md : AppSpacing.xl),
                              child: card,
                            ),
                          ),
                          ...below,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Full-bleed brand band: the logo's gradient under a fading grid, with the
/// mark and the copy in white.
class AuthHero extends StatelessWidget {
  final AuthHeroSize size;
  final double topInset;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool? showBack;
  final Key? markKey;
  final Key? subtitleKey;

  const AuthHero({
    super.key,
    required this.size,
    required this.topInset,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.showBack,
    this.markKey,
    this.subtitleKey,
  });

  /// The logo's gradient with the teal end deepened so white copy keeps AA
  /// against every stop.
  static const gradient = AuthHeroPalette.gradient;

  @override
  Widget build(BuildContext context) {
    final compact = size == AuthHeroSize.compact;
    final tall = size == AuthHeroSize.tall;
    final gap = compact ? AppSpacing.xs : AppSpacing.md;
    final back = showBack ?? (onBack != null || Navigator.of(context).canPop());
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_heroRadius),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_heroRadius),
        ),
        child: CustomPaint(
          painter: const _HeroGridPainter(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              topInset + (compact ? AppSpacing.xxs : AppSpacing.xs),
              AppSpacing.md,
              authHeroCardOverlap +
                  switch (size) {
                    AuthHeroSize.tall => AppSpacing.xxl + AppSpacing.md,
                    AuthHeroSize.regular => AppSpacing.xxl,
                    AuthHeroSize.compact => AppSpacing.md,
                  },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (back)
                      IconButton(
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const DirectionalIcon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AuthHeroPalette.onHero,
                          size: 18,
                        ),
                      ),
                    const Spacer(),
                    const LanguageToggle(
                      backgroundColor: AuthHeroPalette.pillBackground,
                      foregroundColor: AuthHeroPalette.onHero,
                      side: BorderSide(color: AuthHeroPalette.pillBorder),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 0 : AppSpacing.xs),
                Center(
                  child: SiratiMark(
                    key: markKey,
                    size: switch (size) {
                      AuthHeroSize.tall => 72,
                      AuthHeroSize.regular => 56,
                      AuthHeroSize.compact => 40,
                    },
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    compact ? AppTypography.titleLg : AppTypography.headlineMd,
                    color: AuthHeroPalette.onHero,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  key: subtitleKey,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    AppTypography.bodyMd,
                    color: AuthHeroPalette.onHero,
                  ).copyWith(height: tall ? 1.6 : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin white grid that fades out toward the bottom of the hero.
class _HeroGridPainter extends CustomPainter {
  static const cell = 24.0;

  const _HeroGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: AuthHeroPalette.gridFade,
      ).createShader(Offset.zero & size);
    for (var x = cell; x < size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = cell; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HeroGridPainter oldDelegate) => false;
}
