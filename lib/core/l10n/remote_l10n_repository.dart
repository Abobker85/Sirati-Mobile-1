import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_store.dart';
import 'package:sirati/core/l10n/remote_strings.dart';
import 'package:sirati/core/network/api_config.dart';

/// Languages list + cached string bundles. Immutable; a new instance is
/// published whenever anything changes.
@immutable
class RemoteL10nState {
  const RemoteL10nState({
    this.languages = RemoteLanguageList.empty,
    this.bundles = const {},
  });

  static const empty = RemoteL10nState();

  final RemoteLanguageList languages;
  final Map<String, RemoteStringBundle> bundles;

  /// Fallback for [code]: its record, else its cached bundle, else English.
  String fallbackOf(String code) =>
      languages.byCode(code)?.fallback ?? bundles[code]?.fallback ?? 'en';

  /// [code] followed by fallbacks, ending at the first bundled language.
  /// Languages with an ARB stop at themselves: their bundled text is a
  /// better fallback than another language's remote text.
  List<String> chainFor(String code) {
    final chain = <String>[code];
    var current = code;
    while (!bundledLanguageCodes.contains(current) && chain.length < 4) {
      final next = fallbackOf(current);
      if (chain.contains(next)) break;
      chain.add(next);
      current = next;
    }
    if (!bundledLanguageCodes.contains(chain.last)) chain.add('en');
    return chain;
  }

  /// Bundled language whose ARB is the final fallback for [code].
  String baseOf(String code) => chainFor(code).last;

  RemoteStringLookup lookupFor(String code) => RemoteStringLookup([
        for (final c in chainFor(code))
          if (bundles[c] != null)
            RemoteStringLayer(locale: c, strings: bundles[c]!.strings),
      ]);
}

typedef RemoteL10nUri = Uri Function(String path);

/// Fetches `GET /i18n/languages` and `/i18n/languages/{code}/strings`,
/// caches both, and publishes [state]. Network and parse failures are
/// silent: the last good cache stays in use.
class RemoteL10nRepository {
  RemoteL10nRepository({
    required RemoteL10nStore store,
    http.Client? client,
    RemoteL10nUri? uri,
    DateTime Function()? clock,
    this.minRefreshInterval = const Duration(minutes: 15),
    this.timeout = const Duration(seconds: 10),
  })  : _store = store,
        _injectedClient = client,
        _uri = uri ?? ApiConfig.uri,
        _clock = clock ?? DateTime.now;

  final RemoteL10nStore _store;
  final http.Client? _injectedClient;
  http.Client? _defaultClient;

  /// Created on first request so merely reading [state] opens no client.
  http.Client get _client =>
      _injectedClient ?? (_defaultClient ??= http.Client());
  final RemoteL10nUri _uri;
  final DateTime Function() _clock;
  final Duration minRefreshInterval;
  final Duration timeout;

  final ValueNotifier<RemoteL10nState> _state =
      ValueNotifier(RemoteL10nState.empty);

  ValueListenable<RemoteL10nState> get state => _state;

  DateTime? _lastRefresh;
  Future<void> _queue = Future.value();

  /// Reads the disk cache; never touches the network.
  Future<void> loadCache() async {
    try {
      final languages = await _store.readLanguages();
      final bundles = <String, RemoteStringBundle>{};
      for (final code in await _store.bundleCodes()) {
        final bundle = await _store.readBundle(code);
        if (bundle != null) bundles[code] = bundle;
      }
      _state.value = RemoteL10nState(
        languages: languages ?? _state.value.languages,
        bundles: {..._state.value.bundles, ...bundles},
      );
    } catch (error) {
      debugPrint('[RemoteL10n] cache read failed: $error');
    }
  }

  /// Refreshes the list and [languageCode]'s bundles. Without [force], runs
  /// at most once per [minRefreshInterval]. Calls run one after another.
  Future<void> refresh(String languageCode, {bool force = false}) {
    final next = _queue.then((_) => _refresh(languageCode, force: force));
    _queue = next.catchError((Object _) {});
    return _queue;
  }

  Future<void> _refresh(String languageCode, {required bool force}) async {
    final now = _clock();
    final last = _lastRefresh;
    if (!force && last != null && now.difference(last) < minRefreshInterval) {
      return;
    }
    _lastRefresh = now;

    final languages = await _fetchLanguages();
    if (languages != null && languages != _state.value.languages) {
      _state.value = RemoteL10nState(
        languages: languages,
        bundles: _state.value.bundles,
      );
      await _guard(() => _store.writeLanguages(languages));
    }

    for (final code in _state.value.chainFor(languageCode)) {
      final record = _state.value.languages.byCode(code);
      final cached = _state.value.bundles[code];
      if (languages != null) {
        // Disabled or unknown languages have no published strings.
        if (record == null) continue;
        if (cached != null && cached.version == record.version) continue;
      }
      final bundle = await _fetchBundle(code, cached?.etag);
      if (bundle == null) continue;
      _state.value = RemoteL10nState(
        languages: _state.value.languages,
        bundles: {..._state.value.bundles, code: bundle},
      );
      await _guard(() => _store.writeBundle(bundle));
    }
  }

  Future<RemoteLanguageList?> _fetchLanguages() async {
    try {
      final response = await _client.get(
        _uri('i18n/languages'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);
      if (response.statusCode != 200) return null;
      return RemoteLanguageList.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (error) {
      debugPrint('[RemoteL10n] languages refresh failed: $error');
      return null;
    }
  }

  /// Null on 304, errors and malformed payloads (cache stays).
  Future<RemoteStringBundle?> _fetchBundle(String code, String? etag) async {
    try {
      final response = await _client.get(
        _uri('i18n/languages/${Uri.encodeComponent(code)}/strings'),
        headers: {
          'Accept': 'application/json',
          if (etag != null) 'If-None-Match': etag,
        },
      ).timeout(timeout);
      if (response.statusCode != 200) return null;
      return RemoteStringBundle.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        expectedCode: code,
        etag: response.headers['etag'],
      );
    } catch (error) {
      debugPrint('[RemoteL10n] strings refresh for $code failed: $error');
      return null;
    }
  }

  Future<void> _guard(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      debugPrint('[RemoteL10n] cache write failed: $error');
    }
  }

  @visibleForTesting
  void debugSetState(RemoteL10nState value) => _state.value = value;
}
