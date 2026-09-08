import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/presentation/splash_screen.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  group('SplashScreen Circular Reveal & Transitions (SIRATI-59)', () {
    Widget buildSubject({
      ThemeData? theme,
      Locale locale = const Locale('ar'),
      bool disableAnimations = false,
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const SplashScreen(),
        ),
      );
    }

    testWidgets('Renders centered circular element in light theme (RTL)',
        (tester) async {
      await tester.pumpWidget(buildSubject(theme: AppTheme.light));
      await tester.pump();

      // Find the circular container
      final circleFinder = find.byKey(const ValueKey('splash_circle'));
      expect(circleFinder, findsOneWidget);

      final Container container = tester.widget(circleFinder);
      final box = container.decoration as BoxDecoration;
      expect(box.shape, BoxShape.circle);

      final Size size = tester.getSize(circleFinder);
      expect(size.width, 220);
      expect(size.height, 220);

      // Verify centered position
      final center = tester.getCenter(circleFinder);
      expect(center.dx, closeTo(400, 50));
      expect(center.dy, closeTo(300, 50));
    });

    testWidgets('Renders centered circular element in dark theme (LTR)',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          theme: AppTheme.dark,
          locale: const Locale('en'),
        ),
      );
      await tester.pump();

      final circleFinder = find.byKey(const ValueKey('splash_circle'));
      expect(circleFinder, findsOneWidget);

      final Container container = tester.widget(circleFinder);
      final box = container.decoration as BoxDecoration;
      expect(box.shape, BoxShape.circle);
    });

    testWidgets('Honours MediaQuery.disableAnimations fallback',
        (tester) async {
      await tester.pumpWidget(buildSubject(disableAnimations: true));
      await tester.pump();

      final circleFinder = find.byKey(const ValueKey('splash_circle'));
      expect(circleFinder, findsOneWidget);

      final Container container = tester.widget(circleFinder);
      final box = container.decoration as BoxDecoration;
      expect(box.shape, BoxShape.circle);
    });
  });
}
