import 'package:sirati/features/job_match/domain/job_match_failure.dart';
import 'package:sirati/features/job_match/domain/job_match_input.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

/// User-facing copy for Job Match failures and input errors.
extension JobMatchMessages on AppLocalizations {
  String jobMatchFailureMessage(JobMatchFailure failure) =>
      switch (failure.kind) {
        JobMatchFailureKind.subscriptionRequired => jobMatchErrorSubscription,
        JobMatchFailureKind.limitReached => jobMatchErrorLimit,
        JobMatchFailureKind.conflict => jobMatchErrorConflict,
        JobMatchFailureKind.stale => jobMatchErrorStale,
        JobMatchFailureKind.cvTooLong => jobMatchErrorCvTooLong,
        JobMatchFailureKind.invalidJobDescription =>
          jobMatchErrorInvalidDescription,
        JobMatchFailureKind.invalidSelection => jobMatchErrorInvalidSelection,
        JobMatchFailureKind.unavailable => jobMatchErrorUnavailable,
        JobMatchFailureKind.notFound => jobMatchErrorNotFound,
        JobMatchFailureKind.network => jobMatchErrorNetwork,
        JobMatchFailureKind.server ||
        JobMatchFailureKind.unknown =>
          jobMatchErrorUnknown,
      };

  String jobMatchInputMessage(JobMatchInputError error) => switch (error) {
        JobMatchInputError.descriptionEmpty => jobMatchDescriptionRequired,
        JobMatchInputError.descriptionTooLong =>
          jobMatchDescriptionTooLong(JobMatchInput.descriptionMax),
        JobMatchInputError.titleTooLong =>
          jobMatchTitleTooLong(JobMatchInput.titleMax),
      };

  /// Localized CV section name; unknown sections share one label.
  String jobMatchSection(String section) {
    const known = {
      'summary',
      'skills',
      'experience',
      'education',
      'certifications',
      'projects',
      'languages',
      'personal',
    };
    return jobMatchSectionName(known.contains(section) ? section : 'other');
  }
}
