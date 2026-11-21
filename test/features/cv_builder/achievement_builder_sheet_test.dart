import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

Widget _wrap(Widget child, {bool english = true}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: Locale(english ? 'en' : 'ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('AchievementBuilderSheet generates XYZ formula bullet point',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? insertedBullet;

    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => AchievementBuilderSheet.show(
            context: context,
            english: true,
            onInsert: (b) => insertedBullet = b,
          ),
          child: const Text('Open Sheet'),
        ),
      ),
    ));

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('XYZ Achievement Builder'), findsOneWidget);

    // Find the 3 text fields
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));

    // Field 1: Action
    await tester.enterText(fields.at(0), 'Developed REST APIs');
    // Field 2: Metric
    await tester.enterText(fields.at(1), 'by 35%');
    // Field 3: Method
    await tester.enterText(fields.at(2), 'using Redis caching');
    await tester.pump();

    // Verify live preview is rendered
    expect(find.text('Live Achievement Preview:'), findsOneWidget);
    expect(
      find.text('• Developed REST APIs, by 35% using Redis caching.'),
      findsOneWidget,
    );

    // Tap insert
    await tester.tap(find.text('Insert into Experience'));
    await tester.pumpAndSettle();

    // Verify sheet closed and callback received the formatted string
    expect(find.text('XYZ Achievement Builder'), findsNothing);
    expect(
        insertedBullet, '• Developed REST APIs, by 35% using Redis caching.');
  });

  testWidgets('AchievementBuilderSheet applies quick preset on tap',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? insertedBullet;

    await tester.pumpWidget(_wrap(
      english: false,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => AchievementBuilderSheet.show(
            context: context,
            english: false,
            onInsert: (b) => insertedBullet = b,
          ),
          child: const Text('Open Sheet'),
        ),
      ),
    ));

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('صانع الإنجازات المقاسة (معادلة XYZ)'), findsOneWidget);

    // Tap "تحسين الأداء التقني" preset
    await tester.tap(find.text('تحسين الأداء التقني'));
    await tester.pump();

    expect(find.text('معاينة الصياغة النهائية:'), findsOneWidget);

    // Tap insert
    await tester.tap(find.text('إدراج في الخبرة'));
    await tester.pumpAndSettle();

    expect(insertedBullet, isNotNull);
    expect(insertedBullet!.contains('بنسبة 35%'), isTrue);
    expect(insertedBullet!.startsWith('•'), isTrue);
  });

  group('starter verbs never stack', () {
    const rests = [
      '',
      'REST APIs and payment gateway',
      'واجهات برمجة التطبيقات'
    ];
    for (final (lang, verbs) in [
      ('en', achievementVerbsEn),
      ('ar', achievementVerbsAr),
    ]) {
      test('any tap sequence leaves exactly the last verb ($lang)', () {
        for (final rest in rests) {
          for (final first in verbs) {
            for (final second in verbs) {
              var text = rest;
              // Tap twice, then another: order and repeats must not matter.
              text = applyAchievementVerb(text, first, verbs);
              text = applyAchievementVerb(text, first, verbs);
              text = applyAchievementVerb(text, second, verbs);
              final expected = rest.isEmpty ? second : '$second $rest';
              expect(text, expected, reason: '$first → $second on "$rest"');
            }
          }
        }
      });

      test('a bare verb is not an achievement ($lang)', () {
        for (final v in verbs) {
          expect(isAchievementActionComplete(v, verbs), isFalse);
          expect(isAchievementActionComplete(' $v ', verbs), isFalse);
          expect(isAchievementActionComplete('$v X', verbs), isTrue);
        }
        expect(isAchievementActionComplete('   ', verbs), isFalse);
      });
    }

    test("text that merely starts with a verb's letters is kept", () {
      // "Developed" must not be stripped out of "Developers ...".
      expect(
        applyAchievementVerb(
            'Developers onboarding', 'Optimized', achievementVerbsEn),
        'Optimized Developers onboarding',
      );
    });
  });

  group('appendAchievement', () {
    test('adds each achievement once, whatever the spacing', () {
      const bullet = '• Cut costs by 20%.';
      expect(appendAchievement('', bullet), bullet);
      expect(appendAchievement('  ', ' $bullet '), bullet);
      final once = appendAchievement('Role — Co', bullet)!;
      expect(once, 'Role — Co\n$bullet');
      expect(appendAchievement(once, bullet), isNull);
      expect(appendAchievement('$once\n', '  $bullet'), isNull);
      expect(appendAchievement(once, '• Another.'), '$once\n• Another.');
    });
  });

  testWidgets('tapping verb chips replaces the verb in the field',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(
        english: false,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AchievementBuilderSheet.show(
                context: context, english: false, onInsert: (_) {}),
            child: const Text('Open Sheet'),
          ),
        )));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    final action = find.byType(TextField).first;
    for (final verb in ['طوّرت', 'طوّرت', 'حسّنت كفاءة']) {
      await tester.tap(find.widgetWithText(ActionChip, verb));
      await tester.pump();
    }
    expect(tester.widget<TextField>(action).controller!.text, 'حسّنت كفاءة');

    // A bare verb cannot be inserted.
    final insert = tester.widget<ButtonStyleButton>(find.ancestor(
      of: find.text('إدراج في الخبرة'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    ));
    expect(insert.onPressed, isNull);
  });

  // iOS 26 restyle (ticket 15): grouped sheet content, filled capsules with
  // no outline, teal ink that holds AA in both themes.
  for (final english in [false, true]) {
    for (final dark in [false, true]) {
      final label = '${english ? 'en' : 'ar'}/${dark ? 'dark' : 'light'}';
      testWidgets('$label: sheet is grouped, unoutlined and AA',
          (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          theme: dark
              ? AppTheme.darkFor(arabic: !english)
              : AppTheme.lightFor(arabic: !english),
          locale: Locale(english ? 'en' : 'ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AchievementBuilderSheet.show(
                  context: context,
                  english: english,
                  onInsert: (_) {},
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();
        final sheet = find.byType(AchievementBuilderSheet);
        final context = tester.element(find.byType(TextField).first);
        expect(PageSurface.of(context), PageSurfaceKind.grouped);
        // Fill the preview so every state's ink is on screen.
        await tester.enterText(find.byType(TextField).at(0), 'Built APIs');
        await tester.pumpAndSettle();

        for (final chip in tester.widgetList<ActionChip>(
            find.descendant(of: sheet, matching: find.byType(ActionChip)))) {
          expect(chip.side, isNull, reason: 'theme capsule, no outline');
          expect(chip.backgroundColor, isNull);
        }
        for (final box in tester.widgetList<Container>(
            find.descendant(of: sheet, matching: find.byType(Container)))) {
          final d = box.decoration;
          if (d is BoxDecoration) {
            expect(d.border, isNull, reason: '$label boxed outline');
          }
        }
        expectAllTextAa('$label achievement sheet');
      });
    }
  }
}
