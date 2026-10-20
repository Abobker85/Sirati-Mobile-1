import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_input.dart';

import '../support/contrast_probe.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final colors = theme.extension<SiratiColors>()!;
    testWidgets('contrast probe composites painted layers (${theme.brightness})',
        (tester) async {
      for (final alpha in [0.0, 0.2, 0.5, 0.8, 1.0]) {
        final tint = colors.primaryInk.withValues(alpha: alpha);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ColoredBox(
              color: colors.surfaceHigh,
              child: DecoratedBox(
                decoration: BoxDecoration(color: tint),
                child: const Text('Layered text'),
              ),
            ),
          ),
        ));
        expect(
          paintedBackgroundsOf(tester.element(find.text('Layered text'))),
          [Color.alphaBlend(tint, colors.surfaceHigh)],
        );
      }
    });

    testWidgets(
        'contrast probe reads disabled Material fills (${theme.brightness})',
        (tester) async {
      for (final enabled in [false, true]) {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: enabled ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.surfaceHigh,
                elevation: 0,
                surfaceTintColor: colors.surface.withValues(alpha: 0),
              ),
              child: const Text('Action'),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(
          paintedBackgroundsOf(tester.element(find.text('Action'))),
          [enabled ? colors.primary : colors.surfaceHigh],
        );
      }
    });

    testWidgets('input fill excludes helper text (${theme.brightness})',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AppInput(hint: 'Inside', helperText: 'Outside'),
        ),
      ));
      expect(paintedBackgroundsOf(tester.element(find.text('Inside'))),
          [colors.surface]);
      expect(paintedBackgroundsOf(tester.element(find.text('Outside'))),
          [theme.scaffoldBackgroundColor]);
    });

    testWidgets('contrast probe resolves direct Material fill (${theme.brightness})',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Material(
            color: colors.primaryLight,
            child: Text('On Material', style: TextStyle(color: colors.primaryInk)),
          ),
        ),
      ));
      expect(
        paintedBackgroundsOf(tester.element(find.text('On Material'))),
        [colors.primaryLight],
      );
    });

    testWidgets(
        'adversarial negative control: probe fails on faded ancestor (${theme.brightness})',
        (tester) async {
      // 1. Icon under Opacity ancestor
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ColoredBox(
            color: colors.surface,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.check, color: colors.textPrimary),
            ),
          ),
        ),
      ));
      expect(
        () => expectAllIconsAa('faded Opacity icon'),
        throwsA(isA<TestFailure>()),
      );

      // 2. Icon under FadeTransition ancestor
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ColoredBox(
            color: colors.surface,
            child: FadeTransition(
              opacity: const AlwaysStoppedAnimation(0.08),
              child: Icon(Icons.star, color: colors.primaryInk),
            ),
          ),
        ),
      ));
      expect(
        () => expectAllIconsAa('faded FadeTransition icon'),
        throwsA(isA<TestFailure>()),
      );

      // 3. Progress indicator under AnimatedOpacity ancestor
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ColoredBox(
            color: colors.surface,
            child: AnimatedOpacity(
              opacity: 0.1,
              duration: Duration.zero,
              child: CircularProgressIndicator(color: colors.primaryInk),
            ),
          ),
        ),
      ));
      expect(
        () => expectAllProgressIndicatorsAa('faded AnimatedOpacity spinner'),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets(
        'adversarial negative control: probe fails on wrong fill (${theme.brightness})',
        (tester) async {
      // 1. Text with wrong/low-contrast fill
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ColoredBox(
            color: colors.surfaceHigh,
            child: Text(
              'Low contrast text',
              style: TextStyle(color: colors.surfaceLow),
            ),
          ),
        ),
      ));
      expect(
        () => expectAllTextAa('wrong fill text'),
        throwsA(isA<TestFailure>()),
      );

      // 2. Icon with wrong/low-contrast fill
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ColoredBox(
            color: colors.surface,
            child: Icon(Icons.warning, color: colors.surfaceLow),
          ),
        ),
      ));
      expect(
        () => expectAllIconsAa('wrong fill icon'),
        throwsA(isA<TestFailure>()),
      );

      // 3. Progress indicator with wrong/low-contrast fill
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ColoredBox(
            color: colors.surface,
            child: CircularProgressIndicator(color: colors.surfaceLow),
          ),
        ),
      ));
      expect(
        () => expectAllProgressIndicatorsAa('wrong fill progress'),
        throwsA(isA<TestFailure>()),
      );
    });
  }
}
