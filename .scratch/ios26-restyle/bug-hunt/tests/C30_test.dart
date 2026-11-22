import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/cv_builder/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/personal_details_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Maps every ASCII digit to Arabic-Indic (U+0660..) or Extended (U+06F0..).
String toArabic(String s, int base) => String.fromCharCodes(
    s.runes.map((r) => r >= 0x30 && r <= 0x39 ? base + r - 0x30 : r));

void main() {
  late AppLocalizations en;
  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('a phone valid in ASCII digits is valid in Arabic-Indic digits', () {
    const valid = [
      '+966501234567', '0501234567', '00966551234567', '+971501234567',
      '+96599123456', '+97433123456', '+97339123456', '+96891123456',
      '+14155552671', '0112345678',
    ];
    for (final p in valid) {
      expect(ContactValidators.validateGulfPhone(p, en), isNull, reason: p);
      for (final base in [0x0660, 0x06F0]) {
        final a = toArabic(p, base);
        expect(ContactValidators.validateGulfPhone(a, en), isNull, reason: a);
      }
    }
  });

  testWidgets('phone typed in Arabic digits is stored in Latin digits',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = CvBuilderController(
      initialDocument: CvDocument.createEmpty(id: 'c30'),
      repository: LocalCvRepository(engine: MemoryCvStorageEngine()),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PersonalDetailsEditor(controller: controller),
        ),
      ),
    ));
    final phone = find.widgetWithText(TextField, '+966501234567');
    await tester.enterText(phone, toArabic('0501234567', 0x0660));
    await tester.pump();
    expect(controller.document.personal.phone, '0501234567');
    expect(find.text(en.invalidGulfOrIntlPhone), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
