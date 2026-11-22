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
            builder: (context, _) =>
                SkillsLanguagesEditor(controller: controller),
          ),
        ),
      ),
    ));
    await tester.pump();
    return controller;
  }

  Future<void> typeCharByChar(
      WidgetTester tester, Finder field, String start, String typed) async {
    await tester.showKeyboard(field);
    var current = start;
    for (final ch in typed.split('')) {
      current += ch;
      tester.testTextInput.updateEditingValue(TextEditingValue(
          text: current,
          selection: TextSelection.collapsed(offset: current.length)));
      await tester.pump();
    }
  }

  final base = CvDocument.createEmpty(id: 'c18');
  final cases = <String, CvDocument>{
    'certification': base.copyWith(certifications: const [
      Certification(id: 'cert1', name: LocalizedText(ar: 'AWS')),
    ]),
    'project': base.copyWith(projects: const [
      Project(id: 'proj1', title: LocalizedText(ar: 'App')),
    ]),
  };

  for (final entry in cases.entries) {
    for (final typed in ['x', 'Cloud Pro', 'شهادة']) {
      testWidgets('${entry.key} row keeps focus and text while typing "$typed"',
          (tester) async {
        final controller = await pump(tester, entry.value);
        final initial = entry.key == 'certification' ? 'AWS' : 'App';
        final field = find.widgetWithText(TextField, initial);
        expect(field, findsOneWidget);
        final editableBefore = tester.state<EditableTextState>(
            find.descendant(of: field, matching: find.byType(EditableText)));
        await typeCharByChar(tester, field, initial, typed);
        final focused = find.byWidgetPredicate(
            (w) => w is EditableText && w.focusNode.hasFocus);
        expect(focused, findsOneWidget, reason: 'focus lost after typing');
        expect(tester.state<EditableTextState>(focused), same(editableBefore),
            reason: 'field was rebuilt from scratch');
        final stored = entry.key == 'certification'
            ? controller.document.certifications!.single.name.ar
            : controller.document.projects!.single.title.ar;
        expect(stored, '$initial$typed'.trim());
        await tester.pump(const Duration(seconds: 5)); // let autosave settle
      });
    }
  }
}
