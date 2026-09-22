import 'package:flutter/material.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Maps pure score bands to palette colours and copy.
extension ScoreBandStyle on ScoreBand {
  Color color(SiratiColors c) => switch (this) {
        ScoreBand.excellent => c.tealDark,
        ScoreBand.veryGood => c.primary,
        ScoreBand.fair => c.amber,
        ScoreBand.weak => c.red,
      };

  Color track(SiratiColors c) => switch (this) {
        ScoreBand.excellent => c.tealLight,
        ScoreBand.veryGood => c.primaryLight,
        ScoreBand.fair => c.amberLight,
        ScoreBand.weak => c.redLight,
      };

  String description({required bool english}) => switch (this) {
        ScoreBand.excellent => english
            ? 'Excellent - your CV is strong and ready'
            : 'ممتاز - سيرتك قوية ومؤهلة',
        ScoreBand.veryGood => english
            ? 'Very good - a few improvements will help'
            : 'جيد جداً - مع بعض التحسينات',
        ScoreBand.fair =>
          english ? 'Fair - review and polish needed' : 'مقبول - يحتاج مراجعة',
        ScoreBand.weak =>
          english ? 'Weak - needs restructuring' : 'ضعيف - يحتاج إعادة هيكلة',
      };
}

extension CriterionBandStyle on CriterionBand {
  Color color(SiratiColors c) => switch (this) {
        CriterionBand.strong => c.teal,
        CriterionBand.good => c.primary,
        CriterionBand.needsWork => c.amber,
      };
}
