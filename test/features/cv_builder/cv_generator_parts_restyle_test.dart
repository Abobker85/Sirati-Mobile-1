// Ticket 14 (iOS 26 restyle round 2): the generator's exit dialogs, the job
// title picker field and the AI enhancement result card, AR/EN x light/dark
// on the plain and the grouped page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/exit_dialogs.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';

import '../../support/contrast_probe.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget body, {
  required String language,
  required bool dark,
  bool grouped = false,
  double width = 390,
}) async {
  AppLocale.languageCode.value = language;
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final english = language == 'en';
  Widget page = Scaffold(
    body: ListView(padding: const EdgeInsets.all(20), children: [body]),
  );
  if (grouped) page = GroupedSurface(child: page);
  await tester.pumpWidget(MaterialApp(
    theme: dark
        ? AppTheme.darkFor(arabic: !english)
        : AppTheme.lightFor(arabic: !english),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: page,
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      final tag = '$language ${dark ? 'dark' : 'light'}';

      testWidgets('$tag: exit dialogs are AA and return each choice',
          (tester) async {
        Object? result;
        await _pump(
          tester,
          language: language,
          dark: dark,
          Builder(
            builder: (context) => Column(children: [
              TextButton(
                key: const ValueKey('open-discard'),
                onPressed: () async =>
                    result = await confirmDiscardEdits(context),
                child: const Text('discard'),
              ),
              TextButton(
                key: const ValueKey('open-save'),
                onPressed: () async => result = await askSaveDraft(context),
                child: const Text('save'),
              ),
            ]),
          ),
        );
        final l10n = AppLocalizations.of(
            tester.element(find.byKey(const ValueKey('open-save'))));

        for (final (label, expected) in [
          (l10n.cancel, false),
          (l10n.cvDiscard, true),
        ]) {
          await tester.tap(find.byKey(const ValueKey('open-discard')));
          await tester.pumpAndSettle();
          expectAllTextAa('$tag discard dialog');
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(result, expected, reason: label);
        }

        for (final (label, expected) in [
          (l10n.cancel, WizardExitAction.cancel),
          (l10n.cvDiscard, WizardExitAction.discard),
          (l10n.cvSaveDraft, WizardExitAction.saveDraft),
        ]) {
          await tester.tap(find.byKey(const ValueKey('open-save')));
          await tester.pumpAndSettle();
          expectAllTextAa('$tag save dialog');
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(result, expected, reason: label);
        }
      });

      for (final grouped in [false, true]) {
        final where = grouped ? 'grouped' : 'plain';

        testWidgets('$tag $where: picker is a filled field like the others',
            (tester) async {
          await _pump(
            tester,
            language: language,
            dark: dark,
            grouped: grouped,
            // Wide enough that the hint is one line in the test font (square
            // glyphs): a wrapped hint is taller by design, a single-line one
            // must match a text field.
            width: 600,
            Builder(builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JobTitlePickerField(
                    titles: const [],
                    value: null,
                    onChanged: (_) {},
                    english: language == 'en',
                  ),
                  const SizedBox(height: 12),
                  AppTextFormField(
                    key: const ValueKey('reference-field'),
                    controller: TextEditingController(),
                    hintText:
                        AppLocalizations.of(context).sharedJobTitleSelectHint,
                    prefixIcon: const Icon(Icons.work_outline_rounded),
                  ),
                ],
              );
            }),
          );
          final picker = find.descendant(
              of: find.byType(JobTitlePickerField),
              matching: find.byType(InputDecorator));
          final decoration = tester
              .widget<InputDecorator>(picker)
              .decoration
              .applyDefaults(
                  Theme.of(tester.element(picker)).inputDecorationTheme);
          expect(decoration.filled, isTrue);
          expect(
              decoration.fillColor, PageSurface.fillOf(tester.element(picker)));
          expect(decoration.enabledBorder, isA<FilledFieldBorder>());
          expect(decoration.enabledBorder!.borderSide, BorderSide.none);
          final reference = find.descendant(
              of: find.byKey(const ValueKey('reference-field')),
              matching: find.byType(InputDecorator));
          expect(
              tester.getSize(picker).height, tester.getSize(reference).height);
          expectAllTextAa('$tag $where picker');
        });

        testWidgets('$tag $where: AI result card is borderless and AA',
            (tester) async {
          final controller = TextEditingController(
              text: 'Built and ran payment APIs for retail clients.');
          addTearDown(controller.dispose);
          await _pump(
            tester,
            language: language,
            dark: dark,
            grouped: grouped,
            AiCvField(
              field: 'summary',
              controller: controller,
              english: language == 'en',
              isLoading: false,
              helperText: 'Helper',
              minimumCharacters: 20,
              onEnhance: () {},
              onDismissResult: () {},
              result: const {
                'changes_made': ['Tightened the opening line'],
                'missing_facts': ['Add the team size'],
                'ats_keywords_added': ['REST APIs', 'تحليل'],
                'unverified_claims': [
                  {'text': '2019', 'kind': 'date'},
                  {'text': 'Acme', 'kind': 'company'},
                ],
              },
              child: AppTextFormField(controller: controller),
            ),
          );
          final card = tester
              .widget<Container>(
                  find.byKey(const Key('enhancement_result_summary')))
              .decoration! as BoxDecoration;
          expect(card.border, isNull);
          expect(card.color,
              PageSurface.fillOf(tester.element(find.byType(AiCvField))));
          expectAllTextAa('$tag $where AI result');
          expectAllProgressIndicatorsAa('$tag $where AI result');
        });
      }
    }
  }
}
