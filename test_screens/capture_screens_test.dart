/// l10n screen capture: renders the app's main screens in `ar` and `en` and
/// records, for every painted label, the l10n key it came from and its rect.
///
/// Run (from the Flutter app root; not part of the normal `flutter test`
/// run because it lives outside `test/`):
///
///   flutter test test_screens/capture_screens_test.dart
///
/// Output (git-ignored): `build/l10n_screens/<id>.<locale>.png` at 390 px
/// wide, pixel ratio 2, light theme, bundled IBM Plex Sans Arabic, plus
/// `build/l10n_screens/manifest.json` (version 1) listing each screen's
/// labels as `{key, x, y, w, h}` in logical px of that image, plus (so the
/// admin can paint edited text over the old one) the paragraph's plain
/// `text`, this key's `value` within it, `args` (placeholder name ->
/// displayed argument, keys with placeholders only), the `style` of the span
/// holding it (font_family, font_size, font_weight, color #RRGGBB, opacity,
/// align, direction, line_height, max_lines, lines) and `bg`, the most common
/// colour just outside the rect in the rendered pixels. Scroll views
/// are captured at their full content height (capped at [_maxHeight]); the
/// image height is in the manifest.
///
/// The admin label editor shows these screenshots and highlights the label
/// being edited. Copy the whole `build/l10n_screens/` folder to the Laravel
/// repo at `D:\Sirati\resources\i18n\screens\` (this test does not copy it).
///
/// Keys are recorded at runtime: a test-only [RecordingRemoteStringLookup]
/// feeds the bundled ARB messages through the generated
/// RemoteAppLocalizations, so each getter/method reports key -> final
/// string; painted RenderParagraph/RenderEditable text is then matched to
/// those strings (see `test/support/l10n_label_capture.dart`).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/utils/app_locale.dart';

import '../test/support/app_screens.dart';
import '../test/support/l10n_label_capture.dart';

const _width = 390.0;
const _height = 844.0;
const _pixelRatio = 2.0;
const _maxHeight = 4000.0;
const _outDir = 'build/l10n_screens';

Future<void> _precacheImages(WidgetTester tester) async {
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in images) {
      final image = element.widget as Image;
      await precacheImage(image.image, element, onError: (_, __) {});
    }
  });
  await tester.pump();
}

/// Content height of a scroll view: its slivers' extents when it is a
/// sliver viewport (exact once the view is tall enough to build them all,
/// and smaller than the viewport when content is short), else the extent
/// reported by its position.
double _contentHeight(ScrollableState scrollable) {
  final position = scrollable.position;
  RenderViewportBase? viewport;
  void find(RenderObject node) {
    if (viewport != null) return;
    if (node is RenderViewportBase) {
      viewport = node;
      return;
    }
    node.visitChildren(find);
  }

  final box = scrollable.context.findRenderObject();
  if (box != null) find(box);
  if (viewport case final v?) {
    var total = 0.0;
    v.visitChildren((child) {
      if (child is RenderSliver) total += child.geometry?.scrollExtent ?? 0;
    });
    return total;
  }
  return position.maxScrollExtent -
      position.minScrollExtent +
      position.viewportDimension;
}

/// Resizes the view so the primary onstage vertical scroll view shows all
/// of its content (between [_height] and [_maxHeight]); returns the height.
Future<double> _fitToContent(WidgetTester tester) async {
  var height = _height;
  for (var i = 0; i < 6; i++) {
    final onstage =
        onstageRenderObjects(tester.renderObject(find.byKey(screenRootKey)));
    final scrollables = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) =>
            s.position.axis == Axis.vertical &&
            s.position.hasContentDimensions &&
            onstage.contains(s.context.findRenderObject()))
        .toList();
    if (scrollables.isEmpty) break;
    scrollables.sort((a, b) =>
        b.position.viewportDimension.compareTo(a.position.viewportDimension));
    final primary = scrollables.first;
    final delta = _contentHeight(primary) - primary.position.viewportDimension;
    final next = (height + delta).clamp(_height, _maxHeight).ceilToDouble();
    if ((next - height).abs() < 1) break;
    height = next;
    tester.view.physicalSize = Size(_width, height) * _pixelRatio;
    await settleScreen(tester);
  }
  return height;
}

/// Writes the PNG and returns the same image's RGBA pixels with its size
/// (device px), for sampling label backgrounds.
Future<(ByteData, int, int)> _writePng(WidgetTester tester, String path) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(screenRootKey));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final size = (image.width, image.height);
    image.dispose();
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    return (rgba!, size.$1, size.$2);
  }))!;
}

String? _gitCommit() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    final sha = (result.stdout as String).trim();
    return result.exitCode == 0 && sha.isNotEmpty ? sha : null;
  } catch (_) {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalogs = {for (final l in screenLanguages) l: readArbCatalog(l)};
  final enKeys = catalogs['en']!.keys.toSet();
  // id -> language -> manifest entry for that image.
  final captured = <String, Map<String, Map<String, Object>>>{};

  setUpAll(() async {
    await loadAppFonts();
    final dir = Directory(_outDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
  });

  setUp(setUpScreenTest);
  tearDown(tearDownScreenTest);

  tearDownAll(() {
    final screens = [
      for (final (index, screen) in appScreens.indexed)
        if (captured[screen.id] case final locales?
            when locales.length == screenLanguages.length)
          {
            'id': screen.id,
            'name': screen.name,
            'order': index + 1,
            'locales': {for (final l in screenLanguages) l: locales[l]},
          },
    ];
    final manifest = {
      'version': 1,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'app_commit': _gitCommit(),
      'device': {'width': 390, 'height': 844, 'pixel_ratio': 2},
      'screens': screens,
    };
    File('$_outDir/manifest.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest));
  });

  for (final screen in appScreens) {
    for (final language in screenLanguages) {
      testWidgets('capture ${screen.id}.$language', (tester) async {
        AppLocale.languageCode.value = language;
        tester.view.physicalSize = const Size(_width, _height) * _pixelRatio;
        tester.view.devicePixelRatio = _pixelRatio;
        addTearDown(tester.view.reset);
        final recorder = L10nLabelRecorder();
        final h = ScreenHarness(language, recorder, catalogs);

        await http.runWithClient(() async {
          await screen.pump(tester, h);
          final height =
              screen.fullHeight ? await _fitToContent(tester) : _height;
          await _precacheImages(tester);
          await settleScreen(tester);

          final root = tester.renderObject(find.byKey(screenRootKey));
          final hits = findLabelHits(root, recorder.keysByValue,
              args: recorder.argsByKeyValue);
          expect(hits, isNotEmpty, reason: 'no labels found on ${screen.id}');
          for (final hit in hits) {
            expect(enKeys, contains(hit.key));
            expect(hit.rect.left, greaterThanOrEqualTo(0));
            expect(hit.rect.top, greaterThanOrEqualTo(0));
            expect(hit.rect.right, lessThanOrEqualTo(_width + 0.01));
            expect(hit.rect.bottom, lessThanOrEqualTo(height + 0.01));
          }

          final image = '${screen.id}.$language.png';
          final (rgba, imageW, imageH) =
              await _writePng(tester, '$_outDir/$image');
          (captured[screen.id] ??= {})[language] = {
            'image': image,
            'width': _width,
            'height': height,
            'labels': [
              for (final hit in hits)
                hit.toJson(
                    bg: sampleBackground(
                        rgba, imageW, imageH, hit.rect, _pixelRatio)),
            ],
          };

          // Unmount inside the zone so pending timers are cancelled.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        }, h.mockClient);
      });
    }
  }
}
