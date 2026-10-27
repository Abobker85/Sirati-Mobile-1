import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class MetaChip extends StatelessWidget {
  final String text;
  final bool highlight;

  const MetaChip({super.key, required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    if (!highlight) {
      return Chip(
        label: Text(
          text,
          style: const TextStyle(fontSize: 13),
        ),
      );
    }
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: context.sirati.primaryInk,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: context.sirati.primaryLight,
      side: BorderSide(color: context.sirati.borderStrong),
    );
  }
}

class EmptyJobNews extends StatelessWidget {
  final bool english;

  final VoidCallback? onClearFilters;

  const EmptyJobNews({super.key, required this.english, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sirati.border),
      ),
      child: Column(
        children: [
          Text(
            onClearFilters != null
                ? AppLocalizations.of(context).noMatchingJobs
                : AppLocalizations.of(context).jobsEmptyFeed,
            textAlign: TextAlign.center,
            style: AppTypography.of(context, AppTypography.bodyMd,
                color: context.sirati.textSecondary),
          ),
          if (onClearFilters != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onClearFilters,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: context.sirati.primaryInk,
              ),
              child: Text(AppLocalizations.of(context).clearFilters),
            ),
          ],
        ],
      ),
    );
  }
}
