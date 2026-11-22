import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';

JobTitle _t(int id, String slug, String ar, String en) => JobTitle(
    id: id, slug: slug, nameAr: ar, nameEn: en, category: 'g',
    keywords: const [], sortOrder: id);

void main() {
  // Phone sizes with a status-bar / notch inset and an open keyboard.
  const cases = [
    (Size(390, 844), 47.0, 336.0),
    (Size(375, 667), 20.0, 260.0),
    (Size(430, 932), 59.0, 346.0),
  ];
  for (final (size, top, kb) in cases) {
    testWidgets('picker header stays below the top inset ($size, top $top, kb $kb)',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = FakeViewPadding(top: top, bottom: 34);
      tester.view.viewPadding = FakeViewPadding(top: top, bottom: 34);
      addTearDown(tester.view.reset);
      final selected = _t(1, 'accountant', 'محاسب', 'Accountant');
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: JobTitlePickerField(
            titles: [selected, _t(2, 'nurse', 'ممرض', 'Nurse')],
            value: selected,
            english: true,
            onChanged: (_) {},
          ),
        ),
      ));
      await tester.tap(find.descendant(
          of: find.byType(JobTitlePickerField), matching: find.byType(InkWell)));
      await tester.pumpAndSettle();
      // Focus search: the keyboard opens.
      await tester.tap(find.descendant(
          of: find.byType(BottomSheet), matching: find.byType(TextField)));
      tester.view.viewInsets = FakeViewPadding(bottom: kb);
      await tester.pumpAndSettle();

      final title = find.descendant(
          of: find.byType(BottomSheet), matching: find.text('Job title'));
      final clear = find.descendant(
          of: find.byType(BottomSheet), matching: find.byType(TextButton));
      expect(tester.getTopLeft(title).dy, greaterThanOrEqualTo(top));
      expect(tester.getTopLeft(clear).dy, greaterThanOrEqualTo(top));
    });
  }
}
