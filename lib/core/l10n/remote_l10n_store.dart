import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';

/// Disk cache for the languages list and string bundles.
///
/// Device data, not account data: it survives sign-out (keys are outside
/// `DiskCache.keyPrefix` and `UserScopedKeys`).
abstract class RemoteL10nStore {
  Future<RemoteLanguageList?> readLanguages();
  Future<void> writeLanguages(RemoteLanguageList languages);
  Future<RemoteStringBundle?> readBundle(String code);
  Future<void> writeBundle(RemoteStringBundle bundle);

  /// Codes with a cached bundle.
  Future<List<String>> bundleCodes();
}

class SharedPreferencesRemoteL10nStore implements RemoteL10nStore {
  SharedPreferencesRemoteL10nStore(
      {Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  static const languagesKey = 'sirati_i18n_languages';
  static const bundlePrefix = 'sirati_i18n_strings_';

  /// Bump when the cached JSON shape changes incompatibly.
  static const schemaVersion = 1;

  final Future<SharedPreferences> Function() _prefs;

  @override
  Future<RemoteLanguageList?> readLanguages() async {
    final data = await _read(languagesKey);
    if (data == null) return null;
    try {
      return RemoteLanguageList.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeLanguages(RemoteLanguageList languages) =>
      _write(languagesKey, languages.toJson());

  @override
  Future<RemoteStringBundle?> readBundle(String code) async {
    final data = await _read('$bundlePrefix$code');
    if (data == null) return null;
    try {
      return RemoteStringBundle.fromJson(data, expectedCode: code);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeBundle(RemoteStringBundle bundle) =>
      _write('$bundlePrefix${bundle.code}', bundle.toJson());

  @override
  Future<List<String>> bundleCodes() async {
    final prefs = await _prefs();
    return [
      for (final key in prefs.getKeys())
        if (key.startsWith(bundlePrefix)) key.substring(bundlePrefix.length),
    ];
  }

  Future<Object?> _read(String key) async {
    try {
      final raw = (await _prefs()).getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['schemaVersion'] != schemaVersion) {
        return null;
      }
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Object? data) async {
    final prefs = await _prefs();
    await prefs.setString(
      key,
      jsonEncode({'schemaVersion': schemaVersion, 'data': data}),
    );
  }
}

/// In-memory store for tests and as a no-disk fallback.
class MemoryRemoteL10nStore implements RemoteL10nStore {
  RemoteLanguageList? languages;
  final Map<String, RemoteStringBundle> bundles = {};
  int writes = 0;

  @override
  Future<RemoteLanguageList?> readLanguages() async => languages;

  @override
  Future<void> writeLanguages(RemoteLanguageList value) async {
    writes++;
    languages = value;
  }

  @override
  Future<RemoteStringBundle?> readBundle(String code) async => bundles[code];

  @override
  Future<void> writeBundle(RemoteStringBundle bundle) async {
    writes++;
    bundles[bundle.code] = bundle;
  }

  @override
  Future<List<String>> bundleCodes() async => bundles.keys.toList();
}
