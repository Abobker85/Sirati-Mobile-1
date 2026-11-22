import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';

import '../../support/app_screens.dart';
import '../../support/contrast_probe.dart';
import '../../support/l10n_label_capture.dart';

/// Ticket 22: on the real screens that carry segmented tabs, at 320dp with
/// the app fonts, no tab or language-toggle label is drawn smaller than its
/// natural size, nothing is clipped, and the app bar holds the (possibly
/// taller, wrapped) bar. Callers pass nothing extra: the bar reserves its own
/// height.
void main() {
  final catalogs = {
    for (final l in screenLanguages) l: readArbCatalog(l),
  };

  setUpAll(loadAppFonts);
  setUp(setUpScreenTest);
  tearDown(tearDownScreenTest);

  const screens = ['analysis_result', 'history'];
  const scales = [1.0, 1.3, 2.0];

  /// Painted size over laid-out size: below 1 means the label was shrunk.
  double drawnScale(Element text) {
    final paragraph = paragraphOf(text.findRenderObject()!);
    final painted = MatrixUtils.transformRect(
        paragraph.getTransformTo(null), Offset.zero & paragraph.size);
    return painted.width / paragraph.size.width;
  }

  for (final id in screens) {
    for (final language in screenLanguages) {
      for (final scale in scales) {
        testWidgets('$id.$language x$scale: tab labels whole, never shrunk',
            (tester) async {
          AppLocale.languageCode.value = language;
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final h = ScreenHarness(language, L10nLabelRecorder(), catalogs);
          final screen = appScreens.firstWhere((s) => s.id == id);

          await http.runWithClient(() async {
            await screen.pump(tester, h);
            final reason = '$id.$language x$scale';
            expect(tester.takeException(), isNull, reason: reason);

            final bar = find.byType(AppSegmentedTabBar);
            expect(bar, findsOneWidget, reason: reason);
            final barRect = tester.getRect(bar);
            final track = tester.getRect(find.descendant(
                of: bar, matching: find.byKey(SegmentedTrack.trackKey)));
            // The app bar reserved enough height: the track is inside the
            // bar's slot and the slot inside the app bar.
            expect(track.top, greaterThanOrEqualTo(barRect.top - 0.5),
                reason: reason);
            expect(track.bottom, lessThanOrEqualTo(barRect.bottom + 0.5),
                reason: reason);
            expect(
                barRect.bottom,
                lessThanOrEqualTo(
                    tester.getRect(find.byType(AppBar)).bottom + 0.5),
                reason: reason);
            // Not over-reserved beyond the contract: the slot is exactly
            // the bar's own measure for these tabs on this view.
            final barWidget = tester.widget<AppSegmentedTabBar>(bar);
            final reserved = barWidget.preferredSize.height;
            final measured = SegmentLayout.heightWithoutContext(
                  labels: barWidget.tabs,
                  maxWidth: 320 -
                      barWidget.padding.horizontal -
                      2 * AppSegmentedControl.trackInset,
                  labelPadding: barWidget.labelPadding,
                  scaler: TextScaler.linear(scale),
                ) +
                2 * AppSegmentedControl.trackInset +
                barWidget.padding.vertical;
            expect(reserved, moreOrLessEquals(measured, epsilon: 1e-6),
                reason: reason);
            // The laid-out control fits what was reserved.
            expect(track.height + barWidget.padding.vertical,
                lessThanOrEqualTo(reserved + 0.5),
                reason: reason);
            expect(track.left, greaterThanOrEqualTo(0), reason: reason);
            expect(track.right, lessThanOrEqualTo(320), reason: reason);

            final labels = [
              ...find
                  .descendant(of: bar, matching: find.byType(Text))
                  .evaluate(),
              ...find
                  .descendant(
                      of: find.byType(LanguageToggle),
                      matching: find.byType(Text))
                  .evaluate(),
            ];
            expect(labels, isNotEmpty, reason: reason);
            // Shrinking is only the last resort: when the longest words of
            // all tabs cannot sit side by side even wrapped. Then every tab
            // label is drawn at that one factor (reported for the ticket).
            final widget = tester.widget<AppSegmentedTabBar>(bar);
            final layout = SegmentLayout.compute(
              tester.element(
                  find.descendant(of: bar, matching: find.byType(Row)).first),
              labels: widget.tabs,
              maxWidth: track.width - 2 * AppSegmentedControl.trackInset,
              labelPadding: widget.labelPadding,
            );
            final tabTexts = find
                .descendant(of: bar, matching: find.byType(Text))
                .evaluate()
                .toSet();
            for (final element in labels) {
              final text = element.widget as Text;
              final paragraph = paragraphOf(element.findRenderObject()!);
              final label = '"${text.data}" $reason';
              final drawn = drawnScale(element);
              if (layout.scaled && tabTexts.contains(element)) {
                debugPrint('[scaled] $label at ${drawn.toStringAsFixed(2)}');
                expect(drawn, moreOrLessEquals(layout.scale, epsilon: 0.01),
                    reason: '$label drawn at the shared factor');
              } else {
                expect(drawn, greaterThanOrEqualTo(0.999),
                    reason: '$label drawn shrunk');
              }
              expect(paragraph.getMinIntrinsicWidth(double.infinity),
                  lessThanOrEqualTo(paragraph.size.width + 0.5),
                  reason: '$label: longest word fits');
              expect(paragraph.getMaxIntrinsicHeight(paragraph.size.width),
                  lessThanOrEqualTo(paragraph.size.height + 0.5),
                  reason: '$label: every line fits');
            }

            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 5));
          }, h.mockClient);
        });
      }
    }
  }
}
