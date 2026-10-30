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
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_jobs_section.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/features/dashboard/presentation/home/home_service_tile.dart';
import 'package:sirati/features/dashboard/presentation/home/home_start_card.dart';
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

/// Home tab, as on the approved board (option 3 with its changes): profile
/// row, the create and ATS start cards, three services, latest jobs, and the
/// latest CV with the honesty line.
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
                : AppLocalizations.of(context).dashboardHomeLoadFailed,
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
                  ref.invalidate(homeLatestJobsProvider(english));
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

class _DashboardList extends StatelessWidget {
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

  void _push(BuildContext context, Widget screen) {
    unawaited(
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final gutter = EdgeInsets.symmetric(horizontal: horizontalPadding);

    final services = [
      HomeServiceTile(
        inkKey: const ValueKey('home-service-upload'),
        icon: Icons.upload_file_outlined,
        label: l.homeServiceUpload,
        onTap: () => _push(
          context,
          const CvAnalysisScreen(initialSource: AnalysisCvSource.upload),
        ),
      ),
      HomeServiceTile(
        inkKey: const ValueKey('home-service-target'),
        icon: Icons.track_changes_rounded,
        label: l.homeServiceTarget,
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.jobMatch);
          // Job match can create a tailored CV.
          if (context.mounted) await onRefresh();
        },
      ),
      HomeServiceTile(
        inkKey: const ValueKey('home-service-education'),
        icon: Icons.school_outlined,
        label: l.homeServiceEducation,
        comingSoon: true,
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
              subtitle: l.homeProfileSubtitle,
              unreadCount: summary.unreadNotifications ??
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
          if (summary.offline)
            Padding(
              padding: gutter.copyWith(top: AppSpacing.sm),
              child: OfflineCacheBanner(english: english, surface: 'dashboard'),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: gutter,
            child: MotionReveal(
              order: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeStartCard(
                    inkKey: const ValueKey('home-start-create'),
                    tone: HomeStartTone.create,
                    title: l.homeStartCreateTitle,
                    body: l.homeStartCreateBody,
                    onTap: () => unawaited(
                      Navigator.pushNamed(context, AppRoutes.createCv),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeStartCard(
                    inkKey: const ValueKey('home-start-ats'),
                    tone: HomeStartTone.ats,
                    title: l.homeStartAtsTitle,
                    body: l.homeStartAtsBody,
                    onTap: () => _push(context, const CvAnalysisScreen()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: gutter,
            child: MotionReveal(
              order: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (MediaQuery.textScalerOf(context).scale(1) >= 1.5 ||
                      constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, tile) in services.indexed) ...[
                          if (i > 0) const SizedBox(height: 10),
                          tile,
                        ],
                      ],
                    );
                  }
                  // Side by side, all three take the tallest one's height.
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, tile) in services.indexed) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: tile),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: gutter,
            child: MotionReveal(
              order: 3,
              child: DashboardJobsSection(
                onViewAll: () => onNavigate(DashboardTab.jobNews),
                onOpenSaved: () => onNavigate(DashboardTab.myCvs),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: gutter,
            child: MotionReveal(
              order: 4,
              child: HomeLatestCvSection(
                onViewAll: () => onNavigate(DashboardTab.myCvs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
