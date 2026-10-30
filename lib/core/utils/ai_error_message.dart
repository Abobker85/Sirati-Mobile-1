import 'package:sirati/l10n/generated/app_localizations.dart';

/// Maps machine-readable AI error codes onto catalog labels.
///
/// Backend [AiTruncationException] prefixes the stored `ai_error` with
/// [tooLongCode] so every surface can name CV length as the cause in the
/// active language, instead of interpolating the raw exception string.
class AiErrorMessage {
  static const tooLongCode = 'cv_too_long';

  static bool isTooLong(String? error) =>
      error != null && error.startsWith(tooLongCode);

  static String describe(String? error, AppLocalizations l10n) {
    if (isTooLong(error)) return l10n.aiErrorTooLong;
    if (error == null || error.trim().isEmpty) return l10n.aiErrorTryAgain;
    return error;
  }

  static String generationFailed(String? error, AppLocalizations l10n) =>
      isTooLong(error)
          ? l10n.aiErrorTooLong
          : l10n.aiGenerationFailed(describe(error, l10n));

  static String suggestionsFailed(String? error, AppLocalizations l10n) =>
      isTooLong(error)
          ? l10n.aiErrorTooLong
          : l10n.aiSuggestionsFailed(describe(error, l10n));

  static String localFallback(String? error, AppLocalizations l10n) =>
      isTooLong(error)
          ? l10n.aiErrorTooLong
          : l10n.aiLocalFallback(describe(error, l10n));
}
