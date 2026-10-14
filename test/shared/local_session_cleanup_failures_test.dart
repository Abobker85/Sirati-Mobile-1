import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/core/storage/disk_cache.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/storage/user_scoped_storage.dart';
import 'package:sirati/features/auth/data/auth_session_guard.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/services/session_cache.dart';

class _FailingPreferences extends InMemorySharedPreferencesStore {
  _FailingPreferences() : super.empty();

  String? failedRemoval;
  bool failEpoch = false;
  bool returnFalse = false;
  final removals = <String>[];

  @override
  Future<bool> remove(String key) async {
    removals.add(key);
    if (key == failedRemoval) {
      if (returnFalse) return false;
      throw PlatformException(code: 'preferences_locked');
    }
    return super.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failEpoch && key == 'flutter.sirati_content_cache_epoch') {
      if (returnFalse) return false;
      throw PlatformException(code: 'preferences_locked');
    }
    return super.setValue(valueType, key, value);
  }
}

class _DeviceTokens extends FcmTokenSource {
  bool failDelete = false;
  int deletes = 0;

  @override
  Future<String?> getToken() async => 'device-token';

  @override
  Future<void> deleteToken() async {
    deletes++;
    if (failDelete) {
      throw FirebaseException(
        plugin: 'firebase_messaging',
        code: 'network-error',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const paths = ['logout', 'deleteAccount', 'handleAuthExpired'];
  final secure = <String, String>{};
  final deletedSecureKeys = <String>[];
  String? failedSecureKey;
  late _FailingPreferences preferences;
  late _DeviceTokens device;

  setUp(() async {
    secure
      ..clear()
      ..addAll(
          {for (final key in UserScopedKeys.secureKeys) key: 'private data'})
      ..[PreferenceStore.langKey] = 'ar';
    failedSecureKey = null;
    deletedSecureKeys.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map).cast<String, Object?>();
      final key = args['key'] as String?;
      if (call.method == 'delete') {
        deletedSecureKeys.add(key!);
        if (key == failedSecureKey) {
          throw PlatformException(code: 'keystore_locked');
        }
        secure.remove(key);
      } else if (call.method == 'read') {
        return secure[key];
      }
      return null;
    });
    SharedPreferences.resetStatic();
    preferences = _FailingPreferences();
    SharedPreferencesStorePlatform.instance = preferences;
    await DiskCache.instance.clear();
    device = _DeviceTokens();
    NotificationService.instance.configureForTest(
      tokens: device,
      clientFactory: ApiClient.new,
    );
    SessionCache.instance.setUser(
      const AuthUser(
        id: 79,
        name: 'Private profile',
        email: 'private@example.test',
      ),
    );
  });

  tearDown(() async {
    preferences
      ..failedRemoval = null
      ..failEpoch = false;
    await DiskCache.instance.clear();
    AuthSessionGuard.resetForTest();
    SessionCache.instance.clear();
    NotificationService.instance
        .configureForTest(tokens: const FcmTokenSource());
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> run(String path) async {
    final tokens = MemoryAuthTokenStore('bearer');
    await http.runWithClient(() async {
      if (path == 'handleAuthExpired') {
        AuthSessionGuard.resetForTest(store: tokens);
        await AuthSessionGuard.handleAuthExpired(
          requestToken: 'bearer',
          showMessage: false,
        );
      } else {
        final auth = AuthApiService(
          apiClient: ApiClient(),
          tokenStore: tokens,
        );
        if (path == 'logout') {
          await auth.logout();
        } else {
          await auth.deleteAccount(password: 'password');
        }
      }
    }, () => MockClient((_) async => http.Response('{}', 200)));
  }

  Matcher failsAt(String step) => throwsA(
        isA<LocalSessionCleanupException>().having(
          (e) => e.failures.map((failure) => failure.step),
          'failed steps',
          [step],
        ),
      );

  for (final path in paths) {
    for (final key in UserScopedKeys.secureKeys) {
      test(
          '$path reports a real secure deletion failure for $key and can retry',
          () async {
        final shared = await SharedPreferences.getInstance();
        await shared.setString(
            '${UserScopedKeys.builderDocPrefix}cv', 'private CV');
        failedSecureKey = key;
        await expectLater(run(path), failsAt('storage'));
        expect(secure[key], 'private data');
        expect(deletedSecureKeys, UserScopedKeys.secureKeys);
        expect(
          secure.keys.where((item) =>
              item != key && UserScopedKeys.secureKeys.contains(item)),
          isEmpty,
        );
        expect(
          shared.getKeys().where(UserScopedKeys.isUserScopedPreference),
          isEmpty,
        );
        expect(SessionCache.instance.user.value, isNull);
        expect(device.deletes, 1);
        failedSecureKey = null;
        await LocalSessionCleanup(clearToken: () async {}).run();
        expect(secure.keys.where(UserScopedKeys.secureKeys.contains), isEmpty);
        expect(secure[PreferenceStore.langKey], 'ar');
      });
    }

    for (final returnFalse in [false, true]) {
      for (final key in [
        DiskCache.cvsKey('ar'),
        '${UserScopedKeys.builderDocPrefix}cv',
      ]) {
        test(
            '$path reports ${returnFalse ? 'false' : 'throwing'} preference '
            'removal for $key', () async {
          final shared = await SharedPreferences.getInstance();
          const other = '${DiskCache.keyPrefix}other';
          const otherDocument = '${UserScopedKeys.builderDraftPrefix}other';
          await shared.setString(key, 'private data');
          await shared.setString(other, 'other private data');
          await shared.setString(otherDocument, 'other private CV');
          preferences
            ..failedRemoval = 'flutter.$key'
            ..returnFalse = returnFalse;
          await expectLater(
            run(path),
            failsAt(key.startsWith(DiskCache.keyPrefix) ? 'caches' : 'storage'),
          );
          expect((await preferences.getAll())['flutter.$key'], 'private data');
          expect(
            (await preferences.getAll()).containsKey('flutter.$other'),
            isFalse,
          );
          expect(
            (await preferences.getAll()).containsKey('flutter.$otherDocument'),
            isFalse,
          );
          expect(device.deletes, 1);
          expect(
              secure.keys.where(UserScopedKeys.secureKeys.contains), isEmpty);
          preferences.failedRemoval = null;
          await LocalSessionCleanup(clearToken: () async {}).run();
          expect((await preferences.getAll()).containsKey('flutter.$key'),
              isFalse);
        });
      }

      test(
          '$path reports ${returnFalse ? 'false' : 'throwing'} epoch rotation '
          'and still removes caches', () async {
        final shared = await SharedPreferences.getInstance();
        final key = DiskCache.cvsKey('en');
        await DiskCache.instance.put(key, {'name': 'private CV'});
        preferences
          ..failEpoch = true
          ..returnFalse = returnFalse;
        await expectLater(run(path), failsAt('caches'));
        expect(
            (await preferences.getAll()).containsKey('flutter.$key'), isFalse);
        expect(device.deletes, 1);
        preferences.failEpoch = false;
        await LocalSessionCleanup(clearToken: () async {}).run();
        await shared.reload();
        await DiskCache.instance.put(key, {'name': 'next account'});
        expect((await DiskCache.instance.get(key))?.data,
            {'name': 'next account'});
        final envelope =
            jsonDecode((await preferences.getAll())['flutter.$key']! as String)
                as Map;
        expect(
          envelope['cacheEpoch'],
          shared.getString('sirati_content_cache_epoch'),
        );
      });
    }

    test('$path reports a real FCM token deletion failure', () async {
      device.failDelete = true;
      await expectLater(run(path), failsAt('device'));
      expect(device.deletes, 1);
      expect(secure.keys.where(UserScopedKeys.secureKeys.contains), isEmpty);
      device.failDelete = false;
      await LocalSessionCleanup(clearToken: () async {}).run();
      expect(device.deletes, 2);
    });
  }

  test('expiry keeps remote push unregistration best effort', () async {
    AuthSessionGuard.resetForTest(store: MemoryAuthTokenStore('bearer'));
    await http.runWithClient(
      () => AuthSessionGuard.handleAuthExpired(
        requestToken: 'bearer',
        showMessage: false,
      ),
      () => MockClient((_) async => http.Response('{}', 503)),
    );
    expect(device.deletes, 1);
    expect(secure.keys.where(UserScopedKeys.secureKeys.contains), isEmpty);
  });
}
