import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_apply_actions.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_format.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_pressable_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Lead card for the newest posting that has a real application link (the
/// feed only offers one when that holds): a larger grey card that darkens and
/// springs while its details area is held. The card opens the details; the
/// teal Apply capsule opens the employer's page, whose site is named beside
/// it.
class FeaturedJobCard extends StatefulWidget {
  final JobNews item;
  final bool english;
  final VoidCallback onTap;

  const FeaturedJobCard({
    super.key,
    required this.item,
    required this.english,
    required this.onTap,
  });

  @override
  State<FeaturedJobCard> createState() => _FeaturedJobCardState();
}

class _FeaturedJobCardState extends State<FeaturedJobCard> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final english = widget.english;
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final destination = ApplyDestination.of(item);
    final meta = jobMetaLine(item, english: english);
    final published =
        jobPublishedText(item, AppLocalizations.of(context), english: english);

    return JobPressSurface(
      pressed: _pressed,
      focused: _focused,
      // The details tap and the Apply button are siblings, not nested, so
      // each is its own target for touch and screen readers.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JobCardInk(
            onTap: widget.onTap,
            onPressedChanged: (v) => setState(() => _pressed = v),
            onFocusChanged: (v) => setState(() => _focused = v),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      JobChip(label: l.jobsNewBadge, emphasis: true),
                      if (jobSourceTypeLabel(l, item) case final label?)
                        JobChip(
                          label: label,
                          icon: jobSourceTypeIcon(item),
                          fill:
                              PageSurface.pageColor(c, PageSurface.of(context)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  JobTitleDisplay(
                    title: item.title,
                    language: item.language,
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  if (meta.isNotEmpty || published.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      [meta, published].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.45, color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (destination case ApplyLink(:final displayHost))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => unawaited(
                        openJobApplication(context, item, destination)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(l.jobsApplyNow),
                    style: jobApplyButtonStyle(c).copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                      padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 20)),
                    ),
                  ),
                  Text(
                    l.jobsApplyOpensHost(ltrIsolate(displayHost)),
                    style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
