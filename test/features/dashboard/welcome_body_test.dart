import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/splash/welcome_body.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  // The agreed welcome (Salem, 2026-10-24) in every language, theme and on
  // small and large phones: logo, slogan, the five-point value card, both
  // actions reachable, nothing overflowing.
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(430, 932)
      ]) {
        testWidgets('$language dark=$dark ${size.width}x${size.height}',
            (tester) async {
          AppLocale.languageCode.value = language;
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          var registered = 0, signedIn = 0, privacy = 0;
          await tester.pumpWidget(MaterialApp(
            theme: dark
                ? AppTheme.darkFor(arabic: language == 'ar')
                : AppTheme.lightFor(arabic: language == 'ar'),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: WelcomeBody(
                onRegister: () => registered++,
                onLogin: () => signedIn++,
                onPrivacy: () => privacy++,
              ),
            ),
          ));
          await tester.pumpAndSettle();
          final en = language == 'en';
          final l10n = lookupAppLocalizations(Locale(language));

          expect(find.byKey(WelcomeBody.logoKey), findsOneWidget);
          expect(find.text(WelcomeBody.slogan(l10n)), findsOneWidget);
          final card = find.byKey(WelcomeBody.valueCardKey);
          expect(
              find.descendant(
                  of: card, matching: find.text(WelcomeBody.valueTitle(l10n))),
              findsOneWidget);
          final points = WelcomeBody.valuePoints(l10n);
          expect(points, hasLength(5));
          for (final point in points) {
            expect(find.descendant(of: card, matching: find.text(point)),
                findsOneWidget);
          }
          for (final icon in WelcomeBody.pointIcons) {
            expect(find.descendant(of: card, matching: find.byIcon(icon)),
                findsOneWidget);
          }

          // Order matches the agreed design: logo, slogan, card, actions.
          double top(Finder f) => tester.getTopLeft(f).dy;
          final create =
              find.text(en ? 'Create New Account' : 'إنشاء حساب جديد');
          final signIn = find.text(en ? 'Sign In' : 'تسجيل الدخول');
          expect(top(find.byKey(WelcomeBody.logoKey)),
              lessThan(top(find.byKey(WelcomeBody.sloganKey))));
          expect(top(find.byKey(WelcomeBody.sloganKey)), lessThan(top(card)));
          expect(top(card), lessThan(top(create)));
          expect(top(create), lessThan(top(signIn)));

          for (final (finder, count) in [
            (create, () => registered),
            (signIn, () => signedIn),
            (
              find.text(en ? 'Privacy Policy' : 'سياسة الخصوصية'),
              () => privacy
            ),
          ]) {
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            await tester.tap(finder);
            expect(count(), 1);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
