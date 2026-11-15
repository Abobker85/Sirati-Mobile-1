import 'package:sirati/l10n/generated/app_localizations.dart';

/// A Premium feature a free user ran into. It picks the headline of the
/// Premium prompt and the Premium page, and which benefit is listed first.
enum PremiumFeature {
  download,
  aiWriting,
  fullAnalysis,
  jobMatch,
  dailyCvLimit,
  dailyAnalysisLimit,
  general;

  /// From the `feature` of a 402 (`SubscriptionRequiredException`).
  /// Anything unknown is [general], so a new server feature still lands on
  /// the Premium page.
  static PremiumFeature fromServer(String? feature) => switch (feature) {
        'cv_download' => download,
        'ai_enhancement' => aiWriting,
        'daily_cv_quota' => dailyCvLimit,
        'daily_analysis_quota' => dailyAnalysisLimit,
        final f? when f.startsWith('job_match') => jobMatch,
        _ => general,
      };

  String title(AppLocalizations l) => switch (this) {
        download => l.premiumFeatureDownloadTitle,
        aiWriting => l.premiumFeatureAiTitle,
        fullAnalysis => l.premiumFeatureAnalysisTitle,
        jobMatch => l.premiumFeatureJobMatchTitle,
        dailyCvLimit => l.premiumFeatureCvLimitTitle,
        dailyAnalysisLimit => l.premiumFeatureAnalysisLimitTitle,
        general => l.premiumGateHeroTitle,
      };

  String body(AppLocalizations l) => switch (this) {
        download => l.premiumFeatureDownloadBody,
        aiWriting => l.premiumFeatureAiBody,
        fullAnalysis => l.premiumFeatureAnalysisBody,
        jobMatch => l.premiumFeatureJobMatchBody,
        dailyCvLimit => l.premiumFeatureCvLimitBody,
        dailyAnalysisLimit => l.premiumFeatureAnalysisLimitBody,
        general => l.premiumGateHeroBody,
      };
}
