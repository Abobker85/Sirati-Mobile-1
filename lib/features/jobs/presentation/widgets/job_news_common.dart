import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';

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

    // The shared calm state; no card of its own.
    return AppEmptyState(
      icon: region != null
          ? Icons.location_off_outlined
          : Icons.work_off_outlined,
      title: title,
      subtitle: region != null ? l.jobsEmptyRegionBody : null,
      actionLabel: action?.$1,
      onAction: action?.$2,
      actionIcon: null,
      scrollable: false,
    );
  }
}
