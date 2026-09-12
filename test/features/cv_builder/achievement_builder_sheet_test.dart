import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
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
    expect(insertedBullet, '• Developed REST APIs, by 35% using Redis caching.');
  });

  testWidgets('AchievementBuilderSheet applies quick preset on tap',
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
}
