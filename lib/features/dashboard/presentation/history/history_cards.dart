import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_band_style.dart';
import 'package:sirati/features/dashboard/domain/history_page.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/animated_ats_score_bar.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';

String _dateLabel(DateTime? date, AppLocalizations l10n) =>
    date == null ? '-' : AppFormat.relativeTime(date, l10n);

/// Score and grade in the band's container colours (AA in both themes).
/// The grade comes from the score's [AtsGrade], so it always matches the band.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final band = ScoreBand.of(score);
    final grade = AtsGrade.of(score).label;
    final english = AppLocale.isEnglish(context);
    return Semantics(
      label: AppLocalizations.of(context).dashboardScoreBadgeSemantics(
        score,
        grade,
      ),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: band.container(c),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormat.digits('$score', english: english),
              style: AppTypography.of(context, AppTypography.titleLg,
                  color: band.onContainer(c)),
            ),
            Text(
              grade,
              style: AppTypography.of(context, AppTypography.labelLg,
                  color: band.onContainer(c)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.of(context, AppTypography.bodySm,
            color: c.primaryInk),
      ),
    );
  }
}

/// Inside an [AppListSection] a history item is a flat row of the
/// section's white card (the press shows as a grey highlight); on its own
/// it is a grouped-white card with no border or shadow.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final row = InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      // The press darkens the white card, as AppContrast checks every ink
      // against.
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? c.pressed(c.groupedCard)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppListSection.rowPadding,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
    if (AppListSection.contains(context)) return row;
    return Material(
      color: c.groupedCard,
      borderRadius: AppRadius.cardAll,
      clipBehavior: Clip.antiAlias,
      child: row,
    );
  }
}

/// Icon box at the start of a history row; separators start past it.
const double historyIconBox = 40;

/// Separator start for history rows: under the text, past the icon box.
const double historySeparatorIndent =
    AppListSection.rowPadding + historyIconBox + AppListTileMetrics.gap;

class AnalysisHistoryCard extends StatelessWidget {
  const AnalysisHistoryCard({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  final CvAnalysis analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final c = context.sirati;
    final band = ScoreBand.of(analysis.scoreTotal);
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: historyIconBox,
                height: historyIconBox,
                decoration: BoxDecoration(
                  color: c.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.manage_search, size: 20, color: c.primaryInk),
              ),
              const SizedBox(width: AppListTileMetrics.gap),
              Expanded(
                child: Text(
                  LocaleFormat.mixedTitle(
                    analysis.targetJobTitle,
                    english: english,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.of(context, AppTypography.titleSm),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ScoreBadge(score: analysis.scoreTotal),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedAtsScoreBar(
            value: (analysis.scoreTotal / 100).clamp(0.0, 1.0),
            color: band.color(c),
            height: 5,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              _MetaChip(
                label: inputMethodLabel(
                  analysis.inputMethod,
                  AppLocalizations.of(context),
                ),
              ),
              Text(
                _dateLabel(analysis.createdAt, AppLocalizations.of(context)),
                style: AppTypography.of(context, AppTypography.bodySm,
                    color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GeneratedCvHistoryCard extends StatelessWidget {
  const GeneratedCvHistoryCard({
    super.key,
    required this.cv,
    required this.onTap,
  });

  final GeneratedCv cv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final c = context.sirati;
    final name = cv.fullName.trim();
    return _CardShell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: historyIconBox,
            height: historyIconBox,
            decoration: BoxDecoration(
              color: c.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: ExcludeSemantics(
                // Large text scales would overflow the fixed box and clip
                // the letter; shrink it to fit instead.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    BidiText.avatarInitial(name,
                        fallback:
                            AppLocalizations.of(context).avatarFallbackInitial),
                    style: AppTypography.of(context, AppTypography.titleLg,
                        color: c.primaryInk),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppListTileMetrics.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleFormat.mixedTitle(cv.fullName, english: english),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.of(context, AppTypography.titleSm),
                ),
                const SizedBox(height: 3),
                Text(
                  LocaleFormat.mixedTitle(cv.targetJobTitle, english: english),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.of(context, AppTypography.bodySm,
                      color: c.textSecondary),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // The CV's content language, named in the UI language
                    // (served from the label catalog).
                    _MetaChip(
                        label: AppLocale.isEnglishCode(cv.language)
                            ? AppLocalizations.of(context).languageEnglish
                            : AppLocalizations.of(context).languageArabic),
                    Text(
                      _dateLabel(cv.createdAt, AppLocalizations.of(context)),
                      style: AppTypography.of(context, AppTypography.bodySm,
                          color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ScoreBadge(score: cv.scoreTotal),
        ],
      ),
    );
  }
}

/// "Load more" / "Loading…" / "Retry" footer for a history list.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.loading,
    required this.failed,
    required this.onPressed,
  });

  final bool loading;
  final bool failed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = loading
        ? l10n.dashboardLoadMoreLoading
        : failed
            ? l10n.dashboardLoadMoreFailed
            : l10n.dashboardLoadMore;
    return TextButton(
      onPressed: loading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.sirati.primaryInk,
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(label),
    );
  }
}
