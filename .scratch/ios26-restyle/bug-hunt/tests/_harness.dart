import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

CvBuilderController makeController(CvDocument doc) => CvBuilderController(
      initialDocument: doc,
      repository: LocalCvRepository(engine: MemoryCvStorageEngine()),
    );

/// Hosts [editor] the way CvBuilderScreen does: rebuilt by a
/// ListenableBuilder on the controller, inside a scroll view.
Future<void> pumpEditor(WidgetTester tester, CvBuilderController controller,
    Widget Function() editor) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    home: Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SingleChildScrollView(child: editor()),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Finder fieldWithText(String text) =>
    find.byWidgetPredicate((w) => w is EditableText && w.controller.text == text);
