import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_cards.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_list_field.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

void main() {
  late TextEditingController text;
  late GlobalKey<FormState> form;

  Future<void> pump(WidgetTester tester, {required String language, bool dark = false}) async {
    AppLocale.languageCode.value = language;
    tester.view.physicalSize = const Size(1170, 2532 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final english = language == 'en';
    await tester.pumpWidget(MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: !english)
          : AppTheme.lightFor(arabic: !english),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: form,
            child: EntryListField<ExperienceEntry>(
              controller: text,
              english: english,
              autovalidateMode: AutovalidateMode.disabled,
              parse: parseExperience,
              serialize: (e) => serializeExperience(e, language),
              problems: experienceProblems,
              blank: const ExperienceEntry(),
              isBlank: (e) => e.isBlank,
              minimumCharacters: 20,
              addLabel: english ? 'Add another job' : 'إضافة خبرة أخرى',
              cardBuilder: (context, entry, onChanged, problems) =>
                  experienceCard(context, entry, onChanged, problems,
                      english: english),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder inCard(int index, String key) => find.descendant(
        of: find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('entry-') &&
            w.runtimeType.toString() == '_EntryCard'),
        matching: find.byKey(ValueKey(key)),
      ).at(index);

  Future<void> type(WidgetTester tester, int card, String key, String value) async {
    final field = find.descendant(of: inCard(card, key), matching: find.byType(TextField));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> pick(WidgetTester tester, int card, String key, int year, int month) async {
    final button = find.descendant(of: inCard(card, key), matching: find.byType(OutlinedButton));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('month-year-year')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$year').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('month-year-month-$month')));
    await tester.tap(find.byKey(const ValueKey('month-year-done')));
    await tester.pumpAndSettle();
  }

  setUp(() {
    text = TextEditingController();
    form = GlobalKey<FormState>();
  });

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('$language dark=$dark: two jobs typed and picked become the server text',
          (tester) async {
        await pump(tester, language: language, dark: dark);
        expect(form.currentState!.validate(), isFalse,
            reason: 'an empty experience is not accepted');

        await type(tester, 0, 'entry-title', 'E-Commerce Specialist');
        await type(tester, 0, 'entry-company', 'Al-Dawaa');
        await pick(tester, 0, 'entry-start', 2025, 11);
        await tester.tap(find.descendant(
            of: inCard(0, 'entry-current'), matching: find.byType(Checkbox)));
        await tester.pump();
        await type(tester, 0, 'entry-description', 'Ran Google Ads\nRaised ROAS by 30%');

        await tester.ensureVisible(find.byKey(const ValueKey('entry-add')));
        await tester.tap(find.byKey(const ValueKey('entry-add')));
        await tester.pumpAndSettle();
        await type(tester, 1, 'entry-title', 'مسؤول مبيعات');
        await type(tester, 1, 'entry-company', 'شركة النخبة');
        await pick(tester, 1, 'entry-start', 2021, 3);
        await pick(tester, 1, 'entry-end', 2025, 10);
        await type(tester, 1, 'entry-description', 'إدارة حسابات كبار العملاء');

        expect(
          text.text,
          serializeExperience(const [
            ExperienceEntry(
              title: 'E-Commerce Specialist',
              company: 'Al-Dawaa',
              start: YearMonth(2025, 11),
              current: true,
              description: 'Ran Google Ads\nRaised ROAS by 30%',
            ),
            ExperienceEntry(
              title: 'مسؤول مبيعات',
              company: 'شركة النخبة',
              start: YearMonth(2021, 3),
              end: YearMonth(2025, 10),
              description: 'إدارة حسابات كبار العملاء',
            ),
          ], language),
        );
        expect(form.currentState!.validate(), isTrue);
        await tester.pumpAndSettle();
        expectAllTextAa('$language dark=$dark filled');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('missing pieces are named per field after trying to continue',
      (tester) async {
    await pump(tester, language: 'en');
    await type(tester, 0, 'entry-title', 'Accountant');
    expect(find.text('Required'), findsNothing, reason: 'quiet while typing');

    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Complete the highlighted fields.'), findsOneWidget);
    expect(find.descendant(of: inCard(0, 'entry-company'), matching: find.text('Required')),
        findsOneWidget);
    expect(find.text('Choose a start date'), findsOneWidget);
    expect(find.descendant(of: inCard(0, 'entry-title'), matching: find.text('Required')),
        findsNothing);

    await pick(tester, 0, 'entry-start', 2020, 5);
    await pick(tester, 0, 'entry-end', 2019, 1);
    await tester.pumpAndSettle();
    expect(find.text('Ends before it starts'), findsOneWidget);
  });

  testWidgets('outside text changes (draft, AI, achievement) are read back',
      (tester) async {
    await pump(tester, language: 'en');
    text.text = 'Engineer — Acme — 2020 - 2022\n- Built APIs.';
    await tester.pumpAndSettle();
    expect(find.descendant(of: inCard(0, 'entry-company'), matching: find.text('Acme')),
        findsOneWidget);

    text.text = '${text.text}\nAchieved 20% faster releases';
    await tester.pumpAndSettle();
    final description = tester.widget<TextField>(find.descendant(
        of: inCard(0, 'entry-description'), matching: find.byType(TextField)));
    expect(description.controller!.text, 'Built APIs.\nAchieved 20% faster releases');

    // Removing the only job leaves one empty card, and empty text.
    await tester.tap(find.byKey(const ValueKey('entry-remove-0')));
    await tester.pumpAndSettle();
    expect(text.text, isEmpty);
    expect(find.byKey(const ValueKey('entry-title')), findsOneWidget);
  });
}
