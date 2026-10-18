/// A job the user wants to tailor a CV for; pre-fills the generator's target
/// title and job description.
class CvTargetJob {
  /// Mirrors GeneratedCvController limits (`target_job_title` max 160,
  /// `job_description` max 4000) so a prefilled form never starts invalid.
  static const titleMax = 160;
  static const descriptionMax = 4000;

  CvTargetJob({
    required String title,
    required String description,
    this.handBackResult = false,
  })  : title = _clip(title, titleMax),
        description = _clip(description, descriptionMax);

  final String title;
  final String description;

  /// When true the generator pops with the created `GeneratedCv` instead of
  /// opening its preview, so the opener can continue its own flow.
  final bool handBackResult;

  /// Trims and cuts at [max] characters without splitting a surrogate pair.
  static String _clip(String raw, int max) {
    final text = raw.trim();
    if (text.length <= max) return text;
    var end = max;
    final unit = text.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) end -= 1; // lone high surrogate
    return text.substring(0, end).trimRight();
  }
}
