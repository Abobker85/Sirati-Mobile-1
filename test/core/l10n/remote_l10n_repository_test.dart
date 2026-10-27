import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_l10n_store.dart';

Uri _uri(String path) => Uri.parse('https://api.test/api/$path');

Map<String, Object?> _language(String code, int version,
        {String direction = 'ltr', String? fallback = 'en'}) =>
    {
      'code': code,
      'name': code.toUpperCase(),
      'native_name': 'native-$code',
      'direction': direction,
      'fallback': fallback,
      'version': version,
    };

String _languagesBody(List<Map<String, Object?>> data) =>
    jsonEncode({'default': 'ar', 'data': data});

String _stringsBody(String code, int version, Map<String, Object?> strings) =>
    jsonEncode({
      'code': code,
      'direction': 'ltr',
      'fallback': 'en',
      'version': version,
      'strings': strings,
    });

/// Fake backend for the public i18n contract.
class _FakeApi {
  _FakeApi({required this.languages, required this.strings});

  List<Map<String, Object?>> languages;
  Map<String, Map<String, Object?>> strings;
  final requests = <http.Request>[];
  http.Response? Function(http.Request)? override;

  int count(String pathEnd) =>
      requests.where((r) => r.url.path.endsWith(pathEnd)).length;

  late final client = MockClient((request) async {
    requests.add(request);
    final forced = override?.call(request);
    if (forced != null) return forced;
    final path = request.url.path;
    if (path.endsWith('/i18n/languages')) {
      return http.Response.bytes(utf8.encode(_languagesBody(languages)), 200,
          headers: {'content-type': 'application/json'});
    }
    final match = RegExp(r'/i18n/languages/([^/]+)/strings$').firstMatch(path);
    if (match == null) return http.Response('', 404);
    final code = match.group(1)!;
    final record = languages.where((l) => l['code'] == code).firstOrNull;
    if (record == null) return http.Response('', 404);
    final version = record['version'] as int;
    final etag = '"$code-$version"';
    if (request.headers['If-None-Match'] == etag) {
      return http.Response('', 304, headers: {'etag': etag});
    }
    return http.Response.bytes(
      utf8.encode(_stringsBody(code, version, strings[code] ?? {})),
      200,
      headers: {'etag': etag, 'content-type': 'application/json'},
    );
  });
}

void main() {
  late MemoryRemoteL10nStore store;
  late _FakeApi api;
  late DateTime now;

  RemoteL10nRepository repository() => RemoteL10nRepository(
        store: store,
        client: api.client,
        uri: _uri,
        clock: () => now,
      );

  setUp(() {
    store = MemoryRemoteL10nStore();
    now = DateTime(2026, 10, 27, 12);
    api = _FakeApi(
      languages: [
        _language('ar', 3, direction: 'rtl'),
        _language('en', 2, fallback: null),
        _language('fr', 5),
      ],
      strings: {
        'ar': {'appTitle': 'سيرتي برو'},
        'en': {'appTitle': 'Siratie Pro', 'language': 'Language!'},
        'fr': {'appTitle': 'Mon CV'},
      },
    );
  });

  test('loadCache publishes the disk cache without any network call', () async {
    store.languages = RemoteLanguageList.fromJson(
        jsonDecode(_languagesBody([_language('fr', 1)])));
    store.bundles['fr'] = const RemoteStringBundle(
        code: 'fr', version: 1, strings: {'appTitle': 'Cache'});
    final repo = repository();
    await repo.loadCache();
    expect(api.requests, isEmpty);
    expect(repo.state.value.languages.byCode('fr')?.version, 1);
    expect(repo.state.value.bundles['fr']?.strings['appTitle'], 'Cache');
  });

  test('refresh fetches the list and the language chain, caching both',
      () async {
    final repo = repository();
    await repo.refresh('fr');
    final state = repo.state.value;
    expect(state.languages.languages.map((l) => l.code), ['ar', 'en', 'fr']);
    expect(state.languages.byCode('ar')!.direction, TextDirection.rtl);
    // null fallback means bundled English.
    expect(state.languages.byCode('en')!.fallback, 'en');
    expect(state.bundles['fr']!.strings, {'appTitle': 'Mon CV'});
    expect(state.bundles['en']!.strings['language'], 'Language!');
    expect(state.bundles['fr']!.etag, '"fr-5"');
    expect(store.bundles.keys, containsAll(['fr', 'en']));
    expect(store.languages, state.languages);
    // A bundled language does not need any other language's strings.
    await repo.refresh('ar', force: true);
    expect(repo.state.value.bundles['ar']!.strings['appTitle'], 'سيرتي برو');
    expect(api.count('/en/strings'), 1);
  });

  test('an unchanged list version skips the strings request', () async {
    final repo = repository();
    await repo.refresh('ar');
    expect(api.count('/ar/strings'), 1);
    await repo.refresh('ar', force: true);
    expect(api.count('/ar/strings'), 1);
    expect(api.count('/i18n/languages'), 2);
  });

  test('a new version sends If-None-Match; 304 keeps the cached bundle',
      () async {
    final repo = repository();
    await repo.refresh('ar');
    final cached = repo.state.value.bundles['ar'];
    // Version bump in the list, but the strings endpoint answers 304.
    api.languages[0] = _language('ar', 4, direction: 'rtl');
    api.override = (request) =>
        request.url.path.endsWith('/strings') ? http.Response('', 304) : null;
    await repo.refresh('ar', force: true);
    final conditional = api.requests.last;
    expect(conditional.headers['If-None-Match'], '"ar-3"');
    expect(repo.state.value.bundles['ar'], same(cached));
  });

  test('version bumps (e.g. direction change) refetch and replace strings',
      () async {
    final repo = repository();
    await repo.refresh('ar');
    api.languages[0] = _language('ar', 4, direction: 'ltr');
    api.strings['ar'] = {'appTitle': 'جديد'};
    await repo.refresh('ar', force: true);
    expect(
        repo.state.value.languages.byCode('ar')!.direction, TextDirection.ltr);
    expect(repo.state.value.bundles['ar']!.strings['appTitle'], 'جديد');
    expect(store.bundles['ar']!.version, 4);
  });

  group('failures are silent and keep the last good cache', () {
    final failures = <String, http.Response Function(http.Request)>{
      'server error': (_) => http.Response('oops', 500),
      'not found': (_) => http.Response('', 404),
      'invalid JSON': (_) => http.Response('{not json', 200),
      'JSON array': (_) => http.Response('[]', 200),
      'no data/strings': (_) => http.Response('{"default":"ar"}', 200),
      'wrong bundle code': (r) => r.url.path.endsWith('/strings')
          ? http.Response(_stringsBody('xx', 9, {'a': 'b'}), 200)
          : http.Response('{"data": 3}', 200),
      'strings not a map': (_) =>
          http.Response('{"code":"ar","version":9,"strings":[1]}', 200),
      'exception': (_) => throw const SocketExceptionLike(),
    };

    for (final entry in failures.entries) {
      test(entry.key, () async {
        final repo = repository();
        await repo.refresh('fr');
        final before = repo.state.value;
        final writes = store.writes;
        api.languages[2] = _language('fr', 6);
        api.override = entry.value;
        await repo.refresh('fr', force: true);
        expect(repo.state.value.bundles['fr'], before.bundles['fr']);
        expect(repo.state.value.bundles['fr']!.strings['appTitle'], 'Mon CV');
        expect(repo.state.value.languages.languages, isNotEmpty);
        expect(store.writes, writes);
      });
    }

    test('a hanging server times out', () async {
      final hanging = Completer<http.Response>();
      final repo = RemoteL10nRepository(
        store: store,
        client: MockClient((_) => hanging.future),
        uri: _uri,
        timeout: const Duration(milliseconds: 20),
      );
      await repo.refresh('ar');
      expect(repo.state.value, same(RemoteL10nState.empty));
    });
  });

  test('records and string values of the wrong type are dropped', () async {
    api.languages = [
      _language('fr', 1),
      {'code': 42},
      {'code': 'not a code!'},
      {'name': 'missing code'},
      _language('fr', 7),
    ];
    api.strings['fr'] = {'appTitle': 'ok', 'cvCount': 3, 'x': null};
    final repo = repository();
    await repo.refresh('fr');
    expect(repo.state.value.languages.languages.map((l) => l.code), ['fr']);
    expect(repo.state.value.bundles['fr']!.strings, {'appTitle': 'ok'});
  });

  test('languages that are not enabled are never fetched', () async {
    final repo = repository();
    await repo.refresh('de');
    expect(api.count('/de/strings'), 0);
    // `de` is unknown, so its chain is de -> en.
    expect(api.count('/en/strings'), 1);
  });

  test('throttle: at most one refresh per 15 minutes unless forced', () async {
    final repo = repository();
    await repo.refresh('ar');
    for (var minute = 0; minute < 15; minute++) {
      now = now.add(const Duration(seconds: 59));
      await repo.refresh('ar');
    }
    expect(api.count('/i18n/languages'), 1);
    now = now.add(const Duration(minutes: 1));
    await repo.refresh('ar');
    expect(api.count('/i18n/languages'), 2);
    await repo.refresh('fr', force: true);
    expect(api.count('/i18n/languages'), 3);
    expect(api.count('/fr/strings'), 1);
  });

  test('concurrent refreshes run one after another', () async {
    final repo = repository();
    await Future.wait([
      repo.refresh('ar', force: true),
      repo.refresh('fr', force: true),
      repo.refresh('ar', force: true),
    ]);
    expect(api.count('/i18n/languages'), 3);
    expect(api.count('/ar/strings'), 1);
    expect(api.count('/fr/strings'), 1);
  });

  group('SharedPreferencesRemoteL10nStore', () {
    test('round-trips the list and bundles with arbitrary Unicode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = SharedPreferencesRemoteL10nStore();
      final list = RemoteLanguageList.fromJson(jsonDecode(_languagesBody([
        _language('ar', 3, direction: 'rtl'),
        _language('pt-br', 1),
      ])));
      const bundle = RemoteStringBundle(
        code: 'pt-br',
        version: 1,
        etag: '"pt-br-1"',
        strings: {'a': 'ação {n} 202b"\'', 'b': 'مرحباً'},
      );
      await prefs.writeLanguages(list);
      await prefs.writeBundle(bundle);
      expect(await prefs.readLanguages(), list);
      final read = await prefs.readBundle('pt-br');
      expect(read!.strings, bundle.strings);
      expect(read.etag, bundle.etag);
      expect(await prefs.bundleCodes(), ['pt-br']);
    });

    test('corrupt or foreign entries read as empty, never throw', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesRemoteL10nStore.languagesKey: '{broken',
        '${SharedPreferencesRemoteL10nStore.bundlePrefix}fr':
            jsonEncode({'schemaVersion': 999, 'data': {}}),
        '${SharedPreferencesRemoteL10nStore.bundlePrefix}de':
            jsonEncode({'schemaVersion': 1, 'data': 'x'}),
      });
      final prefs = SharedPreferencesRemoteL10nStore();
      expect(await prefs.readLanguages(), isNull);
      expect(await prefs.readBundle('fr'), isNull);
      expect(await prefs.readBundle('de'), isNull);
      final repo = RemoteL10nRepository(
        store: prefs,
        client: MockClient((_) async => http.Response('', 500)),
        uri: _uri,
      );
      await repo.loadCache();
      expect(repo.state.value.bundles, isEmpty);
    });
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
