import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/draft_restore_banner.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_footer.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_header.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// The CV wizard reads its labels from the label catalog, so a published
/// remote string replaces the bundled one, and an unpublished key keeps the
/// bundled ARB text.
RemoteL10nState _state(Map<String, Map<String, String>> strings) =>
    RemoteL10nState(
      bundles: {
        for (final e in strings.entries)
          e.key: RemoteStringBundle(code: e.key, version: 1, strings: e.value),
      },
    );

/// Arbitrary plain text (no ICU syntax) in Latin and Arabic script.
String _text(Random random) {
  const pool = ['Ab', 'z', ' ', '7', 'سيرة', 'ج', '-', '.', 'Q'];
  return 'x${List.generate(1 + random.nextInt(8), (_) => pool[random.nextInt(pool.length)]).join()}';
}

Future<void> _pump(
  WidgetTester tester,
  String code,
  RemoteL10nState state,
  Widget child,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightFor(arabic: code == 'ar'),
    locale: Locale(code),
    supportedLocales: appSupportedLocales(state),
    localizationsDelegates: appLocalizationsDelegates(state),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final random = Random(9071);

  for (final code in bundledLanguageCodes) {
    final bundled = lookupAppLocalizations(Locale(code));
    final english = code == 'en';

    testWidgets('$code: wizard footer and draft banner show remote labels',
        (tester) async {
      for (var run = 0; run < 4; run++) {
        final generate = '${_text(random)}-g';
        final restore = '${_text(random)}-r';
        await _pump(
          tester,
          code,
          _state({
            code: {'cvWizardGenerate': generate, 'cvDraftRestore': restore},
          }),
          Column(
            children: [
              DraftRestoreBanner(
                english: english,
                savedAt: null,
                onStartFresh: () {},
                onRestore: () {},
              ),
              WizardFooter(
                english: english,
                step: 3,
                stepCount: 4,
                isEditMode: false,
                isLoading: false,
                onBack: () {},
                onPrimary: () {},
              ),
            ],
          ),
        );
        expect(find.text(generate), findsOneWidget, reason: generate);
        expect(find.text(restore), findsOneWidget, reason: restore);
        expect(find.text(bundled.cvWizardGenerate), findsNothing);
        // Keys without a remote value keep the bundled catalog text.
        expect(find.text(bundled.cvDraftStartFresh), findsOneWidget);
        expect(find.text(bundled.back), findsOneWidget);
      }
    });

    testWidgets('$code: wizard header formats a remote placeholder string',
        (tester) async {
      for (var step = 0; step < 4; step++) {
        final prefix = _text(random);
        await _pump(
          tester,
          code,
          _state({
            code: {'cvWizardStepOf': '$prefix {step}/{total}'},
          }),
          WizardHeader(step: step, english: english, onStepTap: (_) {}),
        );
        expect(find.text('$prefix ${step + 1}/4'), findsOneWidget);
        expect(find.text(bundled.cvWizardStepOf(step + 1, 4)), findsNothing);
      }
    });
  }
}
