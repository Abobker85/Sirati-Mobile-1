import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/data/google_id_token_source.dart';
import 'package:sirati/features/auth/domain/social_sign_in.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _GatedGoogle implements GoogleIdTokenSource {
  final gate = Completer<void>();
  int calls = 0;
  @override
  Future<String?> idToken() async {
    calls++;
    await gate.future;
    return 'tok';
  }
}

class _Auth extends AuthApiService {
  final social = <String>[];
  @override
  Future<AuthSession> socialSignIn({
    required String provider,
    required String idToken,
    String? nonce,
    String? authorizationCode,
    String? name,
  }) {
    social.add(provider);
    return Completer<AuthSession>().future; // server still answering
  }
}

void main() {
  setUp(() => AppLocale.languageCode.value = 'en');

  testWidgets('Google on Register reaches the server after the picker',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final google = _GatedGoogle();
    final auth = _Auth();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
        authApiServiceProvider.overrideWithValue(auth),
        googleIdTokenSourceProvider.overrideWithValue(google),
        socialSignInOptionsProvider.overrideWithValue(
            const SocialSignInOptions(google: true, apple: false)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const RegisterScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(RegisterScreen)));

    await tester.tap(find.text(l10n.authSocialGoogle));
    // The picker stays open for a while.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    google.gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(auth.social, ['google'], reason: 'server never called');
    expect(find.text(l10n.authLoginUnexpectedError), findsNothing);

    // The request is in flight: another tap must not open a second picker.
    await tester.tap(find.text(l10n.authSocialGoogle));
    await tester.pump();
    expect(google.calls, 1, reason: 'busy flag lost: second picker opened');
  });
}
