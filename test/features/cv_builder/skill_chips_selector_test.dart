import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Widget _wrap(Widget child, {bool english = true}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: Locale(english ? 'en' : 'ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  testWidgets(
      'SkillChipsSelector parses initial comma-separated skills and renders chips',
      (tester) async {
    final controller = TextEditingController(text: 'Flutter, Dart, Firebase');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(
      SkillChipsSelector(
        controller: controller,
        targetJobTitle: 'Mobile Developer',
        english: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Flutter'), findsWidgets);
    expect(find.text('Dart'), findsWidgets);
    expect(find.text('Firebase'), findsWidgets);
    expect(find.text('Selected Skills (3)'), findsOneWidget);
  });

  testWidgets('tapping delete icon on chip removes it and updates controller',
      (tester) async {
    final controller = TextEditingController(text: 'Flutter, Dart, Firebase');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(
      SkillChipsSelector(
        controller: controller,
        targetJobTitle: 'Mobile Developer',
        english: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap delete on Flutter (first chip)
    final closeIcon = find.descendant(
      of: find.byKey(const ValueKey('selected_skill_0')),
      matching: find.byIcon(Icons.close_rounded),
    );
    await tester.tap(closeIcon);
    await tester.pumpAndSettle();

    expect(controller.text, 'Dart, Firebase');
    expect(find.text('Selected Skills (2)'), findsOneWidget);
  });

  testWidgets('adding custom skill updates chips and controller',
      (tester) async {
    final controller = TextEditingController(text: 'Flutter');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(
      SkillChipsSelector(
        controller: controller,
        targetJobTitle: 'Mobile Developer',
        english: true,
      ),
    ));
    await tester.pumpAndSettle();

    final inputField = find.byType(TextField);
    await tester.enterText(inputField, 'Docker');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(controller.text, 'Flutter, Docker');
    expect(find.text('Selected Skills (2)'), findsOneWidget);
    expect(find.text('Docker'), findsWidgets);
  });

  testWidgets('tapping suggested skill chip adds it to selected skills',
      (tester) async {
    final controller = TextEditingController(text: 'Flutter');
    addTearDown(controller.dispose);

    const jobTitle = JobTitle(
      id: 1,
      slug: 'flutter-developer',
      nameAr: 'مطور فلاتر',
      nameEn: 'Flutter Developer',
      category: 'software',
      keywords: ['Dart', 'Bloc', 'REST APIs'],
      sortOrder: 1,
    );

    await tester.pumpWidget(_wrap(
      SkillChipsSelector(
        controller: controller,
        targetJobTitle: 'Flutter Developer',
        english: true,
        allJobTitles: const [jobTitle],
      ),
    ));
    await tester.pumpAndSettle();

    // The suggested chip for Bloc should exist
    final suggestedBloc = find.byKey(const ValueKey('suggested_skill_Bloc'));
    expect(suggestedBloc, findsOneWidget);

    await tester.tap(suggestedBloc);
    await tester.pumpAndSettle();

    expect(controller.text, 'Flutter, Bloc');
    expect(find.text('Selected Skills (2)'), findsOneWidget);
  });

  testWidgets('external controller update reflects in chips (two-way sync)',
      (tester) async {
    final controller = TextEditingController(text: 'Initial');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(
      SkillChipsSelector(
        controller: controller,
        targetJobTitle: 'Developer',
        english: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Initial'), findsOneWidget);

    // Simulate AI enhancement or external text modification
    controller.text = 'Enhanced A, Enhanced B';
    await tester.pumpAndSettle();

    expect(find.text('Enhanced A'), findsOneWidget);
    expect(find.text('Enhanced B'), findsOneWidget);
    expect(find.text('Selected Skills (2)'), findsOneWidget);
  });

  group('suggestions come only from the server job-title taxonomy', () {
    Future<List<String>> suggestionsFor(
      WidgetTester tester,
      String title,
      List<JobTitle> titles, {
      String selected = '',
    }) async {
      final controller = TextEditingController(text: selected);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(SkillChipsSelector(
        controller: controller,
        targetJobTitle: title,
        english: true,
        allJobTitles: titles,
      )));
      await tester.pumpAndSettle();
      return tester
          .widgetList<ActionChip>(find.byType(ActionChip))
          .map((c) => (c.key! as ValueKey<String>)
              .value
              .replaceFirst('suggested_skill_', ''))
          .toList();
    }

    JobTitle title(int id, String ar, String en, List<String> keywords) =>
        JobTitle(
          id: id,
          slug: 'title-$id',
          nameAr: ar,
          nameEn: en,
          category: 'any',
          keywords: keywords,
          sortOrder: id,
        );

    final random = Random(7);
    String word() => String.fromCharCodes(
        List.generate(3 + random.nextInt(6), (_) => 97 + random.nextInt(26)));

    testWidgets('a matching title suggests exactly its server keywords',
        (tester) async {
      for (var i = 0; i < 12; i++) {
        final keywords =
            {for (var k = 0; k < 1 + random.nextInt(6); k++) word()}.toList();
        final en = '${word()} ${word()}';
        final got = await suggestionsFor(
            tester, en, [title(1, 'مسمى ${word()}', en, keywords)]);
        expect(got, keywords, reason: en);
      }
    });

    for (final query in [
      'Senior Flutter Developer',
      'Laravel Backend Developer',
      'مطور فلاتر',
      'مدير مشاريع',
      'Customer Support Agent',
    ]) {
      testWidgets('no server match means no suggestions: $query',
          (tester) async {
        final got = await suggestionsFor(tester, query, [
          title(1, 'محاسب', 'Accountant', ['IFRS'])
        ]);
        expect(got, isEmpty);
      });
    }

    testWidgets('keywords of every matching title are merged, case-insensitive',
        (tester) async {
      final got = await suggestionsFor(tester, 'Data Analyst', [
        title(1, 'محلل بيانات', 'Data Analyst', ['SQL', 'Python']),
        title(2, 'محلل', 'Analyst', ['sql', 'Excel']),
        title(3, 'مصمم', 'Designer', ['Figma']),
      ]);
      expect(got, ['SQL', 'Python', 'Excel']);
    });

    testWidgets('selected skills are never suggested again', (tester) async {
      final got = await suggestionsFor(
        tester,
        'Flutter Developer',
        [
          title(
              1, 'مطور فلاتر', 'Flutter Developer', ['Flutter', 'Dart', 'Bloc'])
        ],
        selected: 'Flutter, dart',
      );
      expect(got, ['Bloc']);
    });
  });

  testWidgets('onChanged fires for every user edit', (tester) async {
    final controller = TextEditingController(text: 'Flutter, Dart');
    addTearDown(controller.dispose);
    var calls = 0;
    await tester.pumpWidget(_wrap(SkillChipsSelector(
      controller: controller,
      targetJobTitle: 'Flutter Developer',
      english: true,
      allJobTitles: const [
        JobTitle(
          id: 1,
          slug: 'flutter-developer',
          nameAr: 'مطور فلاتر',
          nameEn: 'Flutter Developer',
          category: 'software',
          keywords: ['Firebase'],
          sortOrder: 1,
        ),
      ],
      onChanged: () => calls++,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('suggested_skill_Firebase')));
    await tester.pump();
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('selected_skill_0')),
      matching: find.byIcon(Icons.close_rounded),
    ));
    await tester.pump();
    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(calls, 3);
    expect(controller.text, isEmpty);
  });
}
