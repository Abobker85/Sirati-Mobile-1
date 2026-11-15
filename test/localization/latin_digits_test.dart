import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';

/// The app shows every number in 0-9 in every language (SIRATI-63): no
/// label and no locale formatter may paint any other script's digits
/// (٠-٩, ۰-۹, ০-৯, …).
final _nonLatinDigit = RegExp(r'[^\P{Nd}0-9]', unicode: true);

void main() {
  test('no bundled label in any language contains non-0-9 digits',
      () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();
    expect(arbs.length, greaterThanOrEqualTo(2));

    final offenders = <String>[];
    for (final file in arbs) {
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in arb.entries) {
        if (entry.key.startsWith('@')) continue;
        if (_nonLatinDigit.hasMatch('${entry.value}')) {
          offenders.add('${file.path}: ${entry.key} = ${entry.value}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  // Bundled languages, plus languages whose Flutter date data has native
  // digits even on older SDKs, so the guard is exercised on every SDK.
  for (final code in ['ar', 'en', 'fa', 'bn', 'mr', 'my', 'as']) {
    testWidgets('$code dates and numbers through the app delegates use 0-9',
        (tester) async {
      late MaterialLocalizations material;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(code),
        supportedLocales: [
          Locale(code),
          const Locale('ar'),
          const Locale('en')
        ],
        localizationsDelegates:
            appLocalizationsDelegates(RemoteL10nState.empty),
        home: Builder(builder: (context) {
          material = MaterialLocalizations.of(context);
          return const SizedBox();
        }),
      ));

      // Every day of a year, so each month name and day count is covered.
      for (var day = 0; day < 366; day++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: day));
        for (final text in [
          material.formatMediumDate(date),
          material.formatFullDate(date),
          material.formatCompactDate(date),
          material.formatShortDate(date),
          material.formatYear(date),
          material.formatMonthYear(date),
        ]) {
          expect(_nonLatinDigit.hasMatch(text), isFalse, reason: text);
        }
      }
      if (code == 'ar' || code == 'en') {
        for (final n in [0, 7, 19, 99, 1234, 987654321]) {
          final text = material.formatDecimal(n);
          expect(_nonLatinDigit.hasMatch(text), isFalse, reason: text);
          final number = intl.NumberFormat.decimalPattern(code).format(n);
          expect(_nonLatinDigit.hasMatch(number), isFalse, reason: number);
        }
      }
    });
  }
}
