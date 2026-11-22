import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Typing into an entry row of the CV builder must keep the same field
/// (state, focus, and the exact text typed, including spaces between words).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('C06: typing in an experience row keeps the field and its text',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AppLocale.languageCode.value = 'en';
    final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
    final doc = CvDocument.createEmpty(id: 'cv1', title: 'CV').copyWith(
      experience: const [ExperienceEntry(id: 'e1')],
    );
    await repo.saveCv(doc);
    await tester.pumpWidget(ProviderScope(
      overrides: [cvRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const CvBuilderScreen(cvId: 'cv1'),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experience').first);
    await tester.pumpAndSettle();

    Finder field() => find
        .descendant(
          of: find.widgetWithText(TextField, 'Job Title (English)'),
          matching: find.byType(EditableText),
        )
        .first;
    expect(field(), findsOneWidget);
    final stateBefore = tester.state(field());

    // Simulate typing a multi-word value keystroke by keystroke.
    const value = 'Senior Engineer';
    for (var i = 1; i <= value.length; i++) {
      await tester.enterText(field(), value.substring(0, i));
      await tester.pump();
      // What the user typed so far must still be in the field (a real
      // keyboard appends to the field's current text).
      expect(tester.widget<EditableText>(field()).controller.text,
          value.substring(0, i),
          reason: 'after keystroke $i');
      expect(tester.widget<EditableText>(field()).focusNode.hasFocus, isTrue,
          reason: 'focus lost after keystroke $i');
    }
    await tester.pumpAndSettle();

    expect(tester.widget<EditableText>(field()).controller.text, value);
    expect(identical(tester.state(field()), stateBefore), isTrue,
        reason: 'field state was rebuilt while typing');
    expect(tester.widget<EditableText>(field()).focusNode.hasFocus, isTrue);
  });
}
