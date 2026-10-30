import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/models/ai_status.dart';

/// A Job Match result (`JobMatchResource`).
///
/// The deterministic score, keywords and gaps exist as soon as the match is
/// created; [feedback] (AI advice and suggestions) arrives later, tracked by
/// [aiStatus].
class JobMatch {
  const JobMatch({
    required this.id,
    required this.generatedCvId,
    required this.appliedGeneratedCvId,
    required this.targetJobTitle,
    required this.language,
    required this.scoreTotal,
    required this.grade,
    required this.coverage,
    required this.keywordsFound,
    required this.keywordsMissing,
    required this.strengths,
    required this.weaknesses,
    required this.aiStatus,
    required this.feedback,
    required this.aiError,
    required this.appliedSuggestionKeys,
  });

  final int id;
  final int generatedCvId;
  final int? appliedGeneratedCvId;
  final String targetJobTitle;
  final String language;
  final int scoreTotal;
  final String grade;

  /// Keyword coverage of the job description, 0–100 (`job_match`).
  final int? coverage;
  final List<String> keywordsFound;
  final List<String> keywordsMissing;
  final List<String> strengths;
  final List<JobMatchWeakness> weaknesses;
  final String aiStatus;
  final JobMatchFeedback? feedback;
  final String? aiError;
  final Set<String> appliedSuggestionKeys;

  bool get aiPending => AiStatus.isPending(aiStatus);

  List<JobMatchSuggestion> get suggestions => feedback?.suggestions ?? const [];

  factory JobMatch.fromJson(Map<String, dynamic> json) {
    final feedback = json['ai_feedback'];
    return JobMatch(
      id: _asInt(json['id']),
      generatedCvId: _asInt(json['generated_cv_id']),
      appliedGeneratedCvId: _asNullableInt(json['applied_generated_cv_id']),
      targetJobTitle: json['target_job_title']?.toString() ?? '',
      language: AppLocale.contentLanguageOf(json['language']),
      scoreTotal: _asInt(json['score_total']).clamp(0, 100),
      grade: json['grade']?.toString() ?? '',
      coverage: _asNullableInt(json['job_match'])?.clamp(0, 100),
      keywordsFound: _strings(json['keywords_found']),
      keywordsMissing: _strings(json['keywords_missing']),
      strengths: _strings(json['strengths']),
      weaknesses: _maps(json['weaknesses'])
          .map(JobMatchWeakness.fromJson)
          .where((w) => w.issue.isNotEmpty)
          .toList(),
      aiStatus: json['ai_status']?.toString() ?? AiStatus.notConfigured,
      feedback: feedback is Map
          ? JobMatchFeedback.fromJson(Map<String, dynamic>.from(feedback))
          : null,
      aiError: _nullableString(json['ai_error']),
      appliedSuggestionKeys: _strings(json['applied_suggestion_ids']).toSet(),
    );
  }
}

class JobMatchWeakness {
  const JobMatchWeakness({
    required this.priority,
    required this.issue,
    required this.fix,
  });

  final String priority;
  final String issue;
  final String fix;

  factory JobMatchWeakness.fromJson(Map<String, dynamic> json) =>
      JobMatchWeakness(
        priority: json['priority']?.toString() ?? '',
        issue: json['issue']?.toString().trim() ?? '',
        fix: json['fix']?.toString().trim() ?? '',
      );
}

class JobMatchFeedback {
  const JobMatchFeedback({
    required this.executiveSummary,
    required this.strengths,
    required this.gaps,
    required this.suggestions,
  });

  final String executiveSummary;
  final List<String> strengths;
  final List<String> gaps;
  final List<JobMatchSuggestion> suggestions;

  factory JobMatchFeedback.fromJson(Map<String, dynamic> json) {
    final seen = <String>{};
    return JobMatchFeedback(
      executiveSummary: json['executive_summary']?.toString().trim() ?? '',
      strengths: _strings(json['strengths']),
      gaps: _strings(json['gaps']),
      // Keys identify suggestions on apply; drop keyless or duplicate ones so
      // a selection can never be ambiguous.
      suggestions: _maps(json['suggestions'])
          .map(JobMatchSuggestion.fromJson)
          .where((s) => s.key.isNotEmpty && seen.add(s.key))
          .toList(),
    );
  }
}

/// One proposed CV edit. [before] is null when the edit adds new text.
class JobMatchSuggestion {
  const JobMatchSuggestion({
    required this.key,
    required this.section,
    required this.before,
    required this.after,
    required this.rationale,
    required this.jdTerms,
    required this.needsUserFact,
  });

  final String key;
  final String section;
  final String? before;
  final String after;
  final String rationale;
  final List<String> jdTerms;

  /// The edit depends on a fact only the user knows (dates, numbers,
  /// employers); applying it requires explicit user confirmation.
  final bool needsUserFact;

  /// Whether the user may select this suggestion for automatic apply.
  bool get selectable => canApply(factConfirmed: false);
  bool canApply({required bool factConfirmed}) =>
      after.trim().isNotEmpty && (!needsUserFact || factConfirmed);

  factory JobMatchSuggestion.fromJson(Map<String, dynamic> json) {
    final target = json['target'];
    final before = _nullableString(json['before']);
    return JobMatchSuggestion(
      key: json['key']?.toString().trim() ?? '',
      section: target is Map ? target['section']?.toString() ?? '' : '',
      before: before == null || before.trim().isEmpty ? null : before,
      after: json['after']?.toString() ?? '',
      rationale: json['rationale']?.toString().trim() ?? '',
      jdTerms: _strings(json['jd_terms']),
      // Only an explicit false allows applying without confirmation.
      // Missing or malformed metadata requires the user's confirmation.
      needsUserFact: json['needs_user_fact'] != false,
    );
  }
}

List<String> _strings(dynamic value) => value is List
    ? value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList()
    : const [];

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];

String? _nullableString(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int _asInt(dynamic value) => _asNullableInt(value) ?? 0;

int? _asNullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}
