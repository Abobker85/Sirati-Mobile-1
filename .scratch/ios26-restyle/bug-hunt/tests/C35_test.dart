import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/cv_builder/controllers/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/presentation/skills_languages_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Invariant: every stored skill/language name is visible on its chip,
  // whichever language variant holds it.
  for (final lang in const ['en', 'ar']) {
    testWidgets('$lang-only skills and languages show their names', (tester) async {
      final skillNames = ['Skill A $lang', 'Second skill $lang'];
      final langNames = ['Lang X $lang', 'Lang Y $lang'];
      final doc = CvDocument.fromJson({
        'id': 's-$lang',
        'export_language': lang,
        'skills': [for (final n in skillNames) {'name': n}],
        'languages': [for (final n in langNames) {'name': n}],
      });
      final controller = CvBuilderController(
        initialDocument: doc,
        repository: LocalCvRepository(engine: MemoryCvStorageEngine()),
      );
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
              child: SkillsLanguagesEditor(controller: controller)),
        ),
      ));
      await tester.pump();
      final chipLabels = tester
          .widgetList<Chip>(find.byType(Chip))
          .map((c) => (c.label as Text).data ?? '')
          .toList();
      for (final n in [...skillNames, ...langNames]) {
        expect(chipLabels.any((l) => l.startsWith(n)), isTrue,
            reason: '$n not on any chip: $chipLabels');
      }
    });
  }

  testWidgets('English-only category groups under its own heading', (tester) async {
    final doc = CvDocument.fromJson({
      'id': 'cat',
      'export_language': 'en',
      'skills': [
        {'name': 'Python', 'level': 'Advanced', 'category': 'Technical skills'}
      ],
    });
    final controller = CvBuilderController(
      initialDocument: doc,
      repository: LocalCvRepository(engine: MemoryCvStorageEngine()),
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
            child: SkillsLanguagesEditor(controller: controller)),
      ),
    ));
    await tester.pump();
    final l = AppLocalizations.of(tester.element(find.byType(SkillsLanguagesEditor)));
    expect(find.text(l.skillCategoryGeneral), findsNothing);
    expect(find.text(l.skillCategoryTechnical), findsWidgets);
    expect(find.text('Python (${l.skillLevelAdvanced})'), findsOneWidget);
  });
}
