import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';

/// Date labels shared by job cards and the detail screen.
/// Prefer computed relative time from [JobNews.publishedAt]; fall back to API label digits.
String jobPublishedText(
  JobNews item,
  AppLocalizations l10n, {
  required bool english,
}) {
  if (item.publishedAt != null) {
    return AppFormat.relativeTime(item.publishedAt!, l10n);
  }
  final label = item.publishedLabel?.trim() ?? '';
  if (label.isEmpty) return '';
  return AppFormat.digits(label, english: english);
}

/// A stated application deadline. The server labels curated listings only;
/// aggregated posts carry an internal retirement date that is not a deadline,
/// so without the label there is nothing to show.
String jobValidUntilText(JobNews item, {required bool english}) {
  if ((item.validUntilLabel ?? '').trim().isEmpty) return '';
  if (item.validUntil != null) {
    return AppFormat.shortDate(item.validUntil!, english: english);
  }
  final label = item.validUntilLabel?.trim() ?? '';
  if (label.isEmpty) return '';
  return AppFormat.digits(label, english: english);
}
