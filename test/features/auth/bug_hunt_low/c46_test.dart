import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/latin_digits.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _FakeAuth extends AuthApiService {
  final codes = <String>[];
  @override
  Future<AuthUser> verifyEmail({required String code}) async {
    codes.add(code);
    throw const ApiException('offline', type: ApiErrorType.network);
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets(
      'Retry on a verify-failure snackbar after leaving to Login '
      'does not touch the disposed screen', (tester) async {
    AppLocale.languageCode.value = 'en';
    final auth = _FakeAuth();
    await tester.pumpWidget(ProviderScope(
      overrides: [authApiServiceProvider.overrideWithValue(auth)],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const EmailVerificationScreen(email: 'sara@x.io'),
      ),
    ));
    await tester.pump();
    await tester.enterText(
        find.byWidgetPredicate((w) =>
            w is TextField &&
            (w.inputFormatters ?? const [])
                .any((f) => f is LatinDigitsInputFormatter)),
        '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(auth.codes, ['123456']);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(EmailVerificationScreen), findsNothing);
    expect(find.text('Retry'), findsOneWidget,
        reason: 'the snackbar outlives the screen');

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
