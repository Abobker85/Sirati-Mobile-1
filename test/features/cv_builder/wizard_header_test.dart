import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_header.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int step,
  required bool english,
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightFor(arabic: !english),
    locale: Locale(english ? 'en' : 'ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: WizardHeader(step: step, english: english, onStepTap: (_) {}),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  // Every label sits centred under its own dot, for any current step, both
  // directions, phone widths and text sizes.
  for (final english in [false, true]) {
    for (final width in [320.0, 375.0, 430.0, 600.0]) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets(
            'labels centred under dots (${english ? 'en' : 'ar'}, $width, x$textScale)',
            (tester) async {
          final titles = wizardStepTitles(
            lookupAppLocalizations(Locale(english ? 'en' : 'ar')),
          );
          for (var step = 0; step < titles.length; step++) {
            await _pump(tester,
                step: step,
                english: english,
                width: width,
                textScale: textScale);

            final dots = <double>[];
            for (var i = 0; i < titles.length; i++) {
              final icon = i < step ? Icons.check_rounded : wizardStepIcons[i];
              final finder = find.byIcon(icon);
              // Several done steps share the check icon; take them in order.
              final centers = tester
                  .widgetList(finder)
                  .map((w) => tester.getCenter(find.byWidget(w)).dx)
                  .toList();
              dots.add(i < step ? centers[i] : centers.single);
            }

            for (var i = 0; i < titles.length; i++) {
              final label = tester.getCenter(find.text(titles[i]).last).dx;
              expect(label, closeTo(dots[i], 0.5),
                  reason: 'step $step, label ${titles[i]}');
            }

            // Steps run from the start edge: right to left in Arabic.
            final ordered = [...dots]..sort();
            expect(dots, english ? ordered : ordered.reversed.toList(),
                reason: 'step $step');
          }
        });
      }
    }
  }
}
