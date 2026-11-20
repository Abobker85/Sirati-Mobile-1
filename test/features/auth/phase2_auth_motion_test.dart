import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

class _FakeForgotAuth extends AuthApiService {
  @override
  Future<void> forgotPassword({required String email}) async {}
}

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
  List<dynamic> overrides = const [],
}) {
  AppLocale.languageCode.value = locale.languageCode;
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: body!,
      ),
      home: child,
    ),
  );
}

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

  group('ForgotPasswordScreen bidirectional MotionStepSwitcher', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      final rtl = locale.languageCode == 'ar';
      testWidgets(
          'slides forward from reading-end and reverses on back ($locale)',
          (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            const ForgotPasswordScreen(),
            locale: locale,
            overrides: [
              authApiServiceProvider.overrideWithValue(_FakeForgotAuth()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'sara@x.io');
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ForgotPasswordScreen)),
        );
        await tester.tap(find.text(l10n.authForgotSendCode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        // Step body moved to code step (direction +1).
        final stepField = find.text(l10n.authVerificationCodeLabel);
        expect(stepField, findsOneWidget);
        final midDx = tester.getTopLeft(stepField).dx;
        await tester.pumpAndSettle();
        final settledDx = tester.getTopLeft(stepField).dx;
        if (rtl) {
          expect(midDx, lessThan(settledDx));
        } else {
          expect(midDx, greaterThan(settledDx));
        }

        // Go back to email step (direction -1).
        final backBtn = find.text(l10n.authForgotUseDifferentEmail);
        await tester.ensureVisible(backBtn);
        await tester.pumpAndSettle();
        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final sendBtn = find.text(l10n.authForgotSendCode);
        expect(sendBtn, findsOneWidget);
        final backMidDx = tester.getTopLeft(sendBtn).dx;
        await tester.pumpAndSettle();
        final backSettledDx = tester.getTopLeft(sendBtn).dx;
        if (rtl) {
          expect(backMidDx, greaterThan(backSettledDx));
        } else {
          expect(backMidDx, lessThan(backSettledDx));
        }
      });
    }

    testWidgets('snaps immediately under disableAnimations', (tester) async {
      await tester.pumpWidget(
        _app(
          const ForgotPasswordScreen(),
          disableAnimations: true,
          overrides: [
            authApiServiceProvider.overrideWithValue(_FakeForgotAuth()),
          ],
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'sara@x.io');
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ForgotPasswordScreen)),
      );
      await tester.tap(find.text(l10n.authForgotSendCode));
      await tester.pump();
      final intro = find.text(l10n.authForgotCodeIntro);
      expect(intro, findsOneWidget);
      final immediateDx = tester.getTopLeft(intro).dx;
      await tester.pumpAndSettle();
      expect(immediateDx, tester.getTopLeft(intro).dx);
    });
  });

  group('EmailVerificationScreen 6-dot progress', () {
    testWidgets('updates dot indicators as digits are typed', (tester) async {
      await tester.pumpWidget(
        _app(
          const EmailVerificationScreen(email: 'sara@x.io'),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      final dotsRow = find.byKey(const ValueKey('otp-progress-dots'));
      expect(dotsRow, findsOneWidget);
      expect(
        find.descendant(of: dotsRow, matching: find.byType(AnimatedContainer)),
        findsNWidgets(6),
      );

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pump();
      final dots = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
                of: dotsRow, matching: find.byType(AnimatedContainer)),
          )
          .toList();
      final widths = dots
          .map((d) => d.constraints?.maxWidth)
          .toList();
      // First 3 filled (12), 4th active (10), last 2 unfilled (8).
      expect(widths, [12.0, 12.0, 12.0, 10.0, 8.0, 8.0]);
    });
  });

  group('RegisterScreen MotionExpandSlot', () {
    testWidgets('expands Other job title field smoothly when Other is chosen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          const RegisterScreen(),
          overrides: [
            jobTitlesProvider.overrideWith(
              (ref) async => const [
                JobTitle(
                  id: 1,
                  slug: 'engineer',
                  nameEn: 'Engineer',
                  nameAr: 'مهندس',
                  category: 'tech',
                  keywords: ['engineer'],
                  sortOrder: 1,
                ),
                JobTitle(
                  id: 99,
                  slug: 'other',
                  nameEn: 'Other',
                  nameAr: 'أخرى',
                  category: 'other',
                  keywords: ['other'],
                  sortOrder: 99,
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('register-job-title-other')),
          findsNothing);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RegisterScreen)),
      );
      await tester.tap(find.text(l10n.sharedJobTitleSelectHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أخرى').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('register-job-title-other')),
          findsOneWidget);
      expect(find.byType(MotionExpandSlot), findsNWidgets(2));
    });
  });
}
