import 'dart:async';
import 'package:flutter/material.dart';

import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/utils/bidi_text.dart';
import 'package:sirati/core/utils/locale_format.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

export 'package:sirati/core/utils/bidi_text.dart';
export 'package:sirati/core/utils/locale_format.dart';

/// GCC country codes: Arabic is the product default on these devices.
const gulfCountryCodes = <String>{'SA', 'AE', 'KW', 'QA', 'BH', 'OM'};

class AppLocale {
  static final ValueNotifier<String> languageCode = ValueNotifier<String>('ar');

  /// Enabled languages from the server (cached). `ar` and `en` are always
  /// available, also while this is empty.
  static final ValueNotifier<RemoteLanguageList> catalog =
      ValueNotifier<RemoteLanguageList>(RemoteLanguageList.empty);

  static PreferenceStore _prefs = const PreferenceStore();
  static List<Locale> _deviceLocales = const [];

  /// Stored choice that is not enabled right now; applied when the catalog
  /// enables it (e.g. the cache was unreadable at launch).
  static String? _pendingStored;

  /// Load persisted language before [runApp].
  ///
  /// Priority: URL `?lang=` (web preview) → secure storage → device locales
  /// (Arabic / Gulf → `ar`, then the first enabled device language) →
  /// Arabic product default. Codes that are not enabled are skipped.
  static Future<void> bootstrap({
    List<Locale>? deviceLocales,
    PreferenceStore? prefs,
  }) async {
    if (prefs != null) _prefs = prefs;
    _deviceLocales =
        deviceLocales ?? WidgetsBinding.instance.platformDispatcher.locales;
    final stored = await _readStoredLanguage();
    final resolved = resolveLanguageCode(
      urlLang: Uri.base.queryParameters['lang'],
      storedLang: stored,
      deviceLocales: _deviceLocales,
      available: availableCodes,
    );
    final storedCode = normalizeLanguageCode(stored);
    _pendingStored = storedCode != null && !availableCodes.contains(storedCode)
        ? storedCode
        : null;
    languageCode.value = resolved;
  }

  static Future<String?> _readStoredLanguage() async {
    try {
      return await _prefs.readLanguage();
    } catch (_) {
      return null;
    }
  }

  /// Pure locale policy. Tested across arbitrary codes and device locales.
  ///
  /// [available] lists enabled codes; `ar` and `en` are always enabled.
  static String resolveLanguageCode({
    String? urlLang,
    String? storedLang,
    List<Locale> deviceLocales = const [],
    Set<String> available = bundledLanguageCodes,
  }) {
    String? enabled(String? raw) {
      final code = normalizeLanguageCode(raw);
      if (code == null) return null;
      return bundledLanguageCodes.contains(code) || available.contains(code)
          ? code
          : null;
    }

    final fromUrl = enabled(urlLang);
    if (fromUrl != null) return fromUrl;
    final fromStore = enabled(storedLang);
    if (fromStore != null) return fromStore;

    for (final locale in deviceLocales) {
      if (locale.languageCode.toLowerCase() == 'ar') return 'ar';
      final country = locale.countryCode?.toUpperCase();
      if (country != null && gulfCountryCodes.contains(country)) return 'ar';
    }
    for (final locale in deviceLocales) {
      final code = enabled(languageCodeOfLocale(locale, available));
      if (code != null) return code;
    }
    return 'ar';
  }

  /// `ar`, `en` and every enabled remote language.
  static Set<String> get availableCodes => {
        ...bundledLanguageCodes,
        for (final language in catalog.value.languages) language.code,
      };

  /// Languages for the picker: server order, `ar`/`en` always present.
  static List<RemoteLanguage> get pickerLanguages => [
        if (catalog.value.byCode('ar') == null) RemoteLanguage.arabic,
        if (catalog.value.byCode('en') == null) RemoteLanguage.english,
        ...catalog.value.languages,
      ];

  static RemoteLanguage? recordFor(String code) =>
      catalog.value.byCode(code) ??
      switch (code) {
        'ar' => RemoteLanguage.arabic,
        'en' => RemoteLanguage.english,
        _ => null,
      };

  /// Applies a new languages list. A selected language that is no longer
  /// enabled falls back by the normal policy (the stored choice is kept, so
  /// it returns when re-enabled); a pending stored choice enabled now wins.
  static void updateCatalog(RemoteLanguageList languages) {
    catalog.value = languages;
    final pending = _pendingStored;
    if (pending != null && availableCodes.contains(pending)) {
      _pendingStored = null;
      languageCode.value = pending;
      return;
    }
    if (!availableCodes.contains(languageCode.value)) {
      _pendingStored ??= languageCode.value;
      languageCode.value = resolveLanguageCode(
        urlLang: Uri.base.queryParameters['lang'],
        deviceLocales: _deviceLocales,
        available: availableCodes,
      );
    }
  }

  /// Bundled language (`ar`/`en`) whose strings and content back [code],
  /// following the language's fallback chain (default English).
  static String baseLanguageOf(String code) {
    var current = code;
    final seen = <String>{};
    while (!bundledLanguageCodes.contains(current)) {
      if (!seen.add(current) || seen.length > 4) return 'en';
      current = catalog.value.byCode(current)?.fallback ?? 'en';
    }
    return current;
  }

  /// True when [code]'s content is backed by English (see [baseLanguageOf]).
  static bool isEnglishCode(String code) => baseLanguageOf(code) == 'en';

  /// Bundled content language (`ar`/`en`) for a stored or served language
  /// code; an unreadable code gives [orElse].
  static String contentLanguageOf(Object? raw, {String orElse = 'ar'}) {
    final code = normalizeLanguageCode(raw);
    return code == null ? orElse : baseLanguageOf(code);
  }

  /// Text direction of [code]: its language record's, else intl's RTL list.
  static TextDirection directionOf(String code) {
    final record = recordFor(code);
    if (record != null) return record.direction;
    return defaultDirectionOf(code);
  }

  /// `ar` or `en`: the content language for API calls and bilingual data.
  static String get baseLanguage => baseLanguageOf(languageCode.value);

  static Locale get locale => localeForLanguageCode(languageCode.value);

  static String _codeOf(BuildContext context) =>
      languageCodeOfLocale(Localizations.localeOf(context), availableCodes);

  /// True when the ambient language is backed by English: English itself,
  /// or a remote language whose fallback chain ends at English.
  static bool isEnglish(BuildContext context) =>
      isEnglishCode(_codeOf(context));

  static bool get isRtl => currentDirection == TextDirection.rtl;

  static TextDirection direction(BuildContext context) =>
      directionOf(_codeOf(context));

  static TextDirection get currentDirection => directionOf(languageCode.value);

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
  ///
  /// Empty [name] → neutral greeting with no invented identity. In RTL a
  /// Latin name stays a single LTR run.
  static String greeting(String name, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trimmed = name.trim();
    if (trimmed.isEmpty) return l10n.coreGreetingWelcome;
    if (direction(context) != TextDirection.rtl) {
      return l10n.coreGreetingHello(trimmed);
    }
    final display =
        BidiText.looksLatin(trimmed) ? BidiText.isolateLtr(trimmed) : trimmed;
    return '${l10n.coreGreetingHello(display)}${BidiText.rlm}';
  }

  /// BiDi-safe mixed body for AR locale.
  static String mixedBody(String body, BuildContext context) {
    return LocaleFormat.mixedBody(body, english: isEnglish(context));
  }

  /// Selects [code] when it is enabled; anything else selects Arabic.
  static Future<void> setLanguage(String code) async {
    final normalized = normalizeLanguageCode(code);
    final next = normalized != null && availableCodes.contains(normalized)
        ? normalized
        : 'ar';
    _pendingStored = null;
    final changed = languageCode.value != next;
    languageCode.value = next;
    try {
      await _prefs.saveLanguage(next);
    } catch (_) {
      // Still apply in-memory even if persist fails.
    }
    if (changed) {
      // Fire-and-forget — analytics never blocks locale switch.
      unawaited(AnalyticsService.setAppLanguage(next));
      unawaited(AnalyticsService.logLanguageChanged(lang: next));
    }
  }

  static Future<void> toggle(BuildContext context) async {
    await setLanguage(isEnglish(context) ? 'ar' : 'en');
  }

  @visibleForTesting
  static void bindPreferences(PreferenceStore prefs) {
    _prefs = prefs;
  }

  @visibleForTesting
  static void resetForTest({
    String language = 'ar',
    RemoteLanguageList languages = RemoteLanguageList.empty,
  }) {
    catalog.value = languages;
    final code = normalizeLanguageCode(language);
    languageCode.value =
        code != null && availableCodes.contains(code) ? code : 'ar';
    _prefs = const PreferenceStore();
    _deviceLocales = const [];
    _pendingStored = null;
  }
}
