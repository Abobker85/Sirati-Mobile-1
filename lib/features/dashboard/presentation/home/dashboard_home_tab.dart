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
import 'package:sirati/features/dashboard/presentation/home/home_glass_header.dart';
import 'package:sirati/features/dashboard/presentation/home/home_intro.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/features/dashboard/presentation/home/home_premium_card.dart';
import 'package:sirati/features/dashboard/presentation/home/home_service_tile.dart';
import 'package:sirati/features/dashboard/presentation/home/home_start_card.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_scroll_end.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/shared/widgets/sirati_refresh_indicator.dart';

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

    // Bottom stays open: the list scrolls behind the floating bar.
    return SafeArea(
      top: false,
      bottom: false,
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

class _DashboardList extends StatefulWidget {
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

  @override
  State<_DashboardList> createState() => _DashboardListState();
}

/// Home builds up once per app launch: the profile row drops in, the start
/// cards grow in and a flash of light sweeps across each, the services pop
/// in one after another, and the sections below rise in. Later visits (tab
/// changes, refreshes, reloading the data) show Home straight away, and the
/// OS "remove animations" setting skips the intro.
class _DashboardListState extends State<_DashboardList>
    with SingleTickerProviderStateMixin {
  static bool _introPlayed = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: MotionDurations.homeIntro,
  );
  bool _introStarted = false;
  int? _visit;

  /// Coming back to Home plays a quicker version of the intro.
  static const _revisitIntro = Duration(milliseconds: 900);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visit = TabVisitScope.maybeOf(context);
    final revisit = _visit != null && visit != _visit;
    _visit = visit;
    if (revisit &&
        AmbientMotion.enabled.value &&
        !MotionSettings.reduce(context)) {
      _intro.duration = _revisitIntro;
      _intro.forward(from: 0);
      return;
    }
    if (_introStarted) return;
    _introStarted = true;
    if (_introPlayed || MotionSettings.reduce(context)) {
      _intro.value = 1;
    } else {
      _introPlayed = true;
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Widget _enter(
    double begin,
    double end,
    Widget child, {
    HomeIntroMotion motion = HomeIntroMotion.rise,
  }) =>
      HomeIntroItem(
        animation: _intro,
        begin: begin,
        end: end,
        motion: motion,
        child: child,
      );

  /// The intro's light sweep, then the same light passing again by itself
  /// every few seconds, the two cards taking turns ([shineDelay]).
  Widget _sweep(
    double begin,
    double end,
    Widget child, {
    Duration shineDelay = const Duration(seconds: 6),
  }) =>
      HomeIntroSweep(
        animation: _intro,
        begin: begin,
        end: end,
        radius: 22,
        strength: HomeStartCard.shineStrength,
        child: AmbientShine(
          radius: 22,
          strength: HomeStartCard.shineStrength,
          color: context.sirati.onBrandSurface,
          delay: shineDelay,
          rest: const Duration(seconds: 7),
          child: child,
        ),
      );

  void _push(BuildContext context, Widget screen) {
    unawaited(
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final gutter = EdgeInsets.symmetric(horizontal: widget.horizontalPadding);

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
          if (context.mounted) await widget.onRefresh();
        },
      ),
      HomeServiceTile(
        inkKey: const ValueKey('home-service-education'),
        icon: Icons.school_outlined,
        label: l.homeServiceEducation,
        comingSoon: true,
        onTap: () => widget.onNavigate(DashboardTab.education),
      ),
    ];

    // Services pop in one after another during the intro.
    final introServices = [
      for (final (i, tile) in services.indexed)
        _enter(
          .30 + .07 * i,
          .62 + .07 * i,
          tile,
          motion: HomeIntroMotion.pop,
        ),
    ];

    return SiratiRefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // The profile row stays pinned and turns to glass once the page
          // scrolls under it.
          PinnedHeaderSliver(
            child: HomeGlassHeader(
              child: _enter(
                0,
                .30,
                motion: HomeIntroMotion.drop,
                DashboardHomeHeader(
                  name: widget.summary.name,
                  subtitle: l.homeProfileSubtitle,
                  unreadCount: widget.summary.unreadNotifications ??
                      SessionCache.instance.unreadCount,
                  onNotifications: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                    // Reading notifications changes the unread badge.
                    await widget.onRefresh();
                  },
                  onAvatarTap: () => _push(context, const SettingsScreen()),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: dashboardScrollEnd(context)),
            sliver: SliverList.list(
              children: [
                if (widget.summary.offline)
                  Padding(
                    padding: gutter.copyWith(top: AppSpacing.sm),
                    child: OfflineCacheBanner(
                      english: widget.english,
                      surface: 'dashboard',
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: gutter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Each start card grows in, then a flash of light crosses it.
                      _enter(
                        .08,
                        .42,
                        motion: HomeIntroMotion.zoom,
                        _sweep(
                          .30,
                          .70,
                          IdleNudge(
                            child: HomeStartCard(
                              inkKey: const ValueKey('home-start-create'),
                              tone: HomeStartTone.create,
                              title: l.homeStartCreateTitle,
                              body: l.homeStartCreateBody,
                              onTap: () => unawaited(
                                Navigator.pushNamed(
                                    context, AppRoutes.createCv),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _enter(
                        .16,
                        .50,
                        motion: HomeIntroMotion.zoom,
                        _sweep(
                          .40,
                          .80,
                          HomeStartCard(
                            inkKey: const ValueKey('home-start-ats'),
                            tone: HomeStartTone.ats,
                            title: l.homeStartAtsTitle,
                            body: l.homeStartAtsBody,
                            onTap: () =>
                                _push(context, const CvAnalysisScreen()),
                          ),
                          shineDelay: const Duration(seconds: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: gutter,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (MediaQuery.textScalerOf(context).scale(1) >= 1.5 ||
                          constraints.maxWidth < 300) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, tile) in introServices.indexed) ...[
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
                            for (final (i, tile) in introServices.indexed) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Expanded(child: tile),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Free accounts only; collapses to nothing for Premium.
                _enter(.45, .78,
                    HomePremiumCard(padding: gutter.copyWith(top: 12))),
                const SizedBox(height: 24),
                Padding(
                  padding: gutter,
                  child: _enter(
                    .52,
                    .86,
                    DashboardJobsSection(
                      onViewAll: () => widget.onNavigate(DashboardTab.jobNews),
                      onOpenSaved: () => widget.onNavigate(DashboardTab.myCvs),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: gutter,
                  child: _enter(
                    .60,
                    1,
                    HomeLatestCvSection(
                      onViewAll: () => widget.onNavigate(DashboardTab.myCvs),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
