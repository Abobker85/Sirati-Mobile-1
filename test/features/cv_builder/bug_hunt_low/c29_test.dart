import 'package:flutter/cupertino.dart';
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

/// Invariant: the CV has no photo setting (CvDocument holds no photo field),
/// so the ATS photo card must not offer any toggle that claims to change the
/// CV. It still shows its ATS photo advice, in every UI language.
void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('$language: photo card gives advice and offers no toggle',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
      await repo.saveCv(CvDocument.createEmpty(id: 'cv_c29', title: 'T'));
      await tester.pumpWidget(ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: const CvBuilderScreen(cvId: 'cv_c29'),
        ),
      ));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(Locale(language));

      final card = find.byKey(PersonalDetailsEditor.photoCardKey);
      expect(card, findsOneWidget);
      Finder inCard(Finder f) => find.descendant(of: card, matching: f);

      // The advice stays.
      expect(inCard(find.text(l10n.atsPhotoWarningTitle)), findsOneWidget);
      expect(inCard(find.text(l10n.atsPhotoWarningBody)), findsOneWidget);

      // No toggle of any kind, and no "photo enabled" confirmation anywhere.
      for (final type in [
        Switch,
        CupertinoSwitch,
        SwitchListTile,
        Checkbox,
        CheckboxListTile,
      ]) {
        expect(inCard(find.byType(type)), findsNothing,
            reason: '$type in the photo card toggles a setting the CV lacks');
      }
      expect(find.text(l10n.atsPhotoEnabled), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
