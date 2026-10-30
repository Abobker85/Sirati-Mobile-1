import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_l10n_store.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

/// App-wide remote labels: cache before the first frame, background
/// refresh on launch, on resume (throttled) and on language change.
abstract final class RemoteL10n {
  static RemoteL10nRepository? _repository;
  static AppLifecycleListener? _lifecycle;
  static bool _bound = false;

  static RemoteL10nRepository get repository => _repository ??=
      RemoteL10nRepository(store: SharedPreferencesRemoteL10nStore());

  static ValueListenable<RemoteL10nState> get state => repository.state;

  /// Labels of the selected language, for code with no [BuildContext]
  /// (network errors, widgets outside the localized tree).
  static AppLocalizations get current =>
      RemoteLocalizationsDelegate.localizationsFor(
          state.value, AppLocale.locale);

  /// Loads the disk cache (no network) and keeps [AppLocale.catalog] in
  /// sync with the languages list. Call before [AppLocale.bootstrap].
  static Future<void> loadCache() async {
    _bind();
    await repository.loadCache();
  }

  /// Starts background refreshes. Call after `runApp`.
  static void start() {
    _bind();
    _lifecycle ??= AppLifecycleListener(onResume: _refresh);
    AppLocale.languageCode.addListener(_onLanguageChanged);
    _refresh();
  }

  static void _bind() {
    if (_bound) return;
    _bound = true;
    repository.state.addListener(_syncCatalog);
    _syncCatalog();
  }

  static void _syncCatalog() {
    final languages = repository.state.value.languages;
    if (AppLocale.catalog.value != languages) {
      AppLocale.updateCatalog(languages);
    }
  }

  static void _refresh() =>
      unawaited(repository.refresh(AppLocale.languageCode.value));

  static void _onLanguageChanged() => unawaited(
        repository.refresh(AppLocale.languageCode.value, force: true),
      );

  @visibleForTesting
  static void debugReset([RemoteL10nRepository? repository]) {
    _repository?.state.removeListener(_syncCatalog);
    AppLocale.languageCode.removeListener(_onLanguageChanged);
    _lifecycle?.dispose();
    _lifecycle = null;
    _bound = false;
    _repository = repository;
  }
}
