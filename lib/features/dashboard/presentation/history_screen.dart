import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/dashboard/application/history_controllers.dart';
import 'package:sirati/features/dashboard/domain/history_page.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';

/// Past analyses and generated CVs, one tab each.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dashboardHistory),
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
    required this.itemBuilder,
  });

  final AsyncValue<HistoryPage<T>> value;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget empty;
  final Widget Function(HistoryPage<T> page)? header;
  final Widget Function(BuildContext context, T item) itemBuilder;

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
        final leading = headerWidget == null ? 0 : 1;
        return RefreshIndicator(
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
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: leading + items.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (headerWidget != null && i == 0) return headerWidget;
                    final index = i - leading;
                    if (index >= items.length) {
                      return LoadMoreFooter(
                        loading: page.loadingMore,
                        failed: page.loadMoreFailed,
                        onPressed: onLoadMore,
                      );
                    }
                    return itemBuilder(context, items[index]);
                  },
                ),
        );
      },
    );
  }
}

/// Completes when the refetch settles; errors surface through the provider.
Future<void> _settle(Future<Object?> next) async {
  try {
    await next;
  } catch (_) {}
}

void _push(BuildContext context, Widget screen) {
  unawaited(Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => screen),
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
      header: (page) => Text(
        l10n.analysisCount(page.items.length),
        textAlign: TextAlign.start,
        style: AppTextStyles.bodySm(context.sirati),
      ),
      itemBuilder: (context, analysis) => AnalysisHistoryCard(
        analysis: analysis,
        onTap: () => _push(context, AnalysisResultScreen(analysis: analysis)),
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
      itemBuilder: (context, cv) => GeneratedCvHistoryCard(
        cv: cv,
        onTap: () => _push(context, GeneratedCvScreen(generatedCv: cv)),
      ),
    );
  }
}
