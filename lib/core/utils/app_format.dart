import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

/// Locale-aware display formatting (relative time, digit shapes).
///
/// Words come from the label catalog ([AppLocalizations]).
class AppFormat {
  AppFormat._();

  /// Always returns Latin digits (0-9) across both locales (SIRATI-63).
  static String digits(Object value, {required bool english}) {
    final s = value is String ? value : value.toString();
    return s;
  }

  /// Relative time for lists, banners, and history, in [l10n]'s language
  /// ("just now", "5 min ago", "yesterday", …) or a short date.
  static String relativeTime(
    DateTime when,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final local = when.isUtc ? when.toLocal() : when;
    var seconds = n.difference(local).inSeconds;
    if (seconds < 0) seconds = 0;

    if (seconds < 45) return l10n.timeJustNow;

    final minutes = (seconds / 60).round();
    if (minutes < 60) return l10n.timeMinutesAgo(minutes < 1 ? 1 : minutes);

    final hours = (minutes / 60).round();
    if (hours < 24) return l10n.timeHoursAgo(hours);

    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(local.year, local.month, local.day);
    if (today.difference(day).inDays == 1) return l10n.timeYesterday;

    return shortDate(local, english: AppLocale.isEnglishCode(l10n.localeName));
  }

  /// Compact `d/M/yyyy` with locale-appropriate digits.
  static String shortDate(DateTime date, {required bool english}) {
    final local = date.isUtc ? date.toLocal() : date;
    final raw = '${local.day}/${local.month}/${local.year}';
    return digits(raw, english: english);
  }

  /// Western digits → Eastern Arabic digits (٠١٢…).
  static String toEasternArabicDigits(String input) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final i = western.indexOf(ch);
      buf.write(i >= 0 ? eastern[i] : ch);
    }
    return buf.toString();
  }
}
