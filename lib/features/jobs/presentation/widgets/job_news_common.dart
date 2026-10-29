import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class MetaChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool highlight;

  const MetaChip(
      {super.key, required this.text, this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final fg = highlight ? c.primaryInk : c.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? c.primaryLight : c.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? c.borderStrong : c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16, color: highlight ? c.primaryInk : c.textSecondary),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty results. With [regionLabel] it is the "no postings in this region"
/// state and offers all regions; otherwise it offers to clear the filters
/// when [onClearFilters] is set, or says the feed is empty.
class EmptyJobNews extends StatelessWidget {
  final bool english;
  final VoidCallback? onClearFilters;
  final String? regionLabel;
  final VoidCallback? onShowAllRegions;

  const EmptyJobNews({
    super.key,
    required this.english,
    this.onClearFilters,
    this.regionLabel,
    this.onShowAllRegions,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final region = regionLabel;
    final title = region != null
        ? l.jobsEmptyRegionTitle(region)
        : onClearFilters != null
            ? l.noMatchingJobs
            : l.jobsEmptyFeed;
    final action = region != null && onShowAllRegions != null
        ? (l.jobsShowAllRegions, onShowAllRegions!)
        : onClearFilters != null
            ? (l.clearFilters, onClearFilters!)
            : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  region != null
                      ? Icons.location_off_outlined
                      : Icons.work_off_outlined,
                  size: 34,
                  color: c.primaryInk,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd(c),
          ),
          if (region != null) ...[
            const SizedBox(height: 6),
            Text(
              l.jobsEmptyRegionBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: c.textSecondary),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: action.$2,
              style: FilledButton.styleFrom(
                backgroundColor: c.brandSurface,
                foregroundColor: c.onBrandSurface,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: Text(action.$1),
            ),
          ],
        ],
      ),
    );
  }
}
