import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

void main() {
  // The tick plays once per field: an error that interrupts it must not make
  // it play again when the field becomes valid later.
  for (final interruptAfterMs in [0, 300, 1000, 1300]) {
    testWidgets('C40: an interrupted tick never plays a second time '
        '(error after ${interruptAfterMs}ms)', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextFormField(
              controller: controller,
              tickWhenValid: true,
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? 'too short' : null,
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Riyadh');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.byType(ValidTick), findsOneWidget, reason: 'first tick');

      await tester.pump(Duration(milliseconds: interruptAfterMs));
      // The user edits it to something invalid and submits before the tick
      // finished: the error takes the suffix slot.
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'R');
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('too short'), findsOneWidget);
      expect(find.byType(ValidTick), findsNothing);

      // Long after the tick's own duration, the user fixes the value.
      await tester.pump(const Duration(seconds: 3));
      await tester.enterText(find.byType(TextField), 'Riyadh!');
      await tester.pump();
      expect(find.text('too short'), findsNothing);
      expect(find.byType(ValidTick), findsNothing,
          reason: 'the tick already played once for this field');
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
