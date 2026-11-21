import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  // Entries as they arrive from the server: one missing name_en, one missing name_ar.
  final taxonomy = [
    JobTitle.fromJson({
      'id': 1, 'slug': 'accountant', 'name_ar': 'محاسب', 'category': 'finance',
      'keywords': ['LedgerOnlyKw'],
    }),
    JobTitle.fromJson({
      'id': 2, 'slug': 'nurse', 'name_en': 'Nurse', 'category': 'health',
      'keywords': ['TriageOnlyKw'],
    }),
  ];

  for (final target in ['Mobile Developer', 'مطور برمجيات', 'Chef', 'x']) {
    testWidgets('entries with an empty name do not match unrelated title "$target"',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(SkillChipsSelector(
        controller: controller,
        targetJobTitle: target,
        english: true,
        allJobTitles: taxonomy,
      )));
      await tester.pumpAndSettle();
      expect(find.text('LedgerOnlyKw'), findsNothing);
      expect(find.text('TriageOnlyKw'), findsNothing);
    });
  }

  testWidgets('a real match still suggests its keywords', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_wrap(SkillChipsSelector(
      controller: controller,
      targetJobTitle: 'Senior Nurse',
      english: true,
      allJobTitles: taxonomy,
    )));
    await tester.pumpAndSettle();
    expect(find.text('TriageOnlyKw'), findsWidgets);
    expect(find.text('LedgerOnlyKw'), findsNothing);
  });
}
