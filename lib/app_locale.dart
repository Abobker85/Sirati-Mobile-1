import 'package:flutter/material.dart';

import 'services/analytics_service.dart';
import 'services/preference_store.dart';
import 'utils/bidi_text.dart';
import 'utils/locale_format.dart';

export 'utils/bidi_text.dart';
export 'utils/locale_format.dart';

class AppLocale {
  static final ValueNotifier<String> languageCode = ValueNotifier<String>(
    Uri.base.queryParameters['lang'] == 'en' ? 'en' : 'ar',
  );

  static const PreferenceStore _prefs = PreferenceStore();

  /// Load persisted language before [runApp].
  /// Priority: URL `?lang=` (web preview) → secure storage → Arabic default.
  static Future<void> bootstrap() async {
    final fromUrl = Uri.base.queryParameters['lang'];
    if (fromUrl == 'en' || fromUrl == 'ar') {
      languageCode.value = fromUrl!;
      return;
    }
    try {
      final stored = await _prefs.readLanguage();
      if (stored == 'en' || stored == 'ar') {
        languageCode.value = stored!;
      }
    } catch (_) {
      // Storage unavailable — keep default.
    }
  }

  static Locale get locale {
    return languageCode.value == 'en'
        ? const Locale('en', 'US')
        : const Locale('ar', 'SA');
  }

  static bool isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }

  static bool get isRtl => languageCode.value != 'en';

  static TextDirection direction(BuildContext context) {
    return isEnglish(context) ? TextDirection.ltr : TextDirection.rtl;
  }

  static TextDirection get currentDirection {
    return languageCode.value == 'en' ? TextDirection.ltr : TextDirection.rtl;
  }

  /// Prefer this over left/right — follows ambient [Directionality].
  static const TextAlign textStart = TextAlign.start;

  /// Prefer this over left/right alignment branches.
  static const CrossAxisAlignment crossStart = CrossAxisAlignment.start;

  /// Prefer this over centerLeft/centerRight.
  static const AlignmentGeometry alignCenterStart =
      AlignmentDirectional.centerStart;

  static const AlignmentGeometry alignCenterEnd =
      AlignmentDirectional.centerEnd;

  /// BiDi-safe greeting for header titles.
  static String greeting(String name, BuildContext context) {
    return BidiText.greeting(name, english: isEnglish(context));
  }

  /// BiDi-safe mixed body for AR locale.
  static String mixedBody(String body, BuildContext context) {
    return LocaleFormat.mixedBody(body, english: isEnglish(context));
  }

  static Future<void> setLanguage(String code) async {
    final next = code == 'en' ? 'en' : 'ar';
    final changed = languageCode.value != next;
    languageCode.value = next;
    try {
      await _prefs.saveLanguage(next);
    } catch (_) {
      // Still apply in-memory even if persist fails.
    }
    if (changed) {
      // Fire-and-forget — analytics never blocks locale switch.
      AnalyticsService.setAppLanguage(next);
      AnalyticsService.logLanguageChanged(lang: next);
    }
  }

  static Future<void> toggle(BuildContext context) async {
    await setLanguage(isEnglish(context) ? 'ar' : 'en');
  }
}
