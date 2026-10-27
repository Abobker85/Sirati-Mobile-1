import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';

/// Replaces `AppLocalizations.delegate`: bundled ARB strings overlaid with
/// published remote strings. Any language is supported; one without an ARB
/// uses its fallback language's bundled strings as the base.
class RemoteLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const RemoteLocalizationsDelegate(this.state);

  final RemoteL10nState state;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(localizationsFor(state, locale));

  /// New strings or languages rebuild every `AppLocalizations.of` reader.
  @override
  bool shouldReload(RemoteLocalizationsDelegate old) =>
      !identical(old.state, state);

  static AppLocalizations localizationsFor(
    RemoteL10nState state,
    Locale locale,
  ) {
    final code = languageCodeOfLocale(
      locale,
      state.languages.languages.map((language) => language.code),
    );
    final baseCode = state.baseOf(code);
    final bundled = bundledLanguageCodes.contains(code);
    return RemoteAppLocalizations(
      code,
      base: bundled ? lookupAppLocalizations(Locale(code)) : null,
      fallbackBase: lookupAppLocalizations(Locale(bundled ? 'en' : baseCode)),
      remote: state.lookupFor(code),
    );
  }
}

/// Wraps a Flutter localizations delegate so a language it has no data for
/// loads [fallback] (English) instead of leaving the type unresolved.
class FallbackLocalizationsDelegate<T> extends LocalizationsDelegate<T> {
  const FallbackLocalizationsDelegate(
    this.inner, {
    this.fallback = const Locale('en'),
  });

  final LocalizationsDelegate<T> inner;
  final Locale fallback;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) =>
      inner.load(inner.isSupported(locale) ? locale : fallback);

  @override
  bool shouldReload(FallbackLocalizationsDelegate<T> old) =>
      inner.shouldReload(old.inner);
}

/// The app's delegate list for [state].
List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates(
  RemoteL10nState state,
) =>
    [
      RemoteLocalizationsDelegate(state),
      const FallbackLocalizationsDelegate<MaterialLocalizations>(
        GlobalMaterialLocalizations.delegate,
      ),
      GlobalWidgetsLocalizations.delegate,
      const FallbackLocalizationsDelegate<CupertinoLocalizations>(
        GlobalCupertinoLocalizations.delegate,
      ),
    ];

/// `ar`, `en`, then every enabled remote language.
List<Locale> appSupportedLocales(RemoteL10nState state) => [
      localeForLanguageCode('ar'),
      localeForLanguageCode('en'),
      for (final language in state.languages.languages)
        if (!language.isBundled) localeForLanguageCode(language.code),
    ];
