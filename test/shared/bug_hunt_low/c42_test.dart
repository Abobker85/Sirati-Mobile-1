import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/password_strength_meter.dart';

// Stated rules: length >= 8, has letter, has digit, has symbol.
// 0-1 -> weak, 2-3 -> medium, 4 -> strong.
String _toArabicIndic(String s) => s.replaceAllMapped(
    RegExp(r'[0-9]'), (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)));

void main() {
  const latinDigitPasswords = [
    'abc!1234',
    'Pass word 2024',
    'كلمة!123',
    'x9',
    '12345678',
    '1!',
    'سرّي_٢٠٢٤_ok1',
  ];

  test('C42a: Arabic-Indic digits count as digits, like Latin ones', () {
    for (final p in latinDigitPasswords) {
      expect(PasswordStrengthMeter.evaluate(_toArabicIndic(p)),
          PasswordStrengthMeter.evaluate(p),
          reason: '"${_toArabicIndic(p)}" vs "$p"');
    }
  });

  test('C42b: letters of any script count as letters, not symbols', () {
    for (final (accented, plain) in [
      ('Pässwörd1', 'Password1'),
      ('Ünïcödé9', 'Unicode9'),
      ('Привет12', 'Privet12'),
      ('گچپژ1234', 'abcd1234'),
      ('éé', 'ee'),
    ]) {
      expect(PasswordStrengthMeter.evaluate(accented),
          PasswordStrengthMeter.evaluate(plain),
          reason: '"$accented" vs "$plain"');
    }
  });

  test('C42c: length counts characters, not UTF-16 code units', () {
    // 4 emoji: 4 characters (below 8), only a symbol -> one rule -> weak.
    expect(PasswordStrengthMeter.evaluate('😀😀😀😀'), PasswordStrength.weak);
    // 7 characters with letter, digit, symbol, one of them astral: not strong.
    expect(PasswordStrengthMeter.evaluate('ab1😀cde'), PasswordStrength.medium);
  });
}
