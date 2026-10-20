import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/ai_field_loading_overlay.dart';

// Production callers: AiCvField and the CV generator's personal step.
void main() {
  for (final dark in [false, true]) {
    testWidgets('AI status surface fills the field, dark=$dark', (tester) async {
      final theme = dark ? AppTheme.dark : AppTheme.light;
      final colors = theme.extension<SiratiColors>()!;
      for (final direction in TextDirection.values) {
        for (final height in [48.0, 180.0, 420.0]) {
          final status = direction == TextDirection.rtl
              ? 'جارٍ تحسين محتوى السيرة الذاتية'
              : 'Improving the wording of your experience';
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: Directionality(
                    textDirection: direction,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 37, left: 19),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: AiFieldLoadingOverlay(
                          isLoading: true,
                          statusMessages: [status],
                          child: SizedBox(
                            key: const ValueKey('field'),
                            width: 280,
                            height: height,
                            child: const TextField(
                              expands: true,
                              minLines: null,
                              maxLines: null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final overlay = find.byType(AiFieldLoadingOverlay);
          final fieldBounds = tester.getRect(find.byKey(const ValueKey('field')));
          expect(tester.getRect(overlay), fieldBounds);

          // Select the painted surface that actually contains the status,
          // so a separate full-size background cannot mask a short veil.
          final surface = find.ancestor(
            of: find.text(status),
            matching: find.byType(ColoredBox),
          ).first;
          expect(tester.getRect(surface), fieldBounds);
          final fill = tester.widget<ColoredBox>(surface).color;
          expect(fill, colors.surface);
          expect(fill.a, 1);
          final clip = find.ancestor(
            of: surface,
            matching: find.byType(ClipRRect),
          ).first;
          expect(tester.getRect(clip), fieldBounds);

          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text(status),
              matching: find.byType(RichText),
            ),
          );
          final ink = (paragraph.text as TextSpan).style!.color!;
          expect(AppContrast.ratio(ink, fill), greaterThanOrEqualTo(4.5));
          final statusBounds = tester.getRect(find.ancestor(
            of: find.text(status),
            matching: find.byType(Column),
          ).first);
          if (height == 420) {
            expect(statusBounds.height, lessThan(fieldBounds.height));
          }
          if (statusBounds.height <= fieldBounds.height) {
            expect(statusBounds.center.dx, closeTo(fieldBounds.center.dx, 1e-6));
            expect(statusBounds.center.dy, closeTo(fieldBounds.center.dy, 1e-6));
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
