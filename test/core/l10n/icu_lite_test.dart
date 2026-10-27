import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sirati/core/l10n/icu_lite.dart';
import 'package:sirati/core/l10n/remote_strings.dart';

/// Random text that contains no ICU syntax (`{` `}`), but does contain
/// apostrophes, `#`, commas, digits, Arabic, Latin and whitespace.
String _plainText(Random random, {int maxLength = 40}) {
  const pool = [
    'a', 'Z', ' ', ',', "'", "''", '#', '=', '0', '7', 'ي', 'ة', 'لا', //
    '\n', '\t', r'$', r'\', '%', 'é', '…', '‏', 'other', 'plural',
  ];
  final length = random.nextInt(maxLength);
  return List.generate(length, (_) => pool[random.nextInt(pool.length)]).join();
}

void main() {
  final random = Random(20261027);

  group('plain text', () {
    test('text without braces is returned verbatim (apostrophes literal)', () {
      for (var i = 0; i < 500; i++) {
        final text = _plainText(random);
        expect(IcuLite.format(text, locale: 'ar'), text);
      }
    });

    test("quoted braces are not escapes: '{x}' substitutes x", () {
      for (var i = 0; i < 200; i++) {
        final value = _plainText(random);
        expect(
          IcuLite.format("'{x}' and ''{x}''", locale: 'en', args: {'x': value}),
          "'$value' and ''$value''",
        );
      }
    });
  });

  group('argument substitution', () {
    test('substitutes arbitrary values for arbitrary surrounding text', () {
      for (var i = 0; i < 300; i++) {
        final before = _plainText(random);
        final after = _plainText(random);
        final first = _plainText(random);
        final second = random.nextInt(1 << 20);
        final message = '$before{first}{ second }$after{first}';
        expect(
          IcuLite.format(
            message,
            locale: 'ar',
            args: {'first': first, 'second': second},
          ),
          '$before$first$second$after$first',
        );
      }
    });

    test('values containing ICU syntax are inserted literally', () {
      const nasty = ['{', '}', '{x}', "'", '{n, plural, other{#}}', r'$x'];
      for (final value in nasty) {
        expect(
          IcuLite.format('<{x}>', locale: 'en', args: {'x': value}),
          '<$value>',
        );
      }
    });

    test('IcuArgument text is shown while its value drives plural choice', () {
      expect(
        IcuLite.format(
          '{n, plural, one{one {n}} other{many {n}}}',
          locale: 'en',
          args: {'n': const IcuArgument(1, 'ONE')},
        ),
        'one ONE',
      );
    });

    test('a missing argument throws IcuFormatException', () {
      expect(
        () => IcuLite.format('Hi {name}', locale: 'en'),
        throwsA(isA<IcuFormatException>()),
      );
      expect(
        () => IcuLite.format('{n, plural, other{x}}', locale: 'en'),
        throwsA(isA<IcuFormatException>()),
      );
    });
  });

  group('plural', () {
    const keywordMessage = '{n, plural, zero{Z {n}} one{O {n}} two{T {n}} '
        'few{F {n}} many{M {n}} other{X {n}}}';

    String expectedFor(num n, String locale) => intl.Intl.pluralLogic(
          n,
          locale: locale,
          zero: 'Z $n',
          one: 'O $n',
          two: 'T $n',
          few: 'F $n',
          many: 'M $n',
          other: 'X $n',
        );

    test('Arabic selects all six CLDR categories like Intl.pluralLogic', () {
      final seen = <String>{};
      for (var n = 0; n <= 1200; n++) {
        final actual =
            IcuLite.format(keywordMessage, locale: 'ar', args: {'n': n});
        expect(actual, expectedFor(n, 'ar'), reason: 'n=$n');
        seen.add(actual.split(' ').first);
      }
      expect(seen, {'Z', 'O', 'T', 'F', 'M', 'X'});
    });

    test('other locales follow their own rules', () {
      for (final locale in ['en', 'fr', 'ru', 'pl', 'cy', 'ja', 'xx']) {
        for (var i = 0; i < 300; i++) {
          final n = random.nextInt(100000);
          expect(
            IcuLite.format(keywordMessage, locale: locale, args: {'n': n}),
            expectedFor(n, locale),
            reason: '$locale n=$n',
          );
        }
      }
    });

    test('=0/=1/=2 win for their exact value and act as zero/one/two', () {
      const message = '{n, plural, =0{none} =1{single} =2{pair} '
          'few{few {n}} other{other {n}}}';
      expect(IcuLite.format(message, locale: 'ar', args: {'n': 0}), 'none');
      expect(IcuLite.format(message, locale: 'ar', args: {'n': 1}), 'single');
      expect(IcuLite.format(message, locale: 'ar', args: {'n': 2}), 'pair');
      for (var n = 3; n < 500; n++) {
        expect(
          IcuLite.format(message, locale: 'ar', args: {'n': n}),
          intl.Intl.pluralLogic(n,
              locale: 'ar', few: 'few $n', other: 'other $n'),
        );
      }
    });

    test('text around and inside branches is kept, including whitespace', () {
      expect(
        IcuLite.format(
          'Total: {n,plural,  one { one item } other{{n} items}} left.',
          locale: 'en',
          args: {'n': 1},
        ),
        'Total:  one item  left.',
      );
    });

    test('a non-numeric plural argument throws', () {
      expect(
        () => IcuLite.format(keywordMessage, locale: 'en', args: {'n': 'x'}),
        throwsA(isA<IcuFormatException>()),
      );
    });
  });

  group('select and nesting', () {
    test('select picks the exact branch, else other, for arbitrary choices',
        () {
      const message = '{s, select, a{A} b{B} other{O:{s}}}';
      expect(IcuLite.format(message, locale: 'en', args: {'s': 'a'}), 'A');
      expect(IcuLite.format(message, locale: 'en', args: {'s': 'b'}), 'B');
      for (var i = 0; i < 200; i++) {
        final choice = _plainText(random, maxLength: 8);
        if (choice == 'a' || choice == 'b') continue;
        expect(
          IcuLite.format(message, locale: 'en', args: {'s': choice}),
          'O:$choice',
        );
      }
    });

    test('plural inside select inside plural', () {
      const message = '{a, plural, one{{g, select, f{{b, plural, one{1f} '
          'other{{b}f}}} other{{b, plural, one{1x} other{{b}x}}}}} '
          'other{many}}';
      expect(
        IcuLite.format(message, locale: 'en', args: {'a': 1, 'g': 'f', 'b': 1}),
        '1f',
      );
      expect(
        IcuLite.format(message, locale: 'en', args: {'a': 1, 'g': 'm', 'b': 5}),
        '5x',
      );
      expect(
        IcuLite.format(message, locale: 'en', args: {'a': 2, 'g': 'f', 'b': 5}),
        'many',
      );
    });

    test('argumentNames lists every name once in first-use order', () {
      expect(
        IcuLite.argumentNames('{b} {a, plural, other{{c}{b}}} {d, select, '
            'x{{e}} other{}}'),
        ['b', 'a', 'c', 'd', 'e'],
      );
    });
  });

  group('malformed messages throw IcuFormatException', () {
    const malformed = [
      '{',
      '}',
      'a } b',
      '{name',
      '{}',
      '{ }',
      '{1x}',
      '{na-me}',
      '{n, plural}',
      '{n, plural,}',
      '{n, plural, one{x}}',
      '{n, plural, other{x}',
      '{n, plural, other x}',
      '{n, plural, =3{x} other{y}}',
      '{n, plural, couple{x} other{y}}',
      '{n, plural, one{a} one{b} other{c}}',
      '{n, selectordinal, other{x}}',
      '{n, number}',
      '{n, date, short}',
      '{s, select, a{x}}',
      '{s, select, other{{t}}',
      '{n plural, other{x}}',
    ];

    for (final message in malformed) {
      test(message, () {
        expect(
          () => IcuLite.format(
            message,
            locale: 'en',
            args: {'n': 1, 's': 'a', 't': 't', 'name': 'x'},
          ),
          throwsA(isA<IcuFormatException>()),
        );
      });
    }

    test('nesting deeper than maxDepth throws instead of overflowing', () {
      var message = 'x';
      for (var i = 0; i < IcuLite.maxDepth + 4; i++) {
        message = '{s, select, other{$message}}';
      }
      expect(
        () => IcuLite.format(message, locale: 'en', args: {'s': 'a'}),
        throwsA(isA<IcuFormatException>()),
      );
      expect(
        () => IcuLite.format('{' * 100000, locale: 'en'),
        throwsA(isA<IcuFormatException>()),
      );
    });

    test('random syntax soup either formats or throws IcuFormatException', () {
      const pool = [
        '{', '}', ',', ' ', 'n', 's', 'plural', 'select', 'other', 'one', //
        '=0', '=1', '=5', "'", '#', 'x',
      ];
      for (var i = 0; i < 5000; i++) {
        final message = List.generate(
          random.nextInt(30),
          (_) => pool[random.nextInt(pool.length)],
        ).join();
        try {
          IcuLite.format(message, locale: 'ar', args: {'n': 3, 's': 'x'});
        } on IcuFormatException {
          // expected for malformed soup
        }
      }
    });
  });

  group('L10nPlaceholderFormat matches intl', () {
    setUpAll(() async {
      await initializeDateFormatting('en');
      await initializeDateFormatting('ar');
    });

    test('numbers without a format print like string interpolation', () {
      for (var i = 0; i < 200; i++) {
        final n = random.nextInt(1 << 30) - (1 << 29);
        expect(L10nPlaceholderFormat.number(n, 'ar'), '$n');
      }
    });

    test('named number formats use the matching NumberFormat constructor', () {
      for (final locale in ['en', 'ar']) {
        for (var i = 0; i < 50; i++) {
          final n = random.nextDouble() * 1000000;
          expect(
            L10nPlaceholderFormat.number(n, locale, format: 'compact'),
            intl.NumberFormat.compact(locale: locale).format(n),
          );
          expect(
            L10nPlaceholderFormat.number(n, locale, format: 'decimalPattern'),
            intl.NumberFormat.decimalPattern(locale).format(n),
          );
          expect(
            L10nPlaceholderFormat.number(
              n,
              locale,
              format: 'currency',
              optional: const {'symbol': 'SAR', 'decimalDigits': 1},
            ),
            intl.NumberFormat.currency(
              locale: locale,
              symbol: 'SAR',
              decimalDigits: 1,
            ).format(n),
          );
        }
      }
    });

    test('date skeletons (joined with +) and custom patterns', () {
      for (var i = 0; i < 50; i++) {
        final date = DateTime.utc(2000 + random.nextInt(60),
            1 + random.nextInt(12), 1 + random.nextInt(28), random.nextInt(24));
        for (final locale in ['en', 'ar']) {
          expect(
            L10nPlaceholderFormat.date(date, locale, format: 'yMd'),
            intl.DateFormat.yMd(locale).format(date),
          );
          expect(
            L10nPlaceholderFormat.date(date, locale, format: 'yMMMd+jm'),
            intl.DateFormat.yMMMd(locale).add_jm().format(date),
          );
          expect(
            L10nPlaceholderFormat.date(date, locale,
                format: 'dd/MM/yyyy', custom: true),
            intl.DateFormat('dd/MM/yyyy', locale).format(date),
          );
        }
      }
    });
  });
}
