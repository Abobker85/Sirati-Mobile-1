import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/errors/app_crash_view.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components.dart';

void main() {
  Widget wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
    return MaterialApp(
      theme: AppTheme.lightFor(arabic: direction == TextDirection.rtl),
      builder: (context, child) {
        return Directionality(textDirection: direction, child: child!);
      },
      home: Scaffold(body: child),
    );
  }

  testWidgets('primary / secondary / text / destructive buttons render',
      (tester) async {
    await tester.pumpWidget(wrap(
      const Column(
        children: [
          AppButton.primary(label: 'Save', onPressed: null),
          AppButton.secondary(label: 'Cancel', onPressed: null),
          AppButton.text(label: 'Skip', onPressed: null),
          AppButton.destructive(label: 'Delete', onPressed: null),
        ],
      ),
    ));

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('buttons meet 48px min touch target', (tester) async {
    await tester.pumpWidget(wrap(
      AppButton.primary(label: 'Continue', onPressed: () {}),
    ));

    final size = tester.getSize(find.byType(ElevatedButton));
    expect(size.height, greaterThanOrEqualTo(AppTouchTarget.min));
  });

  testWidgets('button exposes semantics label', (tester) async {
    await tester.pumpWidget(wrap(
      AppButton.primary(label: 'Generate CV', onPressed: () {}),
    ));

    expect(find.bySemanticsLabel('Generate CV'), findsWidgets);
  });

  testWidgets('card, input, empty state, and loader render in RTL',
      (tester) async {
    await tester.pumpWidget(wrap(
      const Column(
        children: [
          AppSurfaceCard(semanticLabel: 'CV card', child: Text('Card body')),
          AppInput(label: 'Email', hint: 'you@example.com'),
          AppEmptyState(
            icon: Icons.description_outlined,
            title: 'لا توجد سير',
            subtitle: 'أنشئ واحدة',
            scrollable: false,
          ),
          BrandedLoader(),
        ],
      ),
      direction: TextDirection.rtl,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Card body'), findsOneWidget);
    expect(find.text('لا توجد سير'), findsOneWidget);
    expect(find.byType(AppInput), findsOneWidget);
    expect(find.byType(BrandedLoader), findsOneWidget);
  });

  testWidgets('dialog and sheet open without throwing', (tester) async {
    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) {
          return Column(
            children: [
              TextButton(
                onPressed: () => showAppDialog(
                  context: context,
                  title: 'Confirm',
                  body: 'Delete this CV?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  destructive: true,
                ),
                child: const Text('dialog'),
              ),
              TextButton(
                onPressed: () => showAppBottomSheet(
                  context: context,
                  semanticLabel: 'Options',
                  child: const Text('Sheet body'),
                ),
                child: const Text('sheet'),
              ),
            ],
          );
        },
      ),
    ));

    await tester.tap(find.text('dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this CV?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
  });

  testWidgets('crash view shows localized non-technical copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppCrashView(),
      ),
    );

    expect(find.byType(AppCrashView), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets(
      'AppButton primary/destructive disabled state looks different from enabled and loading',
      (tester) async {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      for (final arabic in [false, true]) {
        for (final isDark in [false, true]) {
          final theme = isDark
              ? AppTheme.darkFor(arabic: arabic)
              : AppTheme.lightFor(arabic: arabic);
          final c = theme.extension<SiratiColors>()!;

          for (final variant in [
            AppButtonVariant.primary,
            AppButtonVariant.destructive,
          ]) {
            final isPrimary = variant == AppButtonVariant.primary;
            final enabledFill = isPrimary ? c.primary : c.error;
            final enabledFg = isPrimary ? c.onPrimary : c.onError;
            const label = 'Proceed متابعة';

            // Enabled
            await tester.pumpWidget(
              MaterialApp(
                home: Theme(
                  data: theme,
                  child: Scaffold(
                    body: Directionality(
                      textDirection: dir,
                      child: AppButton(
                        label: label,
                        variant: variant,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            final enabledBtn =
                tester.widget<ElevatedButton>(find.byType(ElevatedButton));
            expect(
              enabledBtn.style!.backgroundColor!.resolve(const <WidgetState>{}),
              enabledFill,
            );

            // Loading keeps enabled fill
            await tester.pumpWidget(
              MaterialApp(
                home: Theme(
                  data: theme,
                  child: Scaffold(
                    body: Directionality(
                      textDirection: dir,
                      child: AppButton(
                        label: label,
                        variant: variant,
                        isLoading: true,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            final loadingBtn =
                tester.widget<ElevatedButton>(find.byType(ElevatedButton));
            expect(
              loadingBtn.style!.backgroundColor!
                  .resolve(const <WidgetState>{WidgetState.disabled}),
              enabledFill,
            );
            expect(find.byType(CircularProgressIndicator), findsOneWidget);

            // Disabled has neutral surfaceHigh fill and textSecondary text
            await tester.pumpWidget(
              MaterialApp(
                home: Theme(
                  data: theme,
                  child: Scaffold(
                    body: Directionality(
                      textDirection: dir,
                      child: AppButton(
                        label: label,
                        variant: variant,
                        onPressed: null,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            final disabledBtn =
                tester.widget<ElevatedButton>(find.byType(ElevatedButton));
            final disabledFill = disabledBtn.style!.backgroundColor!
                .resolve(const <WidgetState>{WidgetState.disabled})!;
            expect(disabledFill, c.surfaceHigh);
            expect(disabledFill, isNot(equals(enabledFill)));

            final textWidget = tester.widget<Text>(find.text(label));
            final textColor = textWidget.style!.color!;
            expect(textColor, c.textSecondary);
            expect(textColor, isNot(equals(enabledFg)));

            final ratio = AppContrast.ratio(textColor, disabledFill);
            expect(ratio, greaterThanOrEqualTo(4.5));
          }
        }
      }
    }
  });
}
