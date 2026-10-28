import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final shown = <int>[];

  setUp(() {
    shown.clear();
    NotificationService.instance.configureForTest(
      localDisplay: (id, title, body, payload) => shown.add(id),
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  RemoteMessage message({
    String? messageId,
    Map<String, dynamic> data = const {},
    bool withNotification = true,
  }) =>
      RemoteMessage(
        messageId: messageId,
        data: data,
        notification: withNotification
            ? const RemoteNotification(title: 't', body: 'b')
            : null,
      );

  for (final platform in TargetPlatform.values) {
    test('$platform: a foreground message is displayed at most once', () {
      debugDefaultTargetPlatformOverride = platform;

      NotificationService.instance
          .handleForegroundMessage(message(messageId: 'm-1'));

      // iOS presents the banner natively; every other platform needs exactly
      // one local copy.
      expect(shown, hasLength(platform == TargetPlatform.iOS ? 0 : 1));
    });
  }

  test('data-only messages never produce a local notification', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    NotificationService.instance.handleForegroundMessage(
      message(messageId: 'm-2', withNotification: false),
    );

    expect(shown, isEmpty);
  });

  test('redelivery of the same server notification reuses its local id', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    for (final serverId in ['1', '42', '987654321', '99999999999']) {
      NotificationService.instance.handleForegroundMessage(
        message(messageId: 'a-$serverId', data: {'notification_id': serverId}),
      );
      NotificationService.instance.handleForegroundMessage(
        message(messageId: 'b-$serverId', data: {'notification_id': serverId}),
      );
    }

    for (var i = 0; i < shown.length; i += 2) {
      expect(shown[i], shown[i + 1]);
      expect(shown[i], inInclusiveRange(0, 0x7fffffff));
    }
  });

  test('distinct server notifications get distinct local ids', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    for (var id = 1; id <= 50; id++) {
      NotificationService.instance.handleForegroundMessage(
        message(messageId: 'm-$id', data: {'notification_id': '$id'}),
      );
    }

    expect(shown.toSet(), hasLength(50));
  });
}
