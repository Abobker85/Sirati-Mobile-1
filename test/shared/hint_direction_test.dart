import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  TextDirection? textDirection,
  required String hint,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: AppTextFormField(
          textDirection: textDirection,
          hintText: hint,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The hint must follow the field's explicit direction in both UI languages,
  // otherwise a Latin value like a phone number is bidi-reordered in Arabic.
  for (final code in ['en', 'ar']) {
    for (final hint in ['+966 5X XXX XXXX', 'name@example.com']) {
      testWidgets('ltr field hint "$hint" stays ltr in $code', (tester) async {
        await _pump(
          tester,
          locale: Locale(code),
          textDirection: TextDirection.ltr,
          hint: hint,
        );
        final text = tester.widget<Text>(find.text(hint));
        expect(text.textDirection, TextDirection.ltr);
      });
    }
  }
}
