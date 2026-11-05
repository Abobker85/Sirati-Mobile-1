import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/session_cache.dart';

/// `/auth/me` that answers each request only when the test releases it.
class _SlowMe extends ApiClient {
  final replies = <Completer<int>>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    final reply = Completer<int>();
    replies.add(reply);
    final id = await reply.future;
    return {
      'data': {'id': id, 'name': 'User $id', 'email': 'u$id@x.io'},
    };
  }
}

AuthUser _user(int id) =>
    AuthUser(id: id, name: 'User $id', email: 'u$id@x.io');

void main() {
  late _SlowMe api;
  late AuthApiService auth;

  setUp(() {
    SessionCache.instance.clear();
    api = _SlowMe();
    auth = AuthApiService(apiClient: api);
  });

  test('an undisturbed reply becomes the session user', () async {
    SessionCache.instance.setUser(_user(1));
    final me = auth.me();
    await pumpEventQueue();
    api.replies.single.complete(1);
    expect((await me)?.id, 1);
    expect(SessionCache.instance.user.value?.id, 1);

    // The first reply after app start fills an empty session too.
    SessionCache.instance.clear();
    final first = auth.me();
    await pumpEventQueue();
    api.replies.last.complete(3);
    await first;
    expect(SessionCache.instance.user.value?.id, 3);
  });

  for (final (name, change) in [
    ('another account signs in', () => SessionCache.instance.setUser(_user(2))),
    ('the account signs out', SessionCache.instance.clear),
  ]) {
    test('a late reply never replaces the session when $name', () async {
      SessionCache.instance.setUser(_user(1));
      final late = auth.me();
      await pumpEventQueue();
      change();
      final after = SessionCache.instance.user.value;
      api.replies.single.complete(1);

      expect((await late)?.id, 1, reason: 'The caller still gets the reply');
      expect(SessionCache.instance.user.value, same(after));
    });
  }
}
