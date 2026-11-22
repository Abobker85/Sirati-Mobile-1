import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

import '../../support/contrast_probe.dart';

/// Sends the reset code without a network, so the second stage can open.
class _FakeAuth extends AuthApiService {
  @override
  Future<void> forgotPassword({required String email}) async {}
}

/// The smallest supported phone with the keyboard up and larger text.
const _phone = Size(320, 568);
const _keyboard = 260.0;
const _textScale = 1.3;

typedef _Screen = ({
  String name,
  Widget Function() build,
  Future<void> Function(WidgetTester tester)? prepare,
});

final List<_Screen> _screens = [
  (name: 'login', build: () => const LoginScreen(), prepare: null),
  (name: 'register', build: () => const RegisterScreen(), prepare: null),
  (
    name: 'forgot password (email)',
    build: () => const ForgotPasswordScreen(),
    prepare: null,
  ),
  (
    name: 'forgot password (code and new password)',
    build: () => const ForgotPasswordScreen(),
    prepare: (tester) async {
      await tester.enterText(find.byType(TextField).first, 'sara@x.io');
      await tester.ensureVisible(find.byType(SubmitButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SubmitButton));
      await tester.pumpAndSettle();
      ScaffoldMessenger.of(tester.element(find.byType(ForgotPasswordScreen)))
          .removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
      await tester.pumpAndSettle();
      // The second stage has the code field and both password fields.
      expect(find.byType(TextField), findsNWidgets(4));
    },
  ),
  (
    name: 'email verification',
    build: () => const EmailVerificationScreen(email: 'sara@x.io'),
    prepare: null,
  ),
];

void main() {
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  for (final screen in _screens) {
    for (final language in ['ar', 'en']) {
      for (final dark in [false, true]) {
        final label = '${screen.name} $language ${dark ? 'dark' : 'light'}';
        testWidgets(
            '$label: keyboard up at 320x568 x1.3 reflows and '
            'the submit stays reachable', (tester) async {
          tester.view.physicalSize = _phone;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          AppLocale.languageCode.value = language;
          final arabic = language == 'ar';

          await tester.pumpWidget(ProviderScope(
            overrides: [
              jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
              authApiServiceProvider.overrideWithValue(_FakeAuth()),
            ],
            child: MaterialApp(
              theme: dark
                  ? AppTheme.darkFor(arabic: arabic)
                  : AppTheme.lightFor(arabic: arabic),
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(_textScale),
                ),
                child: child!,
              ),
              home: screen.build(),
            ),
          ));
          await tester.pumpAndSettle();
          await screen.prepare?.call(tester);

          // Every text is AA on what it is painted over, before and after
          // the keyboard.
          expectAllTextAa(label);

          // Focus the first field and raise the keyboard.
          await tester.tap(find.byType(TextField).first);
          tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'overflow: $label');

          final submit = find.byType(SubmitButton);
          expect(submit, findsOneWidget);
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(submit.hitTestable(), findsOneWidget);
          final rect = tester.getRect(submit);
          expect(rect.top, greaterThanOrEqualTo(-precisionErrorTolerance));
          expect(rect.bottom, lessThanOrEqualTo(_phone.height - _keyboard));
          expect(tester.takeException(), isNull, reason: 'overflow: $label');
          expectAllTextAa('$label, keyboard up');

          // Unmount so periodic resend timers stop.
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
