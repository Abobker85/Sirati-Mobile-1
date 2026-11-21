import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/dashboard/presentation/gallery_screen.dart';
import 'package:sirati/routing/app_router.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';

import 'support/contrast_probe.dart';

void main() {
  testWidgets(
      'ComponentGalleryScreen renders all sections, tokens, and toggles (SIRATI-23)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightFor(arabic: true),
        locale: const Locale('ar', 'SA'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const ComponentGalleryScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify title
    expect(find.text('Component Gallery (Debug)'), findsOneWidget);

    // Verify sections visible initially
    expect(find.text('1. Buttons (AppButton)'), findsOneWidget);
    expect(find.text('2. Text Fields (AppInput)'), findsOneWidget);
    expect(find.text('3. Surface Cards (AppSurfaceCard)'), findsOneWidget);

    // Verify button variants rendered
    expect(find.text('Primary Button'), findsOneWidget);
    expect(find.text('Secondary Button'), findsOneWidget);
    expect(find.text('Text Button'), findsOneWidget);
    expect(find.text('Destructive'), findsOneWidget);

    // Drag ListView down to reveal off-screen sections
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('4. Dialogs and Sheets'), findsOneWidget);
    expect(find.text('5. Empty and Loading States'), findsOneWidget);

    // Verify router parses /gallery
    final parsed = AppRouter.parse('/gallery');
    expect(parsed.name, AppRoutes.gallery);
    expect(parsed.unknown, isFalse);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'gallery disabled button has a neutral grey fill '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightFor(arabic: true),
          darkTheme: AppTheme.darkFor(arabic: true),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: const ComponentGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final disabled = find.descendant(
        of: find.widgetWithText(AppButton, 'Disabled'),
        matching: find.byType(ElevatedButton),
      );
      expect(disabled, findsOneWidget);
      final fill = tester
          .widget<ElevatedButton>(disabled)
          .style!
          .backgroundColor!
          .resolve(const {WidgetState.disabled})!;
      final page = paintedBackgroundsOf(tester.element(disabled)).single;
      final label = find.text('Disabled');
      final ink = DefaultTextStyle.of(tester.element(label))
          .style
          .merge(tester.widget<Text>(label).style)
          .color!;
      // Not warm: a warm grey's red channel sits above its blue one.
      expect(fill.r, lessThanOrEqualTo(fill.b), reason: 'warm fill $fill');
      expect(fill, isNot(page), reason: 'fill vs page');
      expect(ink, isNot(fill), reason: 'label vs fill');
    });
  }
}
