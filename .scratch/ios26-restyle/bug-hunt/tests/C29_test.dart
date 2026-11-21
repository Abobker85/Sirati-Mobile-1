import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/cv_builder/cv_builder_screen.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/personal_details_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Invariant: a setting the photo card lets the user turn on must be real:
/// it is held by the CV document and survives leaving and returning to the
/// tab. A card with no switch (no photo feature) holds trivially.
void main() {
  testWidgets('photo switch is a real, persistent CV setting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
    await repo.saveCv(CvDocument.createEmpty(id: 'cv_c29', title: 'T'));
    await tester.pumpWidget(ProviderScope(
      overrides: [cvRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: const CvBuilderScreen(cvId: 'cv_c29'),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final switches = find.descendant(
        of: find.byKey(PersonalDetailsEditor.photoCardKey),
        matching: find.byType(Switch));
    final count = switches.evaluate().length;
    for (var i = 0; i < count; i++) {
      final controller = tester
          .widget<PersonalDetailsEditor>(find.byType(PersonalDetailsEditor))
          .controller;
      final before = jsonEncode(controller.document.toJson()..remove('updated_at')..remove('updatedAt'));
      await tester.tap(switches.at(i));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(switches.at(i)).value, isTrue);
      final after = jsonEncode(controller.document.toJson()..remove('updated_at')..remove('updatedAt'));
      expect(after, isNot(before), reason: 'switch changes nothing in the CV');

      await tester.tap(find.text(l10n.tabOrder));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.tabPersonal));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(switches.at(i)).value, isTrue,
          reason: 'switch reset after changing tabs');
    }
    await tester.pump(const Duration(seconds: 5));
  });
}
