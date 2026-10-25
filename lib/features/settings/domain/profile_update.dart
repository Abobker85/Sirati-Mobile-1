/// Limits of `PUT /auth/profile`, kept in line with
/// `MobileAuthController::updateProfile`.
abstract final class ProfileRules {
  static const nameMax = 255;
  static const jobTitleOtherMax = 120;
  static const locationMax = 120;

  /// Null when valid, otherwise whether it is missing or too long.
  static ProfileFieldError? name(String? value) =>
      _requiredWithin(value, nameMax);

  /// Optional: empty clears the saved location.
  static ProfileFieldError? location(String? value) =>
      (value?.trim().length ?? 0) > locationMax
          ? ProfileFieldError.tooLong
          : null;

  static ProfileFieldError? jobTitleOther(String? value,
          {required bool isOther}) =>
      isOther ? _requiredWithin(value, jobTitleOtherMax) : null;

  static ProfileFieldError? _requiredWithin(String? value, int max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return ProfileFieldError.required;
    return text.length > max ? ProfileFieldError.tooLong : null;
  }
}

enum ProfileFieldError { required, tooLong }

/// What the user did to their job title in this edit session.
sealed class JobTitleChange {
  const JobTitleChange();
}

/// Not touched: the request must not mention the job title, so the saved
/// value survives even when the picker couldn't show it (catalogue failed to
/// load, or the title was retired).
final class JobTitleUnchanged extends JobTitleChange {
  const JobTitleUnchanged();
}

final class JobTitleCleared extends JobTitleChange {
  const JobTitleCleared();
}

final class JobTitleSelected extends JobTitleChange {
  const JobTitleSelected(this.id, {this.otherText});
  final int id;

  /// Free text, only for the "Other" title.
  final String? otherText;
}

/// A validated profile edit.
class ProfileUpdate {
  ProfileUpdate({
    required String name,
    required this.jobTitle,
    String? location,
  })  : name = name.trim(),
        location = location?.trim();

  final String name;
  final JobTitleChange jobTitle;

  /// Null when the user did not touch it, so the saved value is kept;
  /// empty clears it.
  final String? location;
}
