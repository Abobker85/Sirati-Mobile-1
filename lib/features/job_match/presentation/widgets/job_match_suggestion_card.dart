import 'package:flutter/material.dart';
import 'package:sirati/features/job_match/domain/job_match.dart';
import 'package:sirati/features/job_match/presentation/job_match_messages.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// One proposed edit with its before/after, reason and selection state.
class JobMatchSuggestionCard extends StatelessWidget {
  const JobMatchSuggestionCard({
    super.key,
    required this.suggestion,
    required this.selected,
    required this.applied,
    required this.enabled,
    required this.onToggle,
    required this.factConfirmed,
    required this.onConfirmFact,
  });

  final JobMatchSuggestion suggestion;
  final bool selected;
  final bool applied;

  /// False while an apply is in flight.
  final bool enabled;
  final VoidCallback onToggle;
  final bool factConfirmed;
  final ValueChanged<bool> onConfirmFact;

  static Key checkboxKey(String suggestionKey) =>
      ValueKey('jm-suggestion-$suggestionKey');

  static Key confirmationKey(String suggestionKey) =>
      ValueKey('jm-confirm-fact-$suggestionKey');

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l = AppLocalizations.of(context);
    final canToggle = suggestion.canApply(factConfirmed: factConfirmed) &&
        !applied &&
        enabled;
    final before = suggestion.before;

    return JobMatchSection(
      highlighted: selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                key: checkboxKey(suggestion.key),
                value: selected || applied,
                onChanged: canToggle ? (_) => onToggle() : null,
              ),
              Expanded(
                child: Text(
                  l.jobMatchSection(suggestion.section),
                  style: AppTypography.of(context, AppTypography.titleSm),
                ),
              ),
              if (applied)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.successLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    child: Text(
                      l.jobMatchAppliedBadge,
                      style: AppTypography.of(
                        context,
                        AppTypography.labelSm,
                        color: c.onSuccessContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (before != null) ...[
            _DiffBox(
              label: l.jobMatchBefore,
              text: before,
              background: c.errorLight,
              foreground: c.onErrorContainer,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          _DiffBox(
            label: before == null ? l.jobMatchAddition : l.jobMatchAfter,
            text: suggestion.after,
            background: c.successLight,
            foreground: c.onSuccessContainer,
          ),
          if (suggestion.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.jobMatchWhy,
              style: AppTypography.of(
                context,
                AppTypography.labelMd,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            JobMatchContentText(suggestion.rationale),
          ],
          if (suggestion.jdTerms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.jobMatchTargets,
              style: AppTypography.of(
                context,
                AppTypography.labelMd,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            JobMatchKeywordWrap(
              terms: suggestion.jdTerms,
              kind: JobMatchKeywordKind.neutral,
            ),
          ],
          if (suggestion.needsUserFact) ...[
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: c.surface,
              child: CheckboxListTile(
                key: confirmationKey(suggestion.key),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: factConfirmed || applied,
                onChanged:
                    enabled && !applied && suggestion.after.trim().isNotEmpty
                        ? (value) => onConfirmFact(value ?? false)
                        : null,
                title: Text(
                  l.jm4ConfirmFact,
                  style: AppTypography.of(context, AppTypography.bodyMd),
                ),
                subtitle: Text(
                  l.jm4HonestyHint,
                  style: AppTypography.of(
                    context,
                    AppTypography.bodySm,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiffBox extends StatelessWidget {
  const _DiffBox({
    required this.label,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: AppTypography.of(
                context,
                AppTypography.labelMd,
                color: foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            JobMatchContentText(
              text,
              style: AppTypography.of(
                context,
                AppTypography.bodyMd,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
