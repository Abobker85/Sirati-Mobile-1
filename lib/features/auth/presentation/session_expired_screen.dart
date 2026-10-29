import 'package:flutter/material.dart';

import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/components/brand_gradient_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown once when the server rejects the session (HTTP 401), before sign-in.
///
/// Replaces the silent jump to Login: it says what happened, that account
/// data is safe, and offers one clear way back in.
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  void _signIn(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: ApiConfig.supportEmail,
      queryParameters: {'subject': l10n.contactUsEmailSubject},
    );
    var launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {}
    if (!launched && context.mounted) {
      AppSnackBar.warning(
          context, l10n.contactUsFallback(ApiConfig.supportEmail));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: _sidePadding(constraints.maxWidth),
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.md * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _Pill(
                          icon: Icons.shield_outlined,
                          label: l10n.authSessionExpiredBadge,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      const ExcludeSemantics(child: _ShieldIllustration()),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: _Chip(label: l10n.authSessionExpiredChip),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.authSessionExpiredTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.of(
                            context,
                            AppTypography.displayMd,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.authSessionExpiredBody,
                        textAlign: TextAlign.center,
                        style: AppTypography.of(
                          context,
                          AppTypography.bodyLg,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ReassuranceCard(text: l10n.authSessionExpiredDataSafe),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      BrandGradientButton(
                        label: l10n.authSessionExpiredSignIn,
                        icon: Icons.login_rounded,
                        onPressed: () => _signIn(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: TextButton(
                          onPressed: () => _contactSupport(context),
                          style: TextButton.styleFrom(
                            foregroundColor: c.primaryInk,
                            minimumSize: const Size(
                              AppTouchTarget.min,
                              AppTouchTarget.min,
                            ),
                          ),
                          child: Text(
                            l10n.authSessionExpiredHelp,
                            textAlign: TextAlign.center,
                            style: AppTypography.of(
                              context,
                              AppTypography.bodyMd,
                              color: c.primaryInk,
                            ).copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: c.primaryInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Page gutter, widened so content never exceeds [_maxContentWidth].
  static double _sidePadding(double width) {
    final gutter = AppSpacing.pageGutter(width);
    final centered = (width - _maxContentWidth) / 2;
    return centered > gutter ? centered : gutter;
  }

  static const _maxContentWidth = 440.0;
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c.primaryInk),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.of(
                context,
                AppTypography.labelMd,
                color: c.primaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: c.tealLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.teal.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.of(
          context,
          AppTypography.labelMd,
          color: c.onSuccessContainer,
        ),
      ),
    );
  }
}

class _ReassuranceCard extends StatelessWidget {
  final String text;

  const _ReassuranceCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.tealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: c.onSuccessContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.of(
                context,
                AppTypography.titleSm,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shield holding a CV page, with a clock badge (time ran out) and a check
/// badge (data is safe). Widgets only, so it follows the theme in dark mode.
class _ShieldIllustration extends StatelessWidget {
  const _ShieldIllustration();

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Center(
      child: SizedBox(
        width: 190,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tealLight,
              ),
            ),
            Icon(
              Icons.shield_rounded,
              size: 140,
              color: c.surface,
              shadows: c.softShadow
                  .map((s) => Shadow(
                        color: s.color,
                        blurRadius: s.blurRadius,
                        offset: s.offset,
                      ))
                  .toList(),
            ),
            const _CvPage(),
            PositionedDirectional(
              end: 14,
              bottom: 18,
              child: _Badge(
                size: 54,
                gradient: [c.brandSurface, c.brandSurfaceDeep],
                child: Icon(
                  Icons.schedule_rounded,
                  size: 28,
                  color: c.onBrandSurface,
                ),
              ),
            ),
            PositionedDirectional(
              start: 12,
              top: 92,
              child: _Badge(
                size: 34,
                color: c.surface,
                child: Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: c.onSuccessContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvPage extends StatelessWidget {
  const _CvPage();

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    Widget line(double width, Color color) => Container(
          width: width,
          height: 4,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return Container(
      width: 46,
      height: 58,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.surfaceLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(18, c.primaryInk),
          line(28, c.teal.withValues(alpha: 0.5)),
          line(24, c.teal.withValues(alpha: 0.5)),
          line(20, c.border),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final double size;
  final Color? color;
  final List<Color>? gradient;
  final Widget child;

  const _Badge({
    required this.size,
    required this.child,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: gradient == null ? null : LinearGradient(colors: gradient!),
        border: Border.all(color: c.surface, width: 3),
        boxShadow: c.softShadow,
      ),
      child: Center(child: child),
    );
  }
}
