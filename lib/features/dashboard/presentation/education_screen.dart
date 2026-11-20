import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/application/education_interest_controller.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_scroll_end.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  /// The grey grouped page behind the tab, for tests.
  static const pageKey = ValueKey('education-page');

  /// The "What's coming" section, for tests.
  static const upcomingKey = ValueKey('education-upcoming');

  Future<void> _onNotifyMe(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(educationInterestProvider.notifier).register();
    if (!context.mounted) return;
    // Honest copy: there is no launch-notification pipeline behind this yet,
    // so it must not promise one.
    AppSnackBar.success(
      context,
      l10n.dashboardEducationInterestThanks,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final notified = ref.watch(educationInterestProvider).value ?? false;

    // Grouped grey page (iOS 26 inset-grouped pattern): the upcoming
    // features are one white section. Bottom stays open: the list scrolls
    // behind the floating bar.
    return ColoredBox(
      key: EducationScreen.pageKey,
      color: context.sirati.groupedBackground,
      child: GroupedSurface(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = constraints.maxWidth >= 1100
                  ? 920.0
                  : constraints.maxWidth >= 780
                      ? 760.0
                      : constraints.maxWidth;
              final horizontalPadding =
                  AppSpacing.pageGutter(constraints.maxWidth);

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      dashboardScrollEnd(context),
                    ),
                    children: [
                      ScreenHeader(
                        english: english,
                        title: l10n.dashboardEducationTitle,
                        subtitle: l10n.dashboardEducationSubtitle,
                        icon: Icons.school_rounded,
                        unreadCount: SessionCache.instance.unreadCount,
                        // Named routes, so guests get the sign-in invitation.
                        onNotifications: () => Navigator.of(context)
                            .pushNamed(AppRoutes.notifications),
                        onAvatarTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                      ),
                      const SizedBox(height: 18),
                      MotionReveal(
                        order: 0,
                        child: _ComingSoonHero(
                          notified: notified,
                          onNotify: () => unawaited(_onNotifyMe(context, ref)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Three upcoming features as one inset-grouped section,
                      // each icon routed through a palette pair (icon
                      // foreground + soft container) so they adapt to dark mode
                      // and inherit any brand re-tune (SIRATI-101).
                      MotionReveal(
                        order: 1,
                        child: AppListSection(
                          key: EducationScreen.upcomingKey,
                          header: l10n.dashboardEducationWhatsComing,
                          children: [
                            _UpcomingFeatureRow(
                              icon: Icons.auto_stories_rounded,
                              iconColor: context.sirati.info,
                              iconBg: context.sirati.infoLight,
                              title: l10n.dashboardEducationCoursesTitle,
                              description: l10n.dashboardEducationCoursesBody,
                            ),
                            _UpcomingFeatureRow(
                              icon: Icons.record_voice_over_rounded,
                              iconColor: context.sirati.primaryInk,
                              iconBg: context.sirati.primaryLight,
                              title: l10n.dashboardEducationInterviewTitle,
                              description: l10n.dashboardEducationInterviewBody,
                            ),
                            _UpcomingFeatureRow(
                              icon: Icons.verified_rounded,
                              iconColor: context.sirati.tertiary,
                              iconBg: context.sirati.tertiaryLight,
                              title: l10n.dashboardEducationAtsGuidesTitle,
                              description: l10n.dashboardEducationAtsGuidesBody,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const MotionReveal(
                        order: 2,
                        child: _CvCtaCard(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Borderless, unshadowed card in the page's fill (white on the grouped
/// page), the iOS 26 card shape.
class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PageSurface.fillOf(context),
        borderRadius: AppRadius.cardAll,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ComingSoonHero extends StatelessWidget {
  final bool notified;
  final VoidCallback onNotify;

  const _ComingSoonHero({
    required this.notified,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _GroupedCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.sirati.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              color: context.sirati.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.sirati.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.dashboardEducationComingSoonBadge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.sirati.primaryInk,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.dashboardEducationHeroTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLg(context.sirati),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dashboardEducationHeroBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(context.sirati).copyWith(
              color: context.sirati.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          PressScale(
            child: ElevatedButton.icon(
              onPressed: notified ? null : onNotify,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.sirati.primary,
                foregroundColor: context.sirati.onPrimary,
                // "Registered" is a confirmation, not an unavailable action:
                // show it in the success pair rather than greyed out.
                disabledBackgroundColor: context.sirati.successLight,
                disabledForegroundColor: context.sirati.onSuccessContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(0, 48),
                // The theme's teal capsule.
              ),
              // The button turns into its confirmation: the bell pops into
              // a tick and the label cross-fades.
              icon: MotionMorph(
                morphKey: notified,
                child: Icon(
                  notified
                      ? Icons.check_circle_rounded
                      : Icons.notifications_active_rounded,
                  size: 18,
                ),
              ),
              label: MotionMorph(
                morphKey: notified,
                pop: false,
                child: Text(
                  notified
                      ? l10n.dashboardEducationInterestRegistered
                      : AppLocalizations.of(context).registerInterest,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One flat row of the "What's coming" section: icon box, title and the
/// full description (never truncated; it is the only copy).
class _UpcomingFeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _UpcomingFeatureRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppListSection.rowPadding,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: AppListIcon(icon, background: iconBg, color: iconColor),
            ),
            const SizedBox(width: AppListTileMetrics.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.titleSm(context.sirati),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.bodySm(context.sirati).copyWith(
                      color: context.sirati.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvCtaCard extends StatelessWidget {
  const _CvCtaCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _GroupedCard(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardEducationCtaTitle,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.titleSm(context.sirati),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dashboardEducationCtaBody,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.bodySm(context.sirati).copyWith(
                    color: context.sirati.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PressScale(
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createCv),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.sirati.primary,
                foregroundColor: context.sirati.onPrimary,
                minimumSize: const Size(0, 48),
              ),
              child: Text(l10n.dashboardCreateCv),
            ),
          ),
        ],
      ),
    );
  }
}
