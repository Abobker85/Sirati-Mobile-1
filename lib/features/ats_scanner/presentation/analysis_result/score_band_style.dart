import 'package:flutter/material.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Maps pure score bands to palette colours and copy.
extension ScoreBandStyle on ScoreBand {
  Color color(SiratiColors c) => switch (this) {
        ScoreBand.excellent => c.tealDark,
        ScoreBand.veryGood => c.primary,
        ScoreBand.fair => c.amber,
        ScoreBand.weak => c.red,
      };

  /// Badge fill for the score, paired with [onContainer] (a gated AA pair
  /// in both themes). [color] is a fill/accent tone and fails AA as text.
  Color container(SiratiColors c) => switch (this) {
        ScoreBand.excellent => c.successLight,
        ScoreBand.veryGood => c.primaryLight,
        ScoreBand.fair => c.warningLight,
        ScoreBand.weak => c.errorLight,
      };

  Color onContainer(SiratiColors c) => switch (this) {
        ScoreBand.excellent => c.onSuccessContainer,
        ScoreBand.veryGood => c.primaryInk,
        ScoreBand.fair => c.onWarningContainer,
        ScoreBand.weak => c.onErrorContainer,
      };

  /// Shape cue for the band, so it never rests on colour alone.
  IconData get icon => switch (this) {
        ScoreBand.excellent => Icons.verified_rounded,
        ScoreBand.veryGood => Icons.thumb_up_alt_rounded,
        ScoreBand.fair => Icons.trending_up_rounded,
        ScoreBand.weak => Icons.priority_high_rounded,
      };

  String description(AppLocalizations l) => switch (this) {
        ScoreBand.excellent => l.atsBandExcellent,
        ScoreBand.veryGood => l.atsBandVeryGood,
        ScoreBand.fair => l.atsBandFair,
        ScoreBand.weak => l.atsBandWeak,
      };
}

extension CriterionBandStyle on CriterionBand {
  /// Bar fill (a graphic, not text).
  Color color(SiratiColors c) => switch (this) {
        CriterionBand.strong => c.teal,
        CriterionBand.good => c.primary,
        CriterionBand.needsWork => c.amber,
      };

  /// Shape cue next to the percentage, so the band never rests on colour
  /// alone.
  IconData get icon => switch (this) {
        CriterionBand.strong => Icons.check_circle_rounded,
        CriterionBand.good => Icons.trending_up_rounded,
        CriterionBand.needsWork => Icons.error_outline_rounded,
      };

  /// Percentage chip: gated container / on-container pairs.
  Color container(SiratiColors c) => switch (this) {
        CriterionBand.strong => c.successLight,
        CriterionBand.good => c.primaryLight,
        CriterionBand.needsWork => c.warningLight,
      };

  Color onContainer(SiratiColors c) => switch (this) {
        CriterionBand.strong => c.onSuccessContainer,
        CriterionBand.good => c.primaryInk,
        CriterionBand.needsWork => c.onWarningContainer,
      };
}
