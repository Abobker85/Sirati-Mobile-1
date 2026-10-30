/// Every visible label on every app screen comes from the server catalog.
///
/// Each screen in [appScreens] is pumped in Arabic and English with every
/// catalog message marked (an invisible word joiner prepended), served
/// through the same remote-label path the app uses. Painted text must then
/// be made of marked labels or the screen's sample data: text typed into the
/// code, a bundled fallback for a key the server lacks, or a string the
/// code builds itself has no mark and fails, even when it equals a label.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/utils/app_locale.dart';

import '../support/app_screens.dart';
import '../support/l10n_label_capture.dart';

const _mark = '⁠';

void main() {
  final catalogs = {
    for (final l in screenLanguages)
      l: {
        for (final e in readArbCatalog(l).entries) e.key: '$_mark${e.value}',
      },
  };

  setUpAll(loadAppFonts);
  setUp(setUpScreenTest);
  tearDown(tearDownScreenTest);

  for (final screen in appScreens) {
    for (final language in screenLanguages) {
      testWidgets('${screen.id}.$language shows only server labels',
          (tester) async {
        AppLocale.languageCode.value = language;
        tester.view.physicalSize = const Size(390, 844) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final recorder = L10nLabelRecorder();
        final h = ScreenHarness(language, recorder, catalogs);

        await http.runWithClient(() async {
          await screen.pump(tester, h);
          final root = tester.renderObject(find.byKey(screenRootKey));
          final labels = recorder.keysByValue.keys
              .where((v) => v.contains(_mark))
              .map((v) => v.replaceAll(_mark, ''));
          final unexplained = findUnexplainedText(root, [
            ...recorder.keysByValue.keys.where((v) => v.contains(_mark)),
            ...h.samples,
            // Avatar initials are the first letter of a sample name.
            for (final sample in h.samples)
              if (sample.trim().isNotEmpty)
                sample.trim().substring(0, 1).toUpperCase(),
          ]);
          expect(labels, isNotEmpty, reason: 'no server labels painted');
          expect(unexplained, isEmpty,
              reason: 'text on ${screen.id}.$language not from the server '
                  'catalog or sample data');

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        }, h.mockClient);
      });
    }
  }
}
