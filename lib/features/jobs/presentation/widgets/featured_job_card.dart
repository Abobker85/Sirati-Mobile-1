import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_apply_actions.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_format.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Hero for the newest posting that has a real application link (the feed
/// only offers one when that holds). The card opens the details; the button
/// opens the employer's page, whose site is named under it.
class FeaturedJobCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final destination = ApplyDestination.of(item);
    final meta = jobMetaLine(item, english: english);
    final published =
        jobPublishedText(item, AppLocalizations.of(context), english: english);
    final onHero = c.onBrandSurface;

    return PressScale(
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        // The card's tap (details) and the Apply button are siblings, not
        // nested, so each is its own target for touch and screen readers.
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              // brandSurface, not primary: white text needs a dark fill in
              // both themes (primary -> white is ~2.8:1 light, ~2:1 dark).
              colors: [c.brandSurface, c.brandSurfaceDeep],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onTap,
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
                          _HeroTag(label: l.jobsNewBadge),
                          if (jobSourceTypeLabel(l, item) case final label?)
                            _HeroTag(
                                label: label, icon: jobSourceTypeIcon(item)),
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
                          color: onHero,
                        ),
                      ),
                      if (meta.isNotEmpty || published.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          [meta, published]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5, height: 1.45, color: onHero),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: onHero,
                          foregroundColor: c.onWhitePill,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      Text(
                        l.jobsApplyOpensHost(ltrIsolate(displayHost)),
                        style: TextStyle(fontSize: 12.5, color: onHero),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.brandSurfaceDeep,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.onBrandSurface.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.onBrandSurface),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.onBrandSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
