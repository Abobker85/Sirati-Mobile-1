import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';

// Production callers: RegisterScreen and ProfileScreen job-title fields.
JobTitle _title(int id, String slug, String ar, String en) => JobTitle(
      id: id,
      slug: slug,
      nameAr: ar,
      nameEn: en,
      category: 'general',
      keywords: const [],
      sortOrder: id,
    );

final _withOther = [
  _title(1, 'accountant', 'محاسب', 'Accountant'),
  _title(2, 'nurse', 'ممرض', 'Nurse'),
  _title(99, 'other', 'أخرى', 'Other'),
];

Future<({List<JobTitle?> changes, List<String> manual})> _pump(
  WidgetTester tester, {
  required List<JobTitle> titles,
  required Locale locale,
}) async {
  final changes = <JobTitle?>[];
  final manual = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: JobTitlePickerField(
          titles: titles,
          value: null,
          english: locale.languageCode == 'en',
          onChanged: changes.add,
          onManualEntry: manual.add,
        ),
      ),
    ),
  );
  await tester.tap(find.descendant(
      of: find.byType(JobTitlePickerField), matching: find.byType(InkWell)));
  await tester.pumpAndSettle();
  return (changes: changes, manual: manual);
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final query in [
      'Data Scientist',
      'مهندس طيران',
      'Flutter مطور',
      '  spaced query  ',
    ]) {
      testWidgets(
          'unmatched search "$query" offers manual entry that selects Other '
          'and hands back the trimmed text ($locale)', (tester) async {
        final result = await _pump(tester, titles: _withOther, locale: locale);
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();

        final option = find.byIcon(Icons.edit_outlined);
        expect(option, findsOneWidget);
        await tester.tap(option);
        await tester.pumpAndSettle();

        expect(result.changes, hasLength(1));
        expect(result.changes.single!.isOther, isTrue);
        expect(result.changes.single!.id, 99);
        expect(result.manual, [query.trim()]);
      });
    }

    testWidgets('matching search shows no manual option ($locale)',
        (tester) async {
      await _pump(tester, titles: _withOther, locale: locale);
      await tester.enterText(find.byType(TextField), 'nurse');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('no manual option without an Other title or a query ($locale)',
        (tester) async {
      await _pump(
        tester,
        titles: _withOther.where((t) => !t.isOther).toList(),
        locale: locale,
      );
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsNothing);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  }
}
