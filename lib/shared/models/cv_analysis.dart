import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';

class CvAnalysis {
  final int id;
  final String targetJobTitle;
  final String? originalFilename;
  final String inputMethod;
  final int scoreTotal;
  final bool hasScore;

  /// True only when [jobMatch] was measured against a job description; the
  /// server sends `job_match: null` otherwise (issue #16).
  final bool hasJobMatch;
  final bool hasKeywordSummary;
  final String grade;
  final int jobMatch;
  final List<ScoreCriterion> criteria;
  final List<String> strengths;
  final List<AnalysisWeakness> weaknesses;
  final List<String> keywordsFound;
  final List<String> keywordsMissing;
  final List<String> quickWins;
  final String aiStatus;
  final Map<String, dynamic>? aiFeedback;
  final String? aiError;
  final String? category;
  final String? categoryLabel;
  final String? categoryLabelEn;
  final bool isGeneralProfile;

  /// 'job_description' when the score was computed against the pasted JD,
  /// 'category' when it fell back to the hardcoded category keyword list.
  /// Drives the badge shown next to the category chip (SIRATI-90).
  final String keywordSource;
  final String? classificationWarning;

  /// Items the server trimmed from each list (free tier); all zero when
  /// nothing is hidden.
  final AnalysisHiddenCounts hidden;
  final DateTime? createdAt;

  const CvAnalysis({
    required this.id,
    required this.targetJobTitle,
    required this.originalFilename,
    required this.inputMethod,
    required this.scoreTotal,
    this.hasScore = true,
    this.hasJobMatch = true,
    this.hasKeywordSummary = true,
    required this.grade,
    required this.jobMatch,
    this.category = 'general',
    this.categoryLabel,
    this.categoryLabelEn,
    this.isGeneralProfile = false,
    this.keywordSource = 'category',
    this.classificationWarning,
    this.hidden = AnalysisHiddenCounts.none,
    required this.criteria,
    required this.strengths,
    required this.weaknesses,
    required this.keywordsFound,
    required this.keywordsMissing,
    required this.quickWins,
    required this.aiStatus,
    required this.aiFeedback,
    required this.aiError,
    required this.createdAt,
  });

  factory CvAnalysis.fromJson(Map<String, dynamic> json) {
    final keywordSource =
        json['keyword_source']?.toString() == 'job_description'
            ? 'job_description'
            : 'category';
    return CvAnalysis(
      id: _asInt(json['id']),
      targetJobTitle: json['target_job_title']?.toString() ?? '',
      originalFilename: json['original_filename']?.toString(),
      inputMethod: json['input_method']?.toString() ?? 'paste',
      scoreTotal: _asInt(json['score_total']),
      hasScore: _hasPercentage(json['score_total']),
      hasJobMatch: keywordSource == 'job_description' &&
          _hasPercentage(json['job_match']),
      hasKeywordSummary:
          json['keywords_found'] is List && json['keywords_missing'] is List,
      grade: json['grade']?.toString() ?? '-',
      jobMatch: _asInt(json['job_match']),
      category: json['category']?.toString() ?? 'general',
      categoryLabel: json['category_label']?.toString(),
      categoryLabelEn: json['category_label_en']?.toString(),
      isGeneralProfile:
          json['is_general_profile'] == true || (json['category'] == 'general'),
      keywordSource: keywordSource,
      classificationWarning: json['classification_warning']?.toString(),
      hidden: AnalysisHiddenCounts.fromAccess(json['access']),
      criteria: _asList(json['criteria']).map(ScoreCriterion.fromJson).toList(),
      strengths: _asStringList(json['strengths']),
      weaknesses: _asList(
        json['weaknesses'],
      ).map(AnalysisWeakness.fromJson).toList(),
      keywordsFound: _asStringList(json['keywords_found']),
      keywordsMissing: _asStringList(json['keywords_missing']),
      quickWins: _asStringList(json['quick_wins']),
      aiStatus: json['ai_status']?.toString() ?? AiStatus.notConfigured,
      aiFeedback: json['ai_feedback'] is Map<String, dynamic>
          ? json['ai_feedback'] as Map<String, dynamic>
          : null,
      aiError: json['ai_error']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  /// The scoring category in the content language: the server's label, the
  /// catalog label for the general profile, or null when there is neither.
  String? displayCategoryLabel(AppLocalizations l, {required bool english}) {
    final label = (english ? categoryLabelEn : categoryLabel)?.trim();
    if (label != null && label.isNotEmpty) return label;
    if (category == null || category == 'general') return l.atsCategoryGeneral;
    return null;
  }
}

/// Counts from the server's `access.hidden` block.
class AnalysisHiddenCounts {
  final int strengths;
  final int weaknesses;
  final int keywordsMissing;
  final int quickWins;
  final int aiFeedback;

  const AnalysisHiddenCounts({
    this.strengths = 0,
    this.weaknesses = 0,
    this.keywordsMissing = 0,
    this.quickWins = 0,
    this.aiFeedback = 0,
  });

  static const none = AnalysisHiddenCounts();

  factory AnalysisHiddenCounts.fromAccess(Object? access) {
    final hidden = access is Map ? access['hidden'] : null;
    if (hidden is! Map) return none;
    int count(String key) {
      final value = _asInt(hidden[key]);
      return value > 0 ? value : 0;
    }

    return AnalysisHiddenCounts(
      strengths: count('strengths'),
      weaknesses: count('weaknesses'),
      keywordsMissing: count('keywords_missing'),
      quickWins: count('quick_wins'),
      aiFeedback: count('ai_feedback'),
    );
  }
}

class ScoreCriterion {
  /// Stable backend key (format, keywords, ...); empty for older saved analyses.
  final String key;
  final String label;
  final int score;
  final int max;

  const ScoreCriterion({
    this.key = '',
    required this.label,
    required this.score,
    required this.max,
  });

  factory ScoreCriterion.fromJson(Map<String, dynamic> json) {
    return ScoreCriterion(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      score: _asInt(json['score']),
      max: _asInt(json['max'], fallback: 1),
    );
  }
}

class AnalysisWeakness {
  final String priority;
  final String issue;
  final String fix;

  const AnalysisWeakness({
    required this.priority,
    required this.issue,
    required this.fix,
  });

  factory AnalysisWeakness.fromJson(Map<String, dynamic> json) {
    return AnalysisWeakness(
      priority: json['priority']?.toString() ?? '',
      issue: json['issue']?.toString() ?? '',
      fix: json['fix']?.toString() ?? '',
    );
  }
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.isFinite ? value.round() : fallback;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

// Missing percentages must remain distinguishable from a measured zero.
bool _hasPercentage(Object? raw) {
  final value = num.tryParse(raw?.toString() ?? '');
  return value != null && value.isFinite && value >= 0 && value <= 100;
}
