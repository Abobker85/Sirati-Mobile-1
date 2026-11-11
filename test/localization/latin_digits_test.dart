import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;

/// The app shows every number in 0-9 in every language (SIRATI-63): no
/// label and no locale formatter may paint ٠-٩ or ۰-۹.
final _nonLatinDigit = RegExp('[٠-٩۰-۹]');

void main() {
  test('no bundled label in any language contains Arabic or Persian digits',
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

  testWidgets('Arabic dates and numbers from the locale formatters use 0-9',
      (tester) async {
    late MaterialLocalizations material;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
    for (final n in [0, 7, 19, 99, 1234, 987654321]) {
      final text = material.formatDecimal(n);
      expect(_nonLatinDigit.hasMatch(text), isFalse, reason: text);
      final number = intl.NumberFormat.decimalPattern('ar').format(n);
      expect(_nonLatinDigit.hasMatch(number), isFalse, reason: number);
    }
  });
}
