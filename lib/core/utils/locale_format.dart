import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/bidi_text.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

/// Locale-aware copy helpers (plurals, mixed labels, sample data fixes).
class LocaleFormat {
  LocaleFormat._();

  /// Item count label e.g. analyses / CVs chips.
  static String countNoun({
    required int count,
    required bool english,
    required String singularEn,
    required String pluralEn,
    required String singularAr,
    required String dualAr,
    required String fewAr, // 3–10
    required String manyAr, // 11+
  }) {
    if (english) {
      return count == 1 ? '$count $singularEn' : '$count $pluralEn';
    }
    if (count == 0) return 'لا $fewAr';
    if (count == 1) return '$singularAr واحد';
    if (count == 2) return dualAr;
    final n = AppFormat.digits(count, english: false);
    if (count >= 3 && count <= 10) return '$n $fewAr';
    return '$n $manyAr';
  }

  /// Display job / CV titles that may mix AR + EN; protect Latin runs in AR.
  /// Empty [title] shows [untitled] (a catalog label).
  static String mixedTitle(
    String title, {
    required bool english,
    String untitled = '',
  }) {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return untitled;
    if (english) return cleaned;
    return BidiText.protectLatinTokens(cleaned);
  }

  /// Body paragraphs (job descriptions, long copy) for stable BiDi.
  static String mixedBody(String body, {required bool english}) {
    if (body.isEmpty) return body;
    if (english) return body;
    return BidiText.protectLatinTokens(body);
  }

  /// Normalize common sample typos from demos / mocks.
  static String fixSampleTitle(String title) {
    return title
        .replaceAll(RegExp(r'applicaion', caseSensitive: false), 'Application')
        .replaceAll(RegExp(r'devloper', caseSensitive: false), 'Developer');
  }

  /// ATS badge label that stays stable in RTL layouts.
  static String atsBadge(String scoreLabel, {required bool english}) {
    final cleaned = scoreLabel.trim();
    if (cleaned.isEmpty) return cleaned;
    if (english) return cleaned;
    // e.g. "ATS 47%" → isolate ATS product token
    return BidiText.protectLatinTokens(cleaned);
  }

  /// Relative time for draft banners, e.g. "Saved 5 min ago".
  static String relativeSavedAt(
    DateTime savedAt,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final rel = AppFormat.relativeTime(savedAt, l10n, now: now);
    return rel == l10n.timeJustNow ? l10n.savedJustNow : l10n.savedAgo(rel);
  }

  /// Western digits → Eastern Arabic digits (٠١٢…).
  static String toEasternArabicDigits(String input) =>
      AppFormat.toEasternArabicDigits(input);
}
