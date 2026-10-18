import 'package:sirati/shared/models/cv_target_job.dart';

enum JobMatchInputError { descriptionEmpty, descriptionTooLong, titleTooLong }

/// Client-side limits mirroring the API (`job_description_input` max 4000,
/// `target_job_title` max 160). Checked before any request or
/// [CvTargetJob] is built, because [CvTargetJob] silently clips.
abstract final class JobMatchInput {
  static const descriptionMax = CvTargetJob.descriptionMax;
  static const titleMax = CvTargetJob.titleMax;

  /// Lengths are UTF-16 units — the unit [CvTargetJob] clips by and never
  /// fewer than the server's character count, so a passing input is never
  /// clipped and never rejected for length.
  static JobMatchInputError? validate({
    required String description,
    required String title,
  }) {
    final jd = description.trim();
    if (jd.isEmpty) return JobMatchInputError.descriptionEmpty;
    if (jd.length > descriptionMax) return JobMatchInputError.descriptionTooLong;
    if (title.trim().length > titleMax) return JobMatchInputError.titleTooLong;
    return null;
  }
}
