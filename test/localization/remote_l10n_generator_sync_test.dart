import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';

import '../../tool/gen_remote_l10n.dart';

/// Dart tokens of [source] (whitespace, comments and trailing commas
/// ignored), so `dart format` of the committed file does not matter.
List<String> _tokens(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: true).unit;
  final tokens = <String>[];
  Token? token = unit.beginToken;
  while (token != null && token.type != TokenType.EOF) {
    final next = token.next;
    final trailingComma = token.type == TokenType.COMMA &&
        next != null &&
        (next.type == TokenType.CLOSE_PAREN ||
            next.type == TokenType.CLOSE_SQUARE_BRACKET ||
            next.type == TokenType.CLOSE_CURLY_BRACKET);
    if (!trailingComma) tokens.add(token.lexeme);
    token = next;
  }
  return tokens;
}

void main() {
  test(
      'lib/l10n/remote_app_localizations.dart is in sync with the template '
      'ARB (run: dart run tool/gen_remote_l10n.dart)', () {
    final generated =
        generateRemoteLocalizations(File(templateArbPath).readAsStringSync());
    final committed = File(outputPath).readAsStringSync();
    expect(_tokens(committed), _tokens(generated));
  });

  test('the generated wrapper covers every template key, in ARB order', () {
    final arb = jsonDecode(File(templateArbPath).readAsStringSync()) as Map;
    final arbKeys =
        arb.keys.cast<String>().where((k) => !k.startsWith('@')).toList();
    expect(RemoteAppLocalizations.debugPlaceholderTypes.keys.toList(), arbKeys);
  });

  test('a new ARB key changes the generated output (sync check bites)', () {
    const before = '{"@@locale":"ar","a":"x"}';
    const after = '{"@@locale":"ar","a":"x","b":"y {n}",'
        '"@b":{"placeholders":{"n":{"type":"int"}}}}';
    final first = _tokens(generateRemoteLocalizations(before));
    final second = _tokens(generateRemoteLocalizations(after));
    expect(first, isNot(second));
    expect(second, contains('b'));
  });

  test('typed placeholders with formats are emitted with their metadata', () {
    final source = generateRemoteLocalizations('''
{
  "@@locale": "ar",
  "total": "{amount} on {day}",
  "@total": {"placeholders": {
    "amount": {"type": "double", "format": "currency",
      "optionalParameters": {"symbol": "SAR", "decimalDigits": 2}},
    "day": {"type": "DateTime", "format": "yMMMd+jm"}
  }}
}
''');
    expect(source, contains('String total(double amount, DateTime day)'));
    expect(source, contains("format: 'currency'"));
    expect(source, contains("'symbol': 'SAR'"));
    expect(source, contains("format: 'yMMMd+jm'"));
  });

  test('invalid template ICU fails generation loudly', () {
    expect(
      () => generateRemoteLocalizations('{"a":"{n, plural, one{x}}"}'),
      throwsFormatException,
    );
  });
}
