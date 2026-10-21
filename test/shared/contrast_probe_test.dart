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
        'faded text that misses AA is rejected (${theme.brightness})',
        (tester) async {
      const copy = 'Readable until faded';
      final style = TextStyle(color: colors.textPrimary);

      Future<void> pumpFaded(Widget child) {
        return tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ColoredBox(color: colors.surface, child: child),
          ),
        ));
      }

      await pumpFaded(Text(copy, style: style));
      expectAllTextAa('opaque text still passes');

      for (final child in <Widget>[
        Opacity(opacity: 0.12, child: Text(copy, style: style)),
        FadeTransition(
          opacity: const AlwaysStoppedAnimation(0.12),
          child: Text(copy, style: style),
        ),
        AnimatedOpacity(
          opacity: 0.12,
          duration: Duration.zero,
          child: Text(copy, style: style),
        ),
      ]) {
        await pumpFaded(child);
        await tester.pump();
        expect(
          () => expectAllTextAa('faded text'),
          throwsA(isA<TestFailure>()),
        );
      }

      // 0.8 * 0.5 counted twice on the animated layer would be 0.2.
      await pumpFaded(Opacity(
        opacity: 0.8,
        child: AnimatedOpacity(
          opacity: 0.5,
          duration: Duration.zero,
          child: Text('Counted once', style: style),
        ),
      ));
      await tester.pump();
      expect(
        effectiveAncestorOpacityOf(tester.element(find.text('Counted once'))),
        0.4,
      );
    });

    testWidgets('opacity layers use current paint values (${theme.brightness})',
        (tester) async {
      for (final alpha in [0.0, 0.125, 0.5, 0.875, 1.0]) {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Opacity(
              opacity: 0.5,
              child: AnimatedOpacity(
                opacity: alpha,
                duration: Duration.zero,
                child: FadeTransition(
                  opacity: AlwaysStoppedAnimation(alpha),
                  child: Text('Nested layers',
                      style: TextStyle(color: colors.textPrimary)),
                ),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(
          effectiveAncestorOpacityOf(
              tester.element(find.text('Nested layers'))),
          0.5 * alpha * alpha,
        );
      }
    });

    testWidgets(
        'animated opacity uses in-flight values (${theme.brightness})',
        (tester) async {
      Widget fading(double opacity) => MaterialApp(
        theme: theme,
        home: Scaffold(body: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(seconds: 1),
          child: Text('Transitioning',
              style: TextStyle(color: colors.textPrimary)),
        )),
      );
      await tester.pumpWidget(fading(0));
      await tester.pumpWidget(fading(1));
      await tester.pump();
      for (final opacity in [0.25, 0.5, 0.75]) {
        await tester.pump(const Duration(milliseconds: 250));
        expect(effectiveAncestorOpacityOf(
            tester.element(find.text('Transitioning'))), opacity);
      }
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
