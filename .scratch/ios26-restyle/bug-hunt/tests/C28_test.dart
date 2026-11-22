import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/cv_builder/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/cv_builder_screen.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/personal_details_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  testWidgets('restoring a draft shows it in the personal editor and a later '
      'keystroke keeps the restored values', (tester) async {
    tester.view.physicalSize = const Size(600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
    final server = CvDocument.createEmpty(id: 'cv_c28', title: 'T').copyWith(
      personal: const PersonalDetails(
        fullName: LocalizedText(ar: 'خادم', en: 'Server Name'),
        headline: LocalizedText(ar: '', en: 'Server Headline'),
        location: LocalizedText(ar: '', en: ''),
      ),
      summary: const LocalizedText(ar: '', en: 'server summary'),
    );
    await repo.saveCv(server);
    final draft = server.copyWith(
      personal: const PersonalDetails(
        fullName: LocalizedText(ar: 'مسودة', en: 'Draft Name'),
        headline: LocalizedText(ar: '', en: 'Draft Headline'),
        location: LocalizedText(ar: '', en: ''),
      ),
      summary: const LocalizedText(ar: '', en: 'draft summary'),
      updatedAt: DateTime(2099),
    );
    SharedPreferences.setMockInitialValues({
      '${CvBuilderController.draftPrefix}cv_c28': jsonEncode(draft.toJson()),
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [cvRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: const CvBuilderScreen(cvId: 'cv_c28'),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.restoreDraft));
    await tester.pumpAndSettle();

    final controller =
        tester.widget<PersonalDetailsEditor>(find.byType(PersonalDetailsEditor)).controller;
    expect(controller.document.personal.fullName.en, 'Draft Name');


    // Typing in an unrelated field must not overwrite the restored values.
    final linkedin = find.widgetWithText(TextField, 'linkedin.com/in/username');
    await tester.enterText(linkedin.first, 'linkedin.com/in/x');
    await tester.pump();
    expect(controller.document.personal.fullName.en, 'Draft Name');
    expect(controller.document.personal.headline.en, 'Draft Headline');
    // The editor must show the restored document, not the server one.
    expect(find.text('Draft Name'), findsOneWidget);
    expect(find.text('Server Name'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
