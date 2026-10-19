import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/job_match/domain/job_match.dart';
import 'package:sirati/features/job_match/domain/job_match_failure.dart';
import 'package:sirati/features/job_match/presentation/job_match_messages.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';

/// Score, keyword coverage, gaps and selectable edits for the match held by
/// [jobMatchControllerProvider]. Pushed by `JobMatchScreen`, which keeps the
/// controller alive underneath.
class JobMatchResultScreen extends ConsumerWidget {
  const JobMatchResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(jobMatchControllerProvider);
    final match = state.match;

    return Scaffold(
      appBar: AppBar(title: Text(l.jobMatchResultTitle)),
      body: match == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _ScoreCard(match: match),
                const SizedBox(height: AppSpacing.md),
                ..._statusBanner(context, ref, state, match),
                _KeywordsCard(match: match),
                const SizedBox(height: AppSpacing.md),
                ..._insights(context, match),
                ..._suggestions(context, ref, state, match),
                if (match.appliedGeneratedCvId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.cv(match.appliedGeneratedCvId!),
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(l.jobMatchOpenTailoredCv),
                  ),
                ],
              ],
            ),
      bottomNavigationBar:
          match == null ? null : _ApplyBar(state: state, match: match),
    );
  }

  List<Widget> _statusBanner(
    BuildContext context,
    WidgetRef ref,
    JobMatchState state,
    JobMatch match,
  ) {
    final l = AppLocalizations.of(context);
    final JobMatchNotice? notice;
    if (match.aiPending) {
      if (state.pollPhase == JobMatchPollPhase.polling) {
        notice = JobMatchNotice(
          tone: JobMatchTone.info,
          message: l.jobMatchAiPreparing,
          busy: true,
        );
      } else {
        final failure = state.refreshFailure;
        notice = JobMatchNotice(
          tone: JobMatchTone.warning,
          message: l.jobMatchAiStillProcessing,
          detail: failure == null ? null : l.jobMatchFailureMessage(failure),
          actionLabel: l.jobMatchCheckAgain,
          onAction: () =>
              ref.read(jobMatchControllerProvider.notifier).checkAgain(),
        );
      }
    } else if (match.aiStatus == AiStatus.failed) {
      notice = JobMatchNotice(
        tone: JobMatchTone.warning,
        message: l.jobMatchAiFailed,
        detail: state.retryFailure == null
            ? null
            : l.jobMatchFailureMessage(state.retryFailure!),
        actionLabel: l.jobMatchRetrySuggestions,
        busy: state.retryingAdvice,
        onAction: () =>
            ref.read(jobMatchControllerProvider.notifier).retryAdvice(),
      );
    } else if (match.aiStatus == AiStatus.notConfigured) {
      notice = JobMatchNotice(
        tone: JobMatchTone.info,
        message: l.jobMatchAiNotConfigured,
      );
    } else {
      notice = null;
    }
    if (notice == null) return const [];
    return [notice, const SizedBox(height: AppSpacing.md)];
  }

  List<Widget> _insights(BuildContext context, JobMatch match) {
    final l = AppLocalizations.of(context);
    final feedback = match.feedback;
    final strengths = (feedback?.strengths.isNotEmpty ?? false)
        ? feedback!.strengths
        : match.strengths;
    final gaps = (feedback?.gaps.isNotEmpty ?? false)
        ? feedback!.gaps
        : [
            for (final w in match.weaknesses)
              w.fix.isEmpty ? w.issue : '${w.issue}\n${w.fix}',
          ];
    final summary = feedback?.executiveSummary ?? '';
    return [
      if (summary.isNotEmpty) ...[
        JobMatchSection(
          title: l.jobMatchSummary,
          child: JobMatchContentText(summary),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (strengths.isNotEmpty) ...[
        JobMatchSection(
          title: l.jobMatchStrengths,
          child: JobMatchBulletList(items: strengths),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (gaps.isNotEmpty) ...[
        JobMatchSection(
          title: l.jobMatchGaps,
          child: JobMatchBulletList(items: gaps),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  List<Widget> _suggestions(
    BuildContext context,
    WidgetRef ref,
    JobMatchState state,
    JobMatch match,
  ) {
    if (match.feedback == null) return const [];
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final suggestions = match.suggestions;
    return [
      JobMatchSection(
        title: l.jobMatchSuggestionsTitle,
        child: Text(
          suggestions.isEmpty
              ? l.jobMatchNoSuggestions
              : l.jobMatchSuggestionsHint,
          style: AppTypography.of(
            context,
            AppTypography.bodySm,
            color: c.textSecondary,
          ),
        ),
      ),
      for (final suggestion in suggestions) ...[
        const SizedBox(height: AppSpacing.sm),
        JobMatchSuggestionCard(
          suggestion: suggestion,
          selected: state.selected.contains(suggestion.key),
          applied: match.appliedSuggestionKeys.contains(suggestion.key),
          enabled: !state.applying,
          onToggle: () => ref
              .read(jobMatchControllerProvider.notifier)
              .toggle(suggestion.key),
        ),
      ],
    ];
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.match});

  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final secondary = AppTypography.of(
      context,
      AppTypography.bodySm,
      color: c.textSecondary,
    );
    return JobMatchSection(
      child: Row(
        children: [
          JobMatchScoreRing(score: match.scoreTotal),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.jobMatchScoreLabel,
                  style: AppTypography.of(context, AppTypography.titleMd),
                ),
                if (match.targetJobTitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  JobMatchContentText(
                    match.targetJobTitle,
                    style: AppTypography.of(context, AppTypography.bodyMd),
                  ),
                ],
                if (match.grade.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l.jobMatchGrade(match.grade), style: secondary),
                ],
                if (match.coverage != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l.jobMatchCoverage(match.coverage!), style: secondary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordsCard extends StatelessWidget {
  const _KeywordsCard({required this.match});

  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return JobMatchSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.jobMatchMatchedKeywords,
            style: AppTypography.of(context, AppTypography.titleSm),
          ),
          const SizedBox(height: AppSpacing.xs),
          JobMatchKeywordWrap(
            key: const ValueKey('jm-keywords-matched'),
            terms: match.keywordsFound,
            kind: JobMatchKeywordKind.matched,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.jobMatchMissingKeywords,
            style: AppTypography.of(context, AppTypography.titleSm),
          ),
          const SizedBox(height: AppSpacing.xs),
          JobMatchKeywordWrap(
            key: const ValueKey('jm-keywords-missing'),
            terms: match.keywordsMissing,
            kind: JobMatchKeywordKind.missing,
          ),
        ],
      ),
    );
  }
}

class _ApplyBar extends ConsumerWidget {
  const _ApplyBar({required this.state, required this.match});

  final JobMatchState state;
  final JobMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelectable = match.suggestions.any(
      (s) => s.selectable && !match.appliedSuggestionKeys.contains(s.key),
    );
    if (!hasSelectable && !state.applying) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final Widget content;
    if (state.applying) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: c.primaryInk,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l.jobMatchApplying,
            style: AppTypography.of(context, AppTypography.labelLg),
          ),
        ],
      );
    } else if (state.selected.isEmpty) {
      content = Text(
        l.jobMatchSelectToApply,
        textAlign: TextAlign.center,
        style: AppTypography.of(
          context,
          AppTypography.bodySm,
          color: c.textSecondary,
        ),
      );
    } else {
      content = ElevatedButton(
        key: const ValueKey('jm-apply'),
        onPressed: () => _apply(context, ref),
        child: Text(l.jobMatchApplySelected(state.selected.length)),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: content,
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final outcome =
        await ref.read(jobMatchControllerProvider.notifier).apply();
    if (!context.mounted || outcome == null) return;
    switch (outcome) {
      case JobMatchApplied(:final cv):
        AppSnackBar.success(context, l.jobMatchAppliedSuccess);
        unawaited(navigator.pushNamed(AppRoutes.cv(cv.id), arguments: cv));
      case JobMatchApplyFailed(:final failure):
        if (failure.affectsEntitlement) {
          ref.invalidate(jobMatchEntitlementProvider);
        }
        if (failure.kind == JobMatchFailureKind.stale) {
          AppSnackBar.error(
            context,
            l.jobMatchFailureMessage(failure),
            actionLabel: l.jobMatchNewMatch,
            onAction: navigator.pop,
          );
        } else {
          AppSnackBar.error(context, l.jobMatchFailureMessage(failure));
        }
    }
  }
}
