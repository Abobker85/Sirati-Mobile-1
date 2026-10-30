import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/ai_error_message.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

void main() {
  final random = Random(11);
  String detail() => String.fromCharCodes(List.generate(
      1 + random.nextInt(40), (_) => 0x20 + random.nextInt(0x5E)));

  for (final code in ['ar', 'en']) {
    final l10n = lookupAppLocalizations(Locale(code));

    test('$code: a truncation code always names CV length, never the code', () {
      for (var i = 0; i < 50; i++) {
        final error = '${AiErrorMessage.tooLongCode}${detail()}';
        for (final message in [
          AiErrorMessage.generationFailed(error, l10n),
          AiErrorMessage.suggestionsFailed(error, l10n),
          AiErrorMessage.localFallback(error, l10n),
        ]) {
          expect(message, l10n.aiErrorTooLong);
        }
      }
    });

    test('$code: other errors keep the server detail inside the label', () {
      for (var i = 0; i < 50; i++) {
        final error = 'x${detail()}';
        expect(AiErrorMessage.generationFailed(error, l10n),
            l10n.aiGenerationFailed(error));
        expect(AiErrorMessage.suggestionsFailed(error, l10n),
            l10n.aiSuggestionsFailed(error));
        expect(AiErrorMessage.localFallback(error, l10n),
            l10n.aiLocalFallback(error));
      }
    });

    test('$code: a missing detail asks to try again', () {
      for (final error in [null, '', '   ', '\n\t']) {
        expect(AiErrorMessage.generationFailed(error, l10n),
            l10n.aiGenerationFailed(l10n.aiErrorTryAgain));
      }
    });
  }
}
