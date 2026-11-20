import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/password_strength_meter.dart';

import '../../support/contrast_probe.dart';

/// Passwords built from every mix of the meter's rules (length, letter,
/// digit, symbol), in Latin and Arabic letters, plus random ones.
List<String> _passwords() {
  const letters = ['abc', 'سيرة'];
  const digits = '0123456789';
  const symbols = r'!@#$%^&*()-_=+ ';
  final out = <String>{''};
  for (final letter in letters) {
    for (var mask = 0; mask < 16; mask++) {
      final parts = <String>[
        if (mask & 1 != 0) letter,
        if (mask & 2 != 0) '42',
        if (mask & 4 != 0) '#',
      ];
      var p = parts.join();
      if (p.isEmpty) p = mask & 8 != 0 ? '' : '!';
      // Pad with the same classes to reach (or stay below) 8 characters.
      if (mask & 8 != 0) {
        while (p.length < 8) {
          p += p.isEmpty ? '_' : p[p.length - 1];
        }
      }
      out.add(p);
    }
  }
  final random = Random(12);
  const pool = 'abcXYZسيرت$digits$symbols';
  for (var i = 0; i < 40; i++) {
    out.add(String.fromCharCodes(List.generate(1 + random.nextInt(14),
        (_) => pool.codeUnitAt(random.nextInt(pool.length)))));
  }
  return out.toList();
}

void main() {
  final passwords = _passwords();

  test('the generated passwords reach every strength level', () {
    expect(
      passwords.map(PasswordStrengthMeter.evaluate).toSet(),
      PasswordStrength.values.toSet(),
    );
  });

  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      final label = '${dark ? 'dark' : 'light'} ${arabic ? 'ar' : 'en'}';
      testWidgets(
          'label is AA and filled segments are 3:1 on the page '
          '($label)', (tester) async {
        for (final password in passwords) {
          await tester.pumpWidget(MaterialApp(
            theme: dark
                ? AppTheme.darkFor(arabic: arabic)
                : AppTheme.lightFor(arabic: arabic),
            locale: Locale(arabic ? 'ar' : 'en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: PasswordStrengthMeter(
                  password: password,
                  english: !arabic,
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          final reason = '"$password" ($label)';

          // The level label carries the state as text.
          expectAllTextAa(reason);

          final level = PasswordStrengthMeter.evaluate(password);
          final active = switch (level) {
            PasswordStrength.empty => 0,
            PasswordStrength.weak => 1,
            PasswordStrength.medium => 2,
            PasswordStrength.strong => 3,
          };
          final segments = find
              .descendant(
                of: find.byType(PasswordStrengthMeter),
                matching: find.byType(AnimatedContainer),
              )
              .evaluate()
              .toList();
          expect(segments, hasLength(3), reason: reason);
          for (final (i, element) in segments.indexed) {
            if (i >= active) continue;
            final fill = ((element.widget as AnimatedContainer).decoration!
                    as BoxDecoration)
                .color!;
            for (final page in paintedBackgroundsOf(element)) {
              expect(
                AppContrast.ratio(fill, page),
                greaterThanOrEqualTo(3),
                reason: 'segment $i of $reason on $page',
              );
            }
          }
        }
      });
    }
  }
}
