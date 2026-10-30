import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/features/jobs/domain/job_news_filters.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_common.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/features/jobs/presentation/widgets/matched_preset_note.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

/// Job-news tab: search, preset / category / city filters, a featured
/// posting, then the rest of the list. Data comes from [jobNewsFeedProvider].
class JobNewsScreen extends ConsumerStatefulWidget {
  const JobNewsScreen({super.key, this.isActive = true});

  /// Whether this tab is currently visible in the dashboard shell.
  final bool isActive;

  @override
  ConsumerState<JobNewsScreen> createState() => _JobNewsScreenState();
}

class _JobNewsScreenState extends ConsumerState<JobNewsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void didUpdateWidget(covariant JobNewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Returning to the tab always refetches so backend changes show up
    // immediately instead of after a restart or cache expiry.
    // After the frame: this runs mid-build, and the refresh dirties other
    // widgets watching the feed (the Home tab's jobs section).
    if (widget.isActive && !oldWidget.isActive) {
      final english = AppLocale.isEnglish(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(refreshJobNews(ref, english: english));
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(jobNewsFiltersProvider.notifier).setQuery(value);
    });
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(jobNewsFiltersProvider.notifier).clear();
  }

  void _openJob(JobNews item) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobNewsDetailScreen(item: item)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final feed = ref.watch(jobNewsFeedProvider(english));
    final filters = ref.watch(jobNewsFiltersProvider);

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

          void retry() => ref.invalidate(jobNewsFeedProvider(english));

          Widget list(JobNewsFeed data, {String? errorMessage}) => shell(
                _JobNewsList(
                  feed: data,
                  filters: filters,
                  english: english,
                  horizontalPadding: horizontalPadding,
                  isReloading: feed.isLoading,
                  errorMessage: errorMessage,
                  onRetry: retry,
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  onClearFilters: _clearFilters,
                  onRefresh: () => refreshJobNews(ref, english: english),
                  onOpenJob: _openJob,
                ),
              );

          return AppAsyncBody<JobNewsFeed>(
            snapshot: feed.toSnapshot(),
            english: english,
            onRetry: retry,
            fallbackOnEmptyError: const JobNewsFeed.empty(),
            errorMessage: (error) => error is ApiException
                ? error.displayMessage
                : AppLocalizations.of(context).jobsLoadFailed,
            // Offline takes the whole tab (nothing can load); any other
            // failure keeps the search and chips so the filters that
            // failed stay visible and changeable, and never shows the
            // previous results as if they were current.
            errorBuilder: (error, message) =>
                error is ApiException && error.type == ApiErrorType.network
                    ? AppErrorState(
                        message: message,
                        english: english,
                        exception: error,
                        onRetry: () => refreshJobNews(ref, english: english),
                        onOpenSaved: () =>
                            Navigator.of(context).pushNamed(AppRoutes.myCvs),
                      )
                    : list(const JobNewsFeed.empty(), errorMessage: message),
            loading: shell(
              JobNewsSkeleton(horizontalPadding: horizontalPadding),
            ),
            builder: list,
          );
        },
      ),
    );
  }
}

class _JobNewsList extends ConsumerWidget {
  const _JobNewsList({
    required this.feed,
    required this.filters,
    required this.english,
    required this.horizontalPadding,
    required this.isReloading,
    required this.errorMessage,
    required this.onRetry,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onOpenJob,
  });

  final JobNewsFeed feed;
  final JobNewsFilters filters;
  final bool english;
  final double horizontalPadding;
  final bool isReloading;

  /// Set when the last load failed: shown with [onRetry] in place of results.
  final String? errorMessage;
  final VoidCallback onRetry;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function() onRefresh;
  final ValueChanged<JobNews> onOpenJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filterController = ref.read(jobNewsFiltersProvider.notifier);
    final now = DateTime.now();
    final failed = errorMessage != null;
    final featured = failed ? null : feed.featuredAt(now);
    final latest = failed ? const <JobNews>[] : feed.latestAt(now);
    final regionOnly = filters.region != JobNewsFilters.all &&
        filters.preset == JobNewsFilters.all &&
        filters.query.trim().isEmpty;
    // Changing filters or results swaps the featured block with an animation.
    final resultsKey = '${filters.hashCode}|${feed.items.length}|'
        '${featured?.id ?? 0}|$failed';

    return RefreshIndicator(
      color: context.sirati.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 18, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScreenHeader(
                    english: english,
                    title: l.jobNewsTitle,
                    icon: Icons.work_rounded,
                    unreadCount: SessionCache.instance.unreadCount,
                    onNotifications: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
                    onAvatarTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  if (feed.offline) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OfflineCacheBanner(english: english, surface: 'news'),
                  ],
                  if (isReloading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 2),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  JobSearchBar(
                    english: english,
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PresetChips(
                    english: english,
                    selectedPreset: filters.preset,
                    onSelected: filterController.setPreset,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RegionChips(
                    selectedRegion: filters.region,
                    onSelected: filterController.setRegion,
                  ),
                  if (filters.preset == 'matched') ...[
                    const SizedBox(height: AppSpacing.sm),
                    MatchedPresetNote(
                      profile: feed.profile,
                      // Guests get the sign-in invitation from the route.
                      onSetJobTitle: () =>
                          Navigator.of(context).pushNamed(AppRoutes.profile),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedSwitcher(
                    duration: MotionSettings.reduce(context)
                        ? Duration.zero
                        : MotionDurations.medium,
                    switchInCurve: MotionCurves.enter,
                    switchOutCurve: MotionCurves.exit,
                    child: Column(
                      key: ValueKey(resultsKey),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (failed)
                          AppErrorState(
                            message: errorMessage!,
                            english: english,
                            onRetry: onRetry,
                            scrollable: false,
                          )
                        else if (featured != null) ...[
                          MotionReveal(
                            order: 0,
                            child: FeaturedJobCard(
                              item: featured,
                              english: english,
                              onTap: () => onOpenJob(featured),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        if (failed)
                          const SizedBox.shrink()
                        else if (feed.items.isEmpty)
                          EmptyJobNews(
                            english: english,
                            regionLabel: regionOnly
                                ? jobRegionLabel(l, filters.region)
                                : null,
                            onShowAllRegions: () =>
                                filterController.setRegion(JobNewsFilters.all),
                            onClearFilters:
                                filters.isActive ? onClearFilters : null,
                          )
                        else if (latest.isNotEmpty) ...[
                          Text(
                            l.jobsLatestPostings,
                            textAlign: TextAlign.start,
                            style: AppTextStyles.titleMd(context.sirati),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 0, horizontalPadding, 112),
            sliver: SliverList.builder(
              itemCount: latest.length,
              itemBuilder: (context, index) {
                final item = latest[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  // +1: the featured card is reveal order 0.
                  child: MotionReveal(
                    order: index + 1,
                    child: JobNewsCard(
                      item: item,
                      english: english,
                      now: now,
                      onTap: () => onOpenJob(item),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
