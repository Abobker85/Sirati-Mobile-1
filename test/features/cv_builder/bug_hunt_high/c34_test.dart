import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/cv_builder/controllers/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/presentation/skills_languages_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Future<CvBuilderController> pump(WidgetTester tester, CvDocument doc) async {
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
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SkillsLanguagesEditor(controller: controller),
        ),
      ),
    ),
  ));
  await tester.pump();
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Invariant: opening a certification/project and editing one field must
  // neither hide nor erase text already stored in either language.
  for (final lang in const ['en', 'ar']) {
    testWidgets('certification ($lang CV): fields show stored text, edit keeps others',
        (tester) async {
      final doc = CvDocument.fromJson({
        'id': 'c-$lang',
        'export_language': lang,
        'certifications': [
          {'id': 'x', 'name': 'Name-$lang', 'authority': 'Issuer-$lang', 'issue_date': '2020'}
        ],
      });
      final before = doc.certifications!.single;
      final controller = await pump(tester, doc);
      expect(find.text('Name-$lang'), findsOneWidget);
      expect(find.text('Issuer-$lang'), findsOneWidget);
      await tester.enterText(find.text('Name-$lang'), 'Name-$lang!');
      await tester.pump();
      final after = controller.document.certifications!.single;
      expect(after.authority, before.authority);
      expect(after.name.resolve(lang, fallback: false), 'Name-$lang!');
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('project ($lang CV): fields show stored text, edit keeps others',
        (tester) async {
      final doc = CvDocument.fromJson({
        'id': 'p-$lang',
        'export_language': lang,
        'projects': [
          {'id': 'y', 'title': 'Title-$lang', 'role': 'Role-$lang', 'description': 'Desc-$lang'}
        ],
      });
      final before = doc.projects!.single;
      final controller = await pump(tester, doc);
      expect(find.text('Title-$lang'), findsOneWidget);
      expect(find.text('Role-$lang'), findsOneWidget);
      await tester.enterText(find.text('Title-$lang'), 'Title-$lang!');
      await tester.pump();
      final after = controller.document.projects!.single;
      expect(after.role, before.role);
      expect(after.narrative, before.narrative);
      expect(after.title.resolve(lang, fallback: false), 'Title-$lang!');
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('bilingual certification: editing Arabic name keeps English',
      (tester) async {
    final doc = CvDocument.createEmpty(id: 'bi').copyWith(certifications: const [
      Certification(
        id: 'z',
        name: LocalizedText(ar: 'شهادة', en: 'Certificate'),
        authority: LocalizedText(ar: 'جهة', en: 'Body'),
      ),
    ]);
    final controller = await pump(tester, doc);
    await tester.enterText(find.text('شهادة'), 'شهادة٢');
    await tester.pump();
    final after = controller.document.certifications!.single;
    expect(after.name.en, 'Certificate');
    expect(after.authority.en, 'Body');
    await tester.pump(const Duration(seconds: 5));
  });
}
