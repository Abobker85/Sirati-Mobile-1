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
import 'package:sirati/features/dashboard/domain/dashboard_tab.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_cv_hero.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_recent_activity.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_stat_card.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_tool_card.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/shared/widgets/screen_header.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Home tab: greeting, stats, primary actions, and latest activity.
class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key, required this.onNavigate});

  final ValueChanged<DashboardTab> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final summary = ref.watch(dashboardProvider(english));

    return SafeArea(
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
            loading: shell(
              DashboardSkeleton(horizontalPadding: horizontalPadding),
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
    final textButtonStyle = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return RefreshIndicator(
      color: context.sirati.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          18,
          horizontalPadding,
          AppSpacing.scrollBottomNav,
        ),
        children: [
          MotionReveal(
            order: 0,
            child: ScreenHeader(
              english: english,
              title: AppLocale.greeting(summary.name, context),
              titleSize: 22,
              icon: Icons.person_rounded,
              status: summary.status.isEmpty ? null : summary.status,
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
          if (summary.offline) ...[
            const SizedBox(height: AppSpacing.sm),
            OfflineCacheBanner(english: english, surface: 'dashboard'),
          ],
          const SizedBox(height: AppSpacing.lg),
          const MotionReveal(order: 1, child: DashboardCvHero()),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                DashboardStatCard(
                  key: const ValueKey('home-stat-cvs'),
                  label: l.homeStatsCvs,
                  count: summary.cvCount,
                  icon: Icons.description_outlined,
                ),
                DashboardStatCard(
                  key: const ValueKey('home-stat-analyses'),
                  label: l.homeStatsAnalyses,
                  count: summary.analysisCount,
                  icon: Icons.analytics_outlined,
                ),
              ];
              return MediaQuery.textScalerOf(context).scale(1) >= 1.5
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[1]),
                      ],
                    );
            },
          ),
          const SizedBox(height: 20),
          AppCard(
            key: const ValueKey('home-primary-action'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  summary.primaryAction.title,
                  style: TextStyle(
                    color: context.sirati.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.primaryAction.subtitle,
                  style: TextStyle(color: context.sirati.textSecondary),
                ),
                const SizedBox(height: 12),
                SubmitButton(
                  label: summary.primaryAction.buttonLabel,
                  onPressed: () => unawaited(
                    Navigator.pushNamed(context, AppRoutes.createCv),
                  ),
                ),
              ],
            ),
          ),
          if (summary.hasLatestNews) ...[
            const SizedBox(height: 20),
            AppCard(
              key: const ValueKey('home-latest-news'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.newspaper_rounded,
                    color: context.sirati.primaryInk,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.latestNewsTitle,
                    style: TextStyle(
                      color: context.sirati.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.latestNewsSubtitle,
                    style: TextStyle(color: context.sirati.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            l.homeToolsTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.sirati.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                DashboardToolCard(
                  title: l.atsInputTitle,
                  subtitle: l.homeToolsAtsDescription,
                  action: l.atsInputAnalyze,
                  icon: Icons.document_scanner_outlined,
                  onTap: () => _push(context, const CvAnalysisScreen()),
                ),
                DashboardToolCard(
                  tone: DashboardToolTone.jobMatch,
                  title: l.jobMatchEntryTitle,
                  subtitle: l.homeToolsJobMatchDescription,
                  action: l.jobMatchEntryButton,
                  icon: Icons.compare_arrows_rounded,
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.jobMatch);
                    if (context.mounted) await onRefresh();
                  },
                ),
              ];
              if (MediaQuery.textScalerOf(context).scale(1) >= 1.5 ||
                  constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [cards[0], const SizedBox(height: 12), cards[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l.homeActivityTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.sirati.textPrimary,
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
          const SizedBox(height: 12),
          const MotionReveal(order: 4, child: DashboardRecentActivity()),
        ],
      ),
    );
  }
}
