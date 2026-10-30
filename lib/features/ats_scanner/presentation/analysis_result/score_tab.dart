import 'package:flutter/material.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/keyword_group.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/keyword_source_badge.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/recommendations_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_band_style.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/animated_ats_score_bar.dart';

/// First tab: score hero, per-criterion breakdown, and keyword coverage.
class ScoreTab extends StatelessWidget {
  const ScoreTab({
    super.key,
    required this.analysis,
    required this.english,
    this.trailing,
  });

  final CvAnalysis analysis;
  final bool english;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('analysis-score-tab-list'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _ScoreHero(analysis: analysis, english: english),
        const SizedBox(height: 24),
        if (analysis.hasKeywordSummary)
          Text(
            AppLocalizations.of(context).atsResultKeywordSummary(
              analysis.keywordsFound.length,
              analysis.keywordsMissing.length,
            ),
            key: const ValueKey('ats-result-keyword-summary'),
            style: TextStyle(color: context.sirati.textSecondary),
          ),
        const SizedBox(height: 24),
        SectionTitle(AppLocalizations.of(context).atsCriteriaDetails),
        const SizedBox(height: 12),
        _CriteriaCard(criteria: analysis.criteria),
        const SizedBox(height: 24),
        if (analysis.hasKeywordSummary)
          SectionTitle(AppLocalizations.of(context).atsKeywordsTitle),
        const SizedBox(height: 12),
        if (analysis.hasKeywordSummary)
          _KeywordsCard(
            found: analysis.keywordsFound,
            missing: analysis.keywordsMissing,
            english: english,
          ),
        if (analysis.hidden.keywordsMissing > 0) ...[
          const SizedBox(height: 8),
          HiddenItemsNote(count: analysis.hidden.keywordsMissing),
        ],
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.analysis, required this.english});

  final CvAnalysis analysis;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final band = ScoreBand.of(analysis.scoreTotal);
    final scoreColor = band.onContainer(c);
    final jobMatch = analysis.jobMatch.clamp(0, 100);
    final category = analysis.displayCategoryLabel(
      AppLocalizations.of(context),
      english: english,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          if (analysis.hasScore) ...[
            AnimatedScoreRing(
              score: analysis.scoreTotal,
              scoreColor: scoreColor,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: band.container(c),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppLocalizations.of(context)
                    .atsGradeLabel(AtsGrade.of(analysis.scoreTotal).label),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: band.onContainer(c),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              band.description(AppLocalizations.of(context)),
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ] else
            Text(
              AppLocalizations.of(context).homeHeroScoreUnavailable,
              style: TextStyle(color: c.textSecondary),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 16,
                color: c.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.targetJobTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (analysis.hasJobMatch) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$jobMatch%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.primaryInk,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (analysis.hasJobMatch) ...[
            const SizedBox(height: 8),
            AnimatedAtsScoreBar(
              value: jobMatch / 100,
              color: c.primaryInk,
              trackColor: c.surface,
              height: 7,
              borderRadius: 6,
              // Primary score: haptic the moment the elastic fill settles.
              celebrateOnComplete: true,
              semanticLabel: AppLocalizations.of(context).atsJobMatchSemantic,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                AppLocalizations.of(context).atsJobMatchPercentage,
                style: TextStyle(fontSize: 11, color: c.textHint),
              ),
            ),
          ],
          if (category != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 14, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).atsBenchmark(category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          KeywordSourceBadge(
            keywordSource: analysis.keywordSource,
            english: english,
          ),
        ],
      ),
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  const _CriteriaCard({required this.criteria});

  final List<ScoreCriterion> criteria;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < criteria.length; i++) ...[
            _CriterionRow(criterion: criteria[i]),
            if (i < criteria.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion});

  final ScoreCriterion criterion;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final ratio = criterionRatio(criterion.score, criterion.max);
    final criterionBand = CriterionBand.of(ratio);
    final barColor = criterionBand.onContainer(c);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _criterionLabel(AppLocalizations.of(context), criterion),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  '${criterion.score} / ${criterion.max}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: criterionBand.container(c),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${(ratio * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: criterionBand.onContainer(c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          AnimatedAtsScoreBar(
            value: ratio,
            color: barColor,
            trackColor: c.surface,
            height: 6,
            borderRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _KeywordsCard extends StatelessWidget {
  const _KeywordsCard({
    required this.found,
    required this.missing,
    required this.english,
  });

  final List<String> found;
  final List<String> missing;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KeywordHeading(
            dotColor: c.teal,
            textColor: c.tealDark,
            label: AppLocalizations.of(context).atsKeywordsFound(found.length),
          ),
          const SizedBox(height: 10),
          KeywordGroup(keywords: found, found: true, english: english),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          _KeywordHeading(
            dotColor: c.red,
            textColor: c.red,
            label:
                AppLocalizations.of(context).atsKeywordsMissing(missing.length),
          ),
          const SizedBox(height: 10),
          KeywordGroup(keywords: missing, found: false, english: english),
        ],
      ),
    );
  }
}

class _KeywordHeading extends StatelessWidget {
  const _KeywordHeading({
    required this.dotColor,
    required this.textColor,
    required this.label,
  });

  final Color dotColor;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Localized criterion name by its stable backend key; falls back to the
/// backend label for unknown keys and for analyses saved before keys existed.
String _criterionLabel(AppLocalizations l10n, ScoreCriterion criterion) {
  return switch (criterion.key) {
    'format' => l10n.atsCriterionFormat,
    'keywords' => l10n.atsCriterionKeywords,
    'structure' => l10n.atsCriterionStructure,
    'experience' => l10n.atsCriterionExperience,
    'education' => l10n.atsCriterionEducation,
    'summary' => l10n.atsCriterionSummary,
    'contact' => l10n.atsCriterionContact,
    _ => criterion.label,
  };
}
