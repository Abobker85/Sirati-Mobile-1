import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/features/dashboard/application/dashboard_controller.dart';
import 'package:sirati/features/dashboard/application/history_controllers.dart';
import 'package:sirati/features/dashboard/domain/dashboard_summary.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_cv_hero.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_jobs_section.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_recent_activity.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_tool_card.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';

/// Home tab, as agreed in Salem's review (2026-10-24): brand header, the CV
/// hero in its empty or returning state, two tools, jobs for you and the
/// latest activity.
class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key, required this.onNavigate});

  final ValueChanged<DashboardTab> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final summary = ref.watch(dashboardProvider(english));

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = constraints.maxWidth >= 1100
              ? 920.0
              : constraints.maxWidth >= 780
              ? 760.0
              : constraints.maxWidth;
          final horizontalPadding = AppSpacing.pageGutter(constraints.maxWidth);

          Widget shell(Widget child) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: child,
            ),
          );

          return AppAsyncBody<DashboardSummary>(
            snapshot: summary.toSnapshot(),
            english: english,
            onRetry: () => ref.invalidate(dashboardProvider(english)),
            errorMessage: (error) => error is ApiException
                ? error.displayMessage
                : (english
                      ? 'Could not load dashboard.'
                      : 'تعذر تحميل الرئيسية.'),
            loading: SafeArea(
              bottom: false,
              child: shell(
                DashboardSkeleton(horizontalPadding: horizontalPadding),
              ),
            ),
            builder: (data) => shell(
              _DashboardList(
                summary: data,
                english: english,
                horizontalPadding: horizontalPadding,
                onRefresh: () async {
                  await refreshDashboard(ref, english: english);
                  await refreshMyCvs(ref, english: english);
                  ref.invalidate(latestDashboardCvProvider(english));
                  ref.invalidate(generatedCvsHistoryProvider);
                  ref.invalidate(analysesHistoryProvider);
                  ref.invalidate(jobNewsFeedProvider(english));
                },
                onNavigate: onNavigate,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardList extends ConsumerWidget {
  const _DashboardList({
    required this.summary,
    required this.english,
    required this.horizontalPadding,
    required this.onRefresh,
    required this.onNavigate,
  });

  final DashboardSummary summary;
  final bool english;
  final double horizontalPadding;
  final Future<void> Function() onRefresh;
  final ValueChanged<DashboardTab> onNavigate;

  /// How far the hero card reaches up into the brand band.
  static const _heroOverlap = 56.0;

  void _push(BuildContext context, Widget screen) {
    unawaited(
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final hasCv = ref.watch(latestDashboardCvProvider(english)).value != null;
    final textButtonStyle = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    final gutter = EdgeInsets.symmetric(horizontal: horizontalPadding);

    final tools = [
      if (hasCv)
        DashboardToolCard(
          key: const ValueKey('home-tool-create'),
          tone: DashboardToolTone.create,
          title: l.homeToolCreateTitle,
          subtitle: l.homeToolCreateBody,
          icon: Icons.note_add_outlined,
          onTap: () =>
              unawaited(Navigator.pushNamed(context, AppRoutes.createCv)),
        )
      else
        DashboardToolCard(
          key: const ValueKey('home-tool-ats'),
          title: l.homeToolAtsTitle,
          subtitle: l.homeToolAtsBody,
          icon: Icons.document_scanner_outlined,
          onTap: () => _push(context, const CvAnalysisScreen()),
        ),
      DashboardToolCard(
        key: const ValueKey('home-tool-education'),
        tone: DashboardToolTone.education,
        title: l.homeToolEducationTitle,
        subtitle: l.homeToolEducationBody,
        icon: Icons.school_outlined,
        onTap: () => onNavigate(DashboardTab.education),
      ),
    ];

    return RefreshIndicator(
      color: c.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.scrollBottomNav),
        children: [
          MotionReveal(
            order: 0,
            child: DashboardHomeHeader(
              name: summary.name,
              subtitle: summary.status.isNotEmpty
                  ? summary.status
                  : hasCv
                  ? l.homeHeaderSubtitleReturning
                  : l.homeHeaderSubtitleNew,
              unreadCount:
                  summary.unreadNotifications ??
                  SessionCache.instance.unreadCount,
              onNotifications: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
                // Reading notifications changes the unread badge.
                await onRefresh();
              },
              onAvatarTap: () => _push(context, const SettingsScreen()),
            ),
          ),
          // The hero sits half on the brand band, as in the agreed design.
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _heroOverlap,
                child: DecoratedBox(
                  decoration: DashboardHomeHeader.brandBand(
                    context,
                    radius: 28,
                  ),
                ),
              ),
              Padding(
                padding: gutter,
                child: MotionReveal(
                  order: 1,
                  child: DashboardCvHero(onReturnFromJobMatch: onRefresh),
                ),
              ),
            ],
          ),
          if (summary.offline)
            Padding(
              padding: gutter.copyWith(top: AppSpacing.sm),
              child: OfflineCacheBanner(english: english, surface: 'dashboard'),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: gutter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (MediaQuery.textScalerOf(context).scale(1) >= 1.5 ||
                    constraints.maxWidth < 340) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [tools[0], const SizedBox(height: 12), tools[1]],
                  );
                }
                // Side by side, both cards take the taller one's height.
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tools[0]),
                      const SizedBox(width: 12),
                      Expanded(child: tools[1]),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: gutter,
            child: MotionReveal(
              order: 3,
              child: DashboardJobsSection(
                onViewAll: () => onNavigate(DashboardTab.jobNews),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: gutter,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l.homeActivityTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _push(context, const HistoryScreen()),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: Text(english ? 'History' : 'السجل'),
                  style: textButtonStyle,
                ),
                TextButton(
                  onPressed: () => onNavigate(DashboardTab.myCvs),
                  style: textButtonStyle,
                  child: Text(english ? 'View All' : 'عرض الكل'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: gutter,
            child: const MotionReveal(
              order: 4,
              child: DashboardRecentActivity(),
            ),
          ),
        ],
      ),
    );
  }
}
