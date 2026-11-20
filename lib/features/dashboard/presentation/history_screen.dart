import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/expand_page_route.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/dashboard/application/history_controllers.dart';
import 'package:sirati/features/dashboard/domain/history_page.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/features/settings/domain/notification_groups.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/sirati_refresh_indicator.dart';

/// Past analyses and generated CVs, one tab each.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;

    // Grouped grey page: each date section is one white inset card.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.groupedBackground,
        appBar: AppBar(
          title: Text(l10n.dashboardHistory),
          backgroundColor: c.groupedBackground,
          surfaceTintColor: c.groupedBackground,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: Navigator.of(context).canPop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.dashboardRefresh,
              onPressed: () {
                ref
                  ..invalidate(analysesHistoryProvider)
                  ..invalidate(generatedCvsHistoryProvider);
              },
            ),
          ],
          bottom: TabBar(
            labelColor: c.textPrimary,
            unselectedLabelColor: c.textSecondary,
            indicatorColor: c.primary,
            tabs: [
              Tab(text: l10n.analyses),
              Tab(text: l10n.dashboardHistoryGeneratedCvsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AnalysesTab(), _GeneratedCvsTab()],
        ),
      ),
    );
  }
}

/// Loading / error / list scaffolding shared by both tabs.
class _HistoryTab<T> extends StatelessWidget {
  const _HistoryTab({
    required this.value,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.empty,
    required this.header,
    required this.dateOf,
    required this.itemBuilder,
    this.now,
  });

  final AsyncValue<HistoryPage<T>> value;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget empty;
  final Widget Function(HistoryPage<T> page)? header;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// When an item happened, for its date section.
  final DateTime? Function(T item) dateOf;

  /// Clock for the date sections; tests pin it.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    return AppAsyncBody<HistoryPage<T>>(
      snapshot: value.toSnapshot(),
      english: english,
      onRetry: onRetry,
      errorMessage: (error) => error is ApiException
          ? error.displayMessage
          : AppLocalizations.of(context).dashboardHistoryLoadFailed,
      loading: const ListScreenSkeleton(
        itemCount: 5,
        padding: EdgeInsets.all(AppSpacing.md),
      ),
      builder: (page) {
        final items = page.items;
        final headerWidget = header?.call(page);
        return SiratiRefreshIndicator(
          onRefresh: onRefresh,
          child: items.isEmpty
              // Scrollable so pull-to-refresh still works when empty.
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: empty,
                    ),
                  ),
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                  children: [
                    if (headerWidget != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppListSection.rowPadding,
                          end: AppListSection.rowPadding,
                          bottom: AppSpacing.xs,
                        ),
                        child: headerWidget,
                      ),
                    for (final (i, section) in historySections(
                      items,
                      dateOf,
                      now ?? DateTime.now(),
                    ).indexed) ...[
                      if (i > 0 || headerWidget != null)
                        const SizedBox(height: AppSpacing.lg),
                      AppListSection(
                        header: historyPeriodLabel(
                          AppLocalizations.of(context),
                          section.period,
                        ),
                        separatorIndent: historySeparatorIndent,
                        children: [
                          for (final (index, item) in section.items)
                            itemBuilder(context, item, index),
                        ],
                      ),
                    ],
                    if (page.hasMore) ...[
                      const SizedBox(height: AppSpacing.sm),
                      LoadMoreFooter(
                        loading: page.loadingMore,
                        failed: page.loadMoreFailed,
                        onPressed: onLoadMore,
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// One date section of a history list: its period and its items, each with
/// its place in the whole list.
typedef HistorySection<T> = ({
  NotificationPeriod period,
  List<(int, T)> items,
});

/// Splits [items] into date sections in list order (newest first from the
/// server): a new section starts whenever the period changes, so no item
/// ever moves out of order.
List<HistorySection<T>> historySections<T>(
  List<T> items,
  DateTime? Function(T item) dateOf,
  DateTime now,
) {
  final sections = <HistorySection<T>>[];
  for (final (index, item) in items.indexed) {
    final period = notificationPeriodOf(dateOf(item), now);
    if (sections.isEmpty || sections.last.period != period) {
      sections.add((period: period, items: []));
    }
    sections.last.items.add((index, item));
  }
  return sections;
}

String historyPeriodLabel(AppLocalizations l10n, NotificationPeriod period) =>
    switch (period) {
      NotificationPeriod.today => l10n.settingsNotificationsToday,
      NotificationPeriod.yesterday => l10n.settingsNotificationsYesterday,
      NotificationPeriod.thisWeek => l10n.settingsNotificationsThisWeek,
      NotificationPeriod.earlier => l10n.settingsNotificationsEarlier,
    };

/// Completes when the refetch settles; errors surface through the provider.
Future<void> _settle(Future<Object?> next) async {
  try {
    await next;
  } catch (_) {}
}

void _push(BuildContext context, Widget screen, {ExpandOrigin? origin}) {
  unawaited(Navigator.of(context).push(
    origin != null
        ? ExpandPageRoute<void>(origin: origin, builder: (_) => screen)
        : MaterialPageRoute<void>(builder: (_) => screen),
  ));
}

class _AnalysesTab extends ConsumerWidget {
  const _AnalysesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _HistoryTab(
      value: ref.watch(analysesHistoryProvider),
      onRetry: () => ref.invalidate(analysesHistoryProvider),
      onRefresh: () => _settle(ref.refresh(analysesHistoryProvider.future)),
      onLoadMore: () => unawaited(
        ref.read(analysesHistoryProvider.notifier).loadMore(),
      ),
      empty: AppEmptyState(
        icon: Icons.analytics_outlined,
        title: l10n.analysisCount(0),
        subtitle: l10n.dashboardHistoryAnalysesEmptySubtitle,
        actionLabel: l10n.dashboardHistoryAnalyzeCv,
        onAction: () => _push(context, const CvAnalysisScreen()),
        scrollable: false,
      ),
      dateOf: (analysis) => analysis.createdAt,
      header: (page) => Text(
        l10n.analysisCount(page.items.length),
        textAlign: TextAlign.start,
        style: AppTextStyles.bodySm(context.sirati),
      ),
      itemBuilder: (context, analysis, index) => MotionReveal(
        key: ValueKey('history-analysis-${analysis.id}'),
        order: index.clamp(0, MotionReveal.maxStaggerIndex),
        child: Builder(
          builder: (cardContext) => AnalysisHistoryCard(
            analysis: analysis,
            onTap: () => _push(
              context,
              AnalysisResultScreen(analysis: analysis),
              origin: ExpandOrigin.of(cardContext, radius: 0),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedCvsTab extends ConsumerWidget {
  const _GeneratedCvsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _HistoryTab(
      value: ref.watch(generatedCvsHistoryProvider),
      onRetry: () => ref.invalidate(generatedCvsHistoryProvider),
      onRefresh: () => _settle(ref.refresh(generatedCvsHistoryProvider.future)),
      onLoadMore: () => unawaited(
        ref.read(generatedCvsHistoryProvider.notifier).loadMore(),
      ),
      empty: AppEmptyState(
        icon: Icons.description_outlined,
        title: l10n.dashboardHistoryCvsEmptyTitle,
        subtitle: l10n.dashboardHistoryCvsEmptySubtitle,
        actionLabel: l10n.dashboardCreateCv,
        onAction: () => _push(context, const CvGeneratorScreen()),
        scrollable: false,
      ),
      header: null,
      dateOf: (cv) => cv.createdAt,
      itemBuilder: (context, cv, index) => MotionReveal(
        key: ValueKey('history-cv-${cv.id}'),
        order: index.clamp(0, MotionReveal.maxStaggerIndex),
        child: Builder(
          builder: (cardContext) => GeneratedCvHistoryCard(
            cv: cv,
            onTap: () => _push(
              context,
              GeneratedCvScreen(generatedCv: cv),
              origin: ExpandOrigin.of(cardContext, radius: 0),
            ),
          ),
        ),
      ),
    );
  }
}
