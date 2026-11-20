import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis/analysis_form_sections.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

/// Ticket 16: the scan form is a grouped page. Every control carries a fill
/// of its own that differs from whatever is painted behind it (no field or
/// capsule disappears into a card of the same colour), nothing has a
/// resting outline, all copy is AA, and the chosen source is marked by a
/// check, not by its tint alone.

Widget _app({
  required bool arabic,
  required bool dark,
  required AnalysisCvSource source,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic),
      locale: Locale(arabic ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: CvAnalysisScreen(
        savedCvs: const AsyncValue.data([
          SavedAnalysisCv(id: 4, title: 'Backend CV'),
          SavedAnalysisCv(id: 9, title: 'سيرة المحلل'),
        ]),
        initialCvId: 4,
        initialMarkdown: '# Backend CV',
        initialSource: source,
      ),
    ),
  );
}

/// The colours painted behind [element], excluding its own fill.
List<Color> _behind(Element element) {
  late Element parent;
  element.visitAncestorElements((e) {
    parent = e;
    return false;
  });
  return paintedBackgroundsOf(parent);
}

void main() {
  tearDown(() => AppLocale.languageCode.value = 'en');

  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      for (final source in AnalysisCvSource.values) {
        final label =
            '${arabic ? 'ar' : 'en'} ${dark ? 'dark' : 'light'} ${source.name}';
        testWidgets('$label: grouped page, own fills, no outlines, AA',
            (tester) async {
          AppLocale.languageCode.value = arabic ? 'ar' : 'en';
          tester.view.physicalSize = const Size(900, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
              _app(arabic: arabic, dark: dark, source: source));
          await tester.pumpAndSettle();

          final screen = tester.element(find.byType(CvAnalysisScreen));
          final c = screen.sirati;
          // The page is the grouped background.
          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          final page = scaffold.backgroundColor ??
              Theme.of(tester.element(find.byType(Scaffold)))
                  .scaffoldBackgroundColor;
          expect(page, c.groupedBackground, reason: label);

          // Fields: filled, no resting outline, fill differs from behind.
          final fields = find.byType(InputDecorator).evaluate().toList();
          expect(fields, isNotEmpty, reason: label);
          for (final element in fields) {
            final decoration = (element.widget as InputDecorator).decoration;
            expect(decoration.filled, isTrue, reason: label);
            final resting = decoration.enabledBorder ?? decoration.border;
            expect(
              resting == null ||
                  resting.borderSide.style == BorderStyle.none ||
                  resting.borderSide.width == 0,
              isTrue,
              reason: '$label resting outline $resting',
            );
            for (final bg in _behind(element)) {
              expect(decoration.fillColor, isNot(bg),
                  reason: '$label field fill same as behind');
            }
          }

          // Source capsules: no side, own fill, label AA on it.
          for (final s in AnalysisCvSource.values) {
            final button = find.byKey(ValueKey(s));
            final material = tester.widget<Material>(find
                .descendant(of: button, matching: find.byType(Material))
                .first);
            final shape = material.shape! as OutlinedBorder;
            expect(shape.side.style == BorderStyle.none || shape.side.width == 0,
                isTrue,
                reason: '$label ${s.name} side');
            expect(shape, isA<StadiumBorder>(), reason: label);
            for (final bg in _behind(tester.element(button))) {
              expect(material.color, isNot(bg),
                  reason: '$label ${s.name} fill same as behind');
            }
            expect(material.color,
                s == source ? c.primaryLight : c.groupedCard,
                reason: label);
          }
          // Exactly the chosen source carries the check.
          expect(
            find.descendant(
              of: find.byKey(ValueKey(source)),
              matching: find.byKey(CvAnalysisScreen.selectedSourceCheckKey),
            ),
            findsOneWidget,
            reason: label,
          );
          expect(find.byKey(CvAnalysisScreen.selectedSourceCheckKey),
              findsOneWidget,
              reason: label);

          if (source == AnalysisCvSource.upload) {
            final zone = tester.widget<Material>(find
                .descendant(
                  of: find.byType(UploadDropZone),
                  matching: find.byType(Material),
                )
                .first);
            expect(zone.shape, isNull, reason: '$label drop zone outline');
            for (final bg
                in _behind(tester.element(find.byType(UploadDropZone)))) {
              expect(zone.color, isNot(bg), reason: label);
            }
          }

          expectAllTextAa(label);
          expectAllIconsAa(label);
        });
      }
    }
  }
}
