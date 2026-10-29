import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// "Jobs for you" on Home (Salem review, element 8): the first few jobs of
/// the feed, with a way to the full Jobs tab.
class DashboardJobsSection extends ConsumerWidget {
  const DashboardJobsSection({super.key, required this.onViewAll});

  static const viewAllKey = ValueKey('home-jobs-view-all');

  /// How many jobs Home shows before "View all".
  static const limit = 3;

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final feed = ref.watch(jobNewsFeedProvider(english));
    final items = feed.value?.items ?? const [];

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
            TextButton(
              key: viewAllKey,
              onPressed: onViewAll,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(l.homeJobsViewAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Loading and errors stay quiet here: the Jobs tab has the full
        // states and its own Retry.
        if (feed.isLoading && !feed.hasValue)
          const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          Text(l.homeJobsEmpty, style: TextStyle(color: c.textSecondary))
        else
          for (final item in items.take(limit))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: JobNewsCard(
                item: item,
                english: english,
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
