import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// "Latest jobs" on Home (approved board): the first few jobs of the
/// unfiltered feed as compact cards, with a way to the full Jobs tab.
class DashboardJobsSection extends ConsumerWidget {
  const DashboardJobsSection({
    super.key,
    required this.onViewAll,
    this.onOpenSaved,
  });

  static const viewAllKey = ValueKey('home-jobs-view-all');

  /// How many jobs Home shows before "View all".
  static const limit = 3;

  final VoidCallback onViewAll;

  /// Offline: opens the CVs saved on the device.
  final VoidCallback? onOpenSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final feed = ref.watch(homeLatestJobsProvider(english));
    final items = feed.value?.items ?? const [];
    final error = feed.isLoading ? null : feed.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.homeJobsTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            HomeViewAllButton(key: viewAllKey, onPressed: onViewAll),
          ],
        ),
        const SizedBox(height: 8),
        if (feed.isLoading && !feed.hasValue)
          const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          _JobsLoadError(
            offline:
                error is ApiException && error.type == ApiErrorType.network,
            onRetry: () => ref.invalidate(homeLatestJobsProvider(english)),
            onOpenSaved: onOpenSaved,
          )
        else if (items.isEmpty)
          Text(l.homeJobsEmpty, style: TextStyle(color: c.textSecondary))
        else
          for (final item in items.take(limit))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobNewsCard(
                item: item,
                english: english,
                compact: true,
                onTap: () => unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JobNewsDetailScreen(item: item),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Compact load failure for the Home section: what went wrong, Retry, and
/// offline, the CVs saved on the device.
class _JobsLoadError extends StatelessWidget {
  const _JobsLoadError({
    required this.offline,
    required this.onRetry,
    required this.onOpenSaved,
  });

  final bool offline;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSaved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offline ? l.sharedErrorNetworkSubtitle : l.jobsLoadFailed,
          style: TextStyle(color: c.textSecondary),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.retry),
              style: TextButton.styleFrom(
                foregroundColor: c.primaryInk,
                minimumSize: const Size(48, 48),
              ),
            ),
            if (offline && onOpenSaved != null)
              TextButton.icon(
                onPressed: onOpenSaved,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: Text(l.sharedOfflineOpenSaved),
                style: TextButton.styleFrom(
                  foregroundColor: c.primaryInk,
                  minimumSize: const Size(48, 48),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
