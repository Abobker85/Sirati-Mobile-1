// C21: a field the caller switched to AutovalidateMode.onUserInteraction
// (after a failed submit) must drop its error once the user types a valid
// value, even if it never lost focus.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

void main() {
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorage, (_) async => null));
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorage, null));

  for (final language in ['en', 'ar']) {
    testWidgets('$language forgot password: submit error clears on valid input',
        (tester) async {
      AppLocale.languageCode.value = language;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: language == 'ar'),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ForgotPasswordScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(ForgotPasswordScreen)));

      // Submit the empty form: the error shows and the field is focused.
      await tester.tap(find.byType(SubmitButton).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.authEmailRequired), findsOneWidget);

      for (final email in ['sara@example.com', 'a@b', 'x.y+z@mail.example']) {
        await tester.enterText(find.byType(AppTextFormField).first, email);
        await tester.pumpAndSettle();
        expect(find.text(l10n.authEmailRequired), findsNothing,
            reason: 'stale error after typing $email');
        final state = tester
            .state<FormFieldState<String>>(find.byType(AppTextFormField).first);
        expect(state.hasError, isFalse, reason: 'error state after $email');
        await tester.enterText(find.byType(AppTextFormField).first, '');
        await tester.pumpAndSettle();
      }
    });
  }

  for (final word in ['ok', 'valid value', 'سارة']) {
    testWidgets('AppTextFormField onUserInteraction, focused: "$word"',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => (v ?? '').trim().isEmpty ? 'required' : null,
            ),
          ),
        ),
      ));
      await tester.showKeyboard(find.byType(TextField));
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('required'), findsOneWidget);
      await tester.enterText(find.byType(TextField), word);
      await tester.pumpAndSettle();
      expect(find.text('required'), findsNothing);
    });
  }
}
