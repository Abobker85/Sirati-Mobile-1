import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/domain/notification_item.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';

/// Abobker85/Sirati#12: the server writes its messages in the app language,
/// so every call names it, and what the server wrote is what the user reads.
void main() {
  tearDown(() => AppLocale.languageCode.value = 'ar');

  test('every request names the app language, whatever it is', () async {
    final random = Random(12);
    final codes = [
      'ar',
      'en',
      'fr',
      'ur',
      for (var i = 0; i < 8; i++)
        String.fromCharCodes(List.generate(2, (_) => 97 + random.nextInt(26))),
    ];
    final seen = <String?>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        seen.add(request.headers['x-app-language']);
        return http.Response(jsonEncode({'data': {}}), 200,
            headers: {'content-type': 'application/json'});
      }),
    );

    for (final code in codes) {
      AppLocale.languageCode.value = code;
      seen.clear();
      await client.getJson('/mobile/job-news');
      await client.postJson('/auth/login', {'email': 'a@b.c'});
      await client.putJson('/auth/profile', {'name': 'x'});
      await client.deleteJson('/auth/avatar');
      expect(seen, List.filled(4, code), reason: code);
    }
  });

  for (final (language, message, field) in [
    ('ar', 'بيانات تسجيل الدخول غير صحيحة.', 'حقل الاسم مطلوب.'),
    (
      'en',
      'The email or password is incorrect.',
      'The name field is required.'
    ),
  ]) {
    testWidgets('the server message is what the user reads ($language)',
        (tester) async {
      AppLocale.languageCode.value = language;
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response(
              jsonEncode({
                'message': message,
                'errors': {
                  'name': [field],
                },
              }),
              422,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      Object? error;
      try {
        await client.postJson('/auth/register', {});
      } catch (e) {
        error = e;
      }
      expect(error, isA<ApiException>());

      await tester.pumpWidget(_app(
        language,
        AppAsyncBody<int>(
          snapshot: AsyncSnapshot.withError(ConnectionState.done, error!),
          loading: const SizedBox(),
          builder: (_) => const SizedBox(),
          english: language == 'en',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(field), findsOneWidget);
    });

    testWidgets(
        'a server notification is shown as the server wrote it '
        '($language)', (tester) async {
      AppLocale.languageCode.value = language;
      final title =
          language == 'ar' ? 'سيرتك الذاتية جاهزة' : 'Your CV is ready';
      final body = language == 'ar'
          ? 'افتح سيرتي لمراجعة السيرة وتصديرها.'
          : 'Open Siratie to review and export your CV.';
      final item = NotificationItem.fromJson({
        'id': 1,
        'type': 'cv_ready',
        'title': title,
        'body': body,
        'is_read': false,
        'created_at': DateTime(2026, 10, 30, 9).toIso8601String(),
        'action_type': 'screen',
        'action_url': 'my-cvs/1',
      });

      await tester.pumpWidget(_app(
        language,
        NotificationInbox(
          items: [item],
          now: DateTime(2026, 10, 30, 10),
          onRefresh: () async {},
          onOpen: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      expect(find.text(body), findsOneWidget);
    });
  }
}

Widget _app(String language, Widget child) => MaterialApp(
      theme: AppTheme.lightFor(arabic: language == 'ar'),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );
