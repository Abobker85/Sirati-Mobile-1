import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/storage/storage_cleanup_exception.dart';
import 'package:sirati/core/storage/user_scoped_storage.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/data/auth_session_guard.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/features/cv_builder/application/cv_draft_store.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// In-memory flutter_secure_storage so PreferenceStore runs for real.
final _secure = <String, String>{};

void _mockSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          _secure[key!] = args['value']! as String;
          return null;
        case 'read':
          return _secure[key];
        case 'delete':
          _secure.remove(key);
          return null;
        case 'containsKey':
          return _secure.containsKey(key);
        case 'readAll':
          return Map<String, String>.from(_secure);
        case 'deleteAll':
          _secure.clear();
          return null;
      }
      return null;
    },
  );
}

const _deviceSecure = {
  PreferenceStore.langKey: 'ar',
  PreferenceStore.themeModeKey: 'dark',
  PreferenceStore.onboardingKey: '1',
};

const _deviceShared = {'unrelated_device_flag': 'keep'};

/// Seeds one account's data plus device-level settings.
Future<void> _seedAccountData() async {
  _secure
    ..clear()
    ..addAll(_deviceSecure)
    ..[PreferenceStore.educationInterestKey] = '1'
    ..[PreferenceStore.notificationsKey] = '0';
  SharedPreferences.setMockInitialValues({
    ..._deviceShared,
    '${UserScopedKeys.builderDraftPrefix}cv_1': '{"title":"Sara CV"}',
    '${UserScopedKeys.builderDocPrefix}cv_1': '{"title":"Sara CV"}',
    UserScopedKeys.builderIndexKey: <String>['cv_1'],
  });
  // A real generator draft with personal data, written by the real store.
  await const CvDraftStore(PreferenceStore()).save(
    const CvFormData(
      fullName: 'Sara Ahmed',
      email: 'sara@x.io',
      phone: '+966501234567',
    ),
    step: 1,
  );
}

Future<void> _expectOnlyDeviceDataLeft() async {
  expect(
    await const CvDraftStore(PreferenceStore()).read(stepCount: 4),
    isNull,
    reason: 'the next account must not be offered this draft',
  );
  for (final key in UserScopedKeys.secureKeys) {
    expect(_secure.containsKey(key), isFalse, reason: key);
  }
  for (final MapEntry(:key, :value) in _deviceSecure.entries) {
    expect(_secure[key], value, reason: 'device setting $key kept');
  }
  final shared = await SharedPreferences.getInstance();
  expect(
    shared.getKeys().where(UserScopedKeys.isUserScopedPreference),
    isEmpty,
  );
  expect(shared.getString('unrelated_device_flag'), 'keep');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_mockSecureStorage);

  test('the seeded draft is real (sanity)', () async {
    await _seedAccountData();
    final draft =
        await const CvDraftStore(PreferenceStore()).read(stepCount: 4);
    expect(draft?.data.fullName, 'Sara Ahmed');
  });

  test('logout removes account data and keeps device settings', () async {
    await _seedAccountData();
    final tokens = MemoryAuthTokenStore('bearer');
    final auth = AuthApiService(
      apiClient: ApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        tokenProvider: tokens.readToken,
      ),
      tokenStore: tokens,
    );
    await http.runWithClient(
      auth.logout,
      () => MockClient((_) async => http.Response('{}', 200)),
    );
    await _expectOnlyDeviceDataLeft();
  });

  test('session expiry (401) removes the same account data', () async {
    await _seedAccountData();
    final tokens = MemoryAuthTokenStore('bearer');
    AuthSessionGuard.resetForTest(store: tokens);
    addTearDown(AuthSessionGuard.resetForTest);
    await AuthSessionGuard.handleAuthExpired(
      requestToken: 'bearer',
      showMessage: false,
    );
    await _expectOnlyDeviceDataLeft();
  });

  test('the wipe keeps going when one store fails', () async {
    await _seedAccountData();
    await expectLater(
      wipeUserScopedStorage(prefs: _ThrowingPrefs()),
      throwsA(isA<StorageCleanupException>().having(
        (error) => error.failures.map((failure) => failure.operation),
        'failed removals',
        UserScopedKeys.secureKeys,
      )),
    );
    final shared = await SharedPreferences.getInstance();
    expect(
      shared.getKeys().where(UserScopedKeys.isUserScopedPreference),
      isEmpty,
    );
  });

  for (final path in ['logout', 'deleteAccount', 'handleAuthExpired']) {
    for (final step in _cleanupSteps) {
      for (final synchronous in [true, false]) {
        test(
            '$path attempts every step when $step fails '
            '${synchronous ? 'synchronously' : 'asynchronously'}', () async {
          final calls = <String>[];
          final error = StateError('failed $step');
          final cleanup = _recordingCleanup(
            calls,
            {step: error},
            synchronous: synchronous,
          );
          await expectLater(
            _runCleanupPath(path, cleanup),
            throwsA(isA<LocalSessionCleanupException>()
                .having((e) => e.failures.map((f) => f.step), 'steps', [step])
                .having((e) => e.failures.single.error, 'original error',
                    same(error))
                .having((e) => e.failures.single.stackTrace.toString(),
                    'original stack', isNotEmpty)),
          );
          expect(calls, _cleanupSteps);
        });
      }
    }

    test('$path reports all failures after every step has run', () async {
      final calls = <String>[];
      final errors = {for (final step in _cleanupSteps) step: StateError(step)};
      await expectLater(
        _runCleanupPath(path, _recordingCleanup(calls, errors)),
        throwsA(isA<LocalSessionCleanupException>()
            .having(
                (e) => e.failures.map((f) => f.step), 'steps', _cleanupSteps)
            .having((e) => e.failures.map((f) => f.error), 'original errors',
                errors.values.toList())),
      );
      expect(calls, _cleanupSteps);
    });

    test('$path wipes real account data even when token clearing fails',
        () async {
      await _seedAccountData();
      SessionCache.instance.setUser(
        const AuthUser(id: 1, name: 'Sara', email: 'sara@x.io'),
      );
      SessionCache.instance.unreadCount = 3;
      final tokens = _ThrowingTokenStore();
      await expectLater(
        _runCleanupPath(path, null, tokens: tokens),
        throwsA(isA<LocalSessionCleanupException>()
            .having((e) => e.failures.map((f) => f.step), 'steps', ['token'])),
      );
      expect(SessionCache.instance.user.value, isNull);
      expect(SessionCache.instance.unreadCount, 0);
      await _expectOnlyDeviceDataLeft();
    });
  }

  test('cleanup waits for each step before starting the next', () async {
    final gate = Completer<void>();
    final calls = <String>[];
    final cleanup = LocalSessionCleanup(
      clearToken: () async {
        calls.add('token');
        await gate.future;
        throw StateError('token');
      },
      clearSession: () => calls.add('session'),
      clearCaches: () => calls.add('caches'),
      wipeStorage: () => calls.add('storage'),
      forgetDevice: () => calls.add('device'),
      clearAnalytics: () => calls.add('analytics'),
    );
    final pending = expectLater(
      cleanup.run(),
      throwsA(isA<LocalSessionCleanupException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['token']);
    gate.complete();
    await pending;
    expect(calls, _cleanupSteps);
  });

  testWidgets(
      'installed expiry handler reports failure and still leaves the account',
      (tester) async {
    AppLocale.languageCode.value = 'en';
    final calls = <String>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    AuthSessionGuard.resetForTest(
      store: MemoryAuthTokenStore('bearer'),
      localSessionCleanup: _recordingCleanup(
        calls,
        {'token': StateError('locked')},
      ),
    );
    addTearDown(AuthSessionGuard.resetForTest);
    AuthSessionGuard.install(navigatorKey: navigatorKey);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: Text('private account screen')),
      ),
    ));
    await tester.pumpAndSettle();
    await ApiClient.onAuthExpired!(requestToken: 'bearer');
    expect(tester.takeException(), isA<LocalSessionCleanupException>());
    expect(calls, _cleanupSteps);
    await tester.pumpAndSettle();
    expect(find.byType(SessionExpiredScreen), findsOneWidget);
    expect(find.text('private account screen'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  test('builder documents in memory do not follow a new account', () async {
    SessionCache.instance.clear();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(cvRepositoryProvider, (_, __) {});

    SessionCache.instance
        .setUser(const AuthUser(id: 1, name: 'A', email: 'a@x.io'));
    await container
        .read(cvRepositoryProvider)
        .saveCv(CvDocument.createEmpty(id: 'cv_a', title: 'A private CV'));
    expect(await container.read(cvRepositoryProvider).listCvs(), isNotEmpty);

    SessionCache.instance.clear();
    SessionCache.instance
        .setUser(const AuthUser(id: 2, name: 'B', email: 'b@x.io'));
    expect(await container.read(cvRepositoryProvider).listCvs(), isEmpty);
    SessionCache.instance.clear();
  });
}

const _cleanupSteps = [
  'token',
  'session',
  'caches',
  'storage',
  'device',
  'analytics',
];

LocalSessionCleanup _recordingCleanup(
  List<String> calls,
  Map<String, Object> errors, {
  bool synchronous = false,
}) {
  FutureOr<void> Function() action(String step) => () {
        calls.add(step);
        final error = errors[step];
        if (synchronous && error != null) throw error;
        return Future<void>.microtask(() {
          if (error != null) throw error;
        });
      };
  return LocalSessionCleanup(
    clearToken: action('token'),
    clearSession: action('session'),
    clearCaches: action('caches'),
    wipeStorage: action('storage'),
    forgetDevice: action('device'),
    clearAnalytics: action('analytics'),
  );
}

Future<void> _runCleanupPath(
  String path,
  LocalSessionCleanup? cleanup, {
  MemoryAuthTokenStore? tokens,
}) async {
  final store = tokens ?? MemoryAuthTokenStore('bearer');
  await http.runWithClient(() async {
    if (path == 'handleAuthExpired') {
      AuthSessionGuard.resetForTest(store: store, localSessionCleanup: cleanup);
      addTearDown(AuthSessionGuard.resetForTest);
      await AuthSessionGuard.handleAuthExpired(
        requestToken: 'bearer',
        showMessage: false,
      );
    } else {
      final auth = AuthApiService(
        tokenStore: store,
        apiClient: ApiClient(tokenProvider: store.readToken),
        localSessionCleanup: cleanup,
      );
      if (path == 'logout') {
        await auth.logout();
      } else {
        await auth.deleteAccount(password: 'password');
      }
    }
  }, () => MockClient((_) async => http.Response('{}', 200)));
}

class _ThrowingTokenStore extends MemoryAuthTokenStore {
  _ThrowingTokenStore() : super('bearer');

  @override
  Future<void> clearToken() async => throw StateError('keystore locked');
}

class _ThrowingPrefs extends PreferenceStore {
  @override
  Future<void> deleteKey(String key) async => throw StateError('keystore');
}
