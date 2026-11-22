import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

import '../support/contrast_probe.dart';
import '../support/no_gradient.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required bool english,
  required bool dark,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: !english),
      darkTheme: AppTheme.darkFor(arabic: !english),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(english ? 'en' : 'ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final english in [false, true]) {
    for (final dark in [false, true]) {
      final label = '${english ? 'en' : 'ar'} ${dark ? 'dark' : 'light'}';

      testWidgets('the profile avatar is a flat fill, initials AA ($label)',
          (tester) async {
        for (final onTap in <VoidCallback?>[null, () {}]) {
          await _pump(
            tester,
            Scaffold(
              body: Center(
                child: ProfileAvatar(
                  label: english ? 'AB' : 'نور',
                  size: 46,
                  onTap: onTap,
                ),
              ),
            ),
            english: english,
            dark: dark,
          );
          expectNoGradient(find.byType(ProfileAvatar), 'avatar $label');
          final text = tester.widget<Text>(
            find.descendant(
                of: find.byType(ProfileAvatar), matching: find.byType(Text)),
          );
          for (final background
              in paintedBackgroundsOf(find
                  .descendant(
                      of: find.byType(ProfileAvatar),
                      matching: find.byType(Text))
                  .evaluate()
                  .single)) {
            expect(
              AppContrast.ratio(text.style!.color!, background),
              greaterThanOrEqualTo(4.5),
              reason: 'initials on $background ($label)',
            );
          }
        }
      });

      testWidgets('the session expired screen paints no gradient ($label)',
          (tester) async {
        await _pump(tester, const SessionExpiredScreen(),
            english: english, dark: dark);
        expectNoGradient(find.byType(SessionExpiredScreen), 'session $label');
      });
    }
  }
}
