import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/controllers/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/presentation/skills_languages_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

CvBuilderController certController(Certification cert) {
  final c = CvBuilderController(
    initialDocument: CvDocument.createEmpty(id: 'hunt'),
    repository: LocalCvRepository(engine: MemoryCvStorageEngine()),
  );
  c.setCertifications([cert]);
  return c;
}

Future<void> pumpCertEditor(WidgetTester tester, CvBuilderController c) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => SkillsLanguagesEditor(controller: c),
        ),
      ),
    ),
  ));
  await tester.pump();
}
