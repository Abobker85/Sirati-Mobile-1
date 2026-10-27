import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ApiErrorType type,
  required bool english,
  String message = 'raw message from the client or server',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(english ? 'en' : 'ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body:
            AppErrorState(message: message, english: english, errorType: type),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Client-raised failures carry a fixed Arabic, developer-facing message; users
  // must see localized copy that never mentions servers' internals.
  for (final english in [true, false]) {
    for (final type in [ApiErrorType.network, ApiErrorType.timeout]) {
      testWidgets('$type shows localized user copy (english=$english)',
          (tester) async {
        const raw =
            'تعذر الاتصال بالخادم. تأكد من تشغيل Laravel وصحة رابط API.';
        await _pump(tester, type: type, english: english, message: raw);
        expect(find.text(raw), findsNothing);
        expect(find.textContaining('Laravel'), findsNothing);
        expect(find.textContaining('API'), findsNothing);
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' ');
        // English UI must not show Arabic body copy and vice versa.
        final hasArabic = RegExp(r'[؀-ۿ]').hasMatch(texts);
        expect(hasArabic, !english);
      });
    }
  }

  testWidgets('server and validation messages still pass through',
      (tester) async {
    await _pump(
      tester,
      type: ApiErrorType.server,
      english: true,
      message: 'The server said: try later.',
    );
    expect(find.text('The server said: try later.'), findsOneWidget);
  });
}
