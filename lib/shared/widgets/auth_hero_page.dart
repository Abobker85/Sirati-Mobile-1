import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// How much room the header takes: tall on Welcome, regular on Login,
/// compact on Register where the form is long.
enum AuthHeroSize { tall, regular, compact }

/// Below this viewport height every header collapses to
/// [AuthHeroSize.compact] so the form can move up (e.g. while the keyboard
/// is open).
const _compactHeaderExtent = 520.0;

/// The signed-out page shared by Welcome, Login, Register and the sign-in
/// invitation, in the iOS 26 style: a plain page with a top row (back and
/// language), the mark, a start-aligned large title and its subtitle, then
/// [card] and [below].
///
/// Everything scrolls together, so a short viewport (keyboard open, large
/// text) never pins the title over the form.
///
/// It is a page body, not a [Scaffold], so hosts keep their own scaffold.
class AuthHeroPage extends StatelessWidget {
  final AuthHeroSize size;
  final String title;
  final String subtitle;
  final Widget card;
  final List<Widget> below;

  /// Puts [card] in a borderless rounded fill (a selling-point or
  /// invitation card). False for forms, whose filled fields sit on the page.
  final bool boxedCard;

  /// Shows the back button and runs on tap. When null the button shows only
  /// if the route can pop.
  final VoidCallback? onBack;

  /// Overrides when the back button shows; false inside a tab, where there
  /// is nothing to go back to.
  final bool? showBack;

  final Key? markKey;
  final Key? subtitleKey;
  final Key? cardKey;

  /// Optional Hero tag for [SiratiMark] across Welcome → Login/Register.
  final Object? markHeroTag;

  const AuthHeroPage({
    super.key,
    required this.size,
    required this.title,
    required this.subtitle,
    required this.card,
    this.below = const [],
    this.boxedCard = false,
    this.onBack,
    this.showBack,
    this.markKey,
    this.subtitleKey,
    this.cardKey,
    this.markHeroTag,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark icons on the light page, light icons on the dark one.
      value: AppTheme.systemUiOverlayStyle(c, Theme.of(context).brightness),
      child: AuthFormConstraint(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Height the body can actually use, including a keyboard that
            // shrinks the scaffold.
            final effective = constraints.maxHeight < _compactHeaderExtent
                ? AuthHeroSize.compact
                : size;
            final gutter = AppSpacing.pageGutter(constraints.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                insets.top,
                gutter,
                insets.bottom + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthLargeTitleHeader(
                    size: effective,
                    title: title,
                    subtitle: subtitle,
                    onBack: onBack,
                    showBack: showBack,
                    markKey: markKey,
                    subtitleKey: subtitleKey,
                    markHeroTag: markHeroTag,
                  ),
                  SizedBox(
                    height: effective == AuthHeroSize.compact
                        ? AppSpacing.md
                        : AppSpacing.lg,
                  ),
                  if (boxedCard)
                    DecoratedBox(
                      key: cardKey,
                      decoration: BoxDecoration(
                        color: PageSurface.fillOf(context),
                        borderRadius: AppRadius.cardAll,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: card,
                      ),
                    )
                  else
                    KeyedSubtree(key: cardKey, child: card),
                  ...below,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The top row (back, language), the mark, the large title and the
/// subtitle, all on the start side.
class AuthLargeTitleHeader extends StatelessWidget {
  final AuthHeroSize size;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool? showBack;
  final Key? markKey;
  final Key? subtitleKey;
  final Object? markHeroTag;

  const AuthLargeTitleHeader({
    super.key,
    required this.size,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.showBack,
    this.markKey,
    this.subtitleKey,
    this.markHeroTag,
  });

  /// The mark's side for each header size.
  static double markSize(AuthHeroSize size) => switch (size) {
        AuthHeroSize.tall => 64,
        AuthHeroSize.regular => 56,
        AuthHeroSize.compact => 40,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final compact = size == AuthHeroSize.compact;
    final back = showBack ?? (onBack != null || Navigator.of(context).canPop());
    final reduce = MotionSettings.reduce(context);

    final mark = SiratiMark(key: markKey, size: markSize(size));
    final markWidget = markHeroTag != null && !reduce
        ? Hero(
            tag: markHeroTag!,
            transitionOnUserGestures: true,
            flightShuttleBuilder: (
              flightContext,
              animation,
              flightDirection,
              fromHeroContext,
              toHeroContext,
            ) =>
                FittedBox(
              fit: BoxFit.contain,
              child: toHeroContext.widget,
            ),
            child: mark,
          )
        : mark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTopBar(onBack: back ? onBack : null, showBack: back),
        SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.md),
        Align(alignment: AlignmentDirectional.centerStart, child: markWidget),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: AppTypography.of(
              context,
              compact ? AppTypography.sectionTitle : AppTypography.largeTitle,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          key: subtitleKey,
          textAlign: TextAlign.start,
          style: AppTypography.of(
            context,
            AppTypography.bodyLg,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Back chevron on the start side and the language toggle on the end side,
/// both on the page's grey fill.
class AuthTopBar extends StatelessWidget {
  /// Runs on back; when null and [showBack], pops the route.
  final VoidCallback? onBack;
  final bool showBack;
  final String? backTooltip;

  const AuthTopBar({
    super.key,
    this.onBack,
    this.showBack = true,
    this.backTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final fill = PageSurface.fillOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              tooltip: backTooltip ??
                  MaterialLocalizations.of(context).backButtonTooltip,
              style: IconButton.styleFrom(backgroundColor: fill),
              icon: DirectionalIcon(
                Icons.arrow_back_ios_new_rounded,
                color: c.textPrimary,
                size: 18,
              ),
            ),
          const Spacer(),
          LanguageToggle(backgroundColor: fill),
        ],
      ),
    );
  }
}
