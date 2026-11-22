import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Future<String?> _open(WidgetTester tester,
    Future<void> Function() fill) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  String? inserted;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => AchievementBuilderSheet.show(
            context: context,
            english: false,
            onInsert: (b) => inserted = b,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await fill();
  await tester.pump();
  await tester.tap(find.text('إدراج في الخبرة'));
  await tester.pumpAndSettle();
  return inserted;
}

void main() {
  testWidgets('every Arabic preset inserts a bullet with one means preposition',
      (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ar'));
    for (final preset in [
      l.cvXyzPresetProject,
    ]) {
      final b = await _open(tester, () async {
        await tester.ensureVisible(find.text(preset));
        await tester.pumpAndSettle();
        await tester.tap(find.text(preset));
      });
      expect(b, isNotNull);
      expect(RegExp(r'عبر\s+ب').hasMatch(b!), isFalse, reason: b);
    }
  });

  // A method already introduced by a means preposition is kept as is;
  // one that is not gets "عبر".
  const alreadyIntroduced = [
    'بتطبيق منهجية Scrum',
    'بواسطة أدوات أتمتة داخلية',
    'بالاعتماد على تحليل البيانات',
    'من خلال ورش عمل أسبوعية',
    'باستخدام Power BI',
  ];
  for (final method in alreadyIntroduced) {
    testWidgets('method "$method" is not given a second preposition',
        (tester) async {
      final b = await _open(tester, () async {
        final f = find.byType(TextField);
        await tester.enterText(f.at(0), 'خفضت زمن التسليم');
        await tester.enterText(f.at(2), method);
      });
      expect(b, '• خفضت زمن التسليم، $method.');
    });
  }
  for (final method in ['بناء لوحة متابعة يومية', 'أتمتة الاختبارات']) {
    testWidgets('bare method "$method" is introduced with عبر', (tester) async {
      final b = await _open(tester, () async {
        final f = find.byType(TextField);
        await tester.enterText(f.at(0), 'خفضت زمن التسليم');
        await tester.enterText(f.at(2), method);
      });
      expect(b, '• خفضت زمن التسليم، عبر $method.');
    });
  }
}
