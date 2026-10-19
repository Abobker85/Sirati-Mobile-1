import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Directory _resolveFlutterAppDir() {
  final current = Directory.current;
  if (File('${current.path}/pubspec.yaml').existsSync() &&
      Directory('${current.path}/lib').existsSync()) {
    return current;
  }
  final sub = Directory('${current.path}/flutter_app');
  if (sub.existsSync() && File('${sub.path}/pubspec.yaml').existsSync()) {
    return sub;
  }
  return current;
}

class _RgbaColor {
  final int r, g, b, a;
  const _RgbaColor(this.r, this.g, this.b, this.a);

  @override
  String toString() => 'RGBA($r, $g, $b, $a)';
}

_RgbaColor _getPixel(ByteData byteData, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return _RgbaColor(
    byteData.getUint8(offset),
    byteData.getUint8(offset + 1),
    byteData.getUint8(offset + 2),
    byteData.getUint8(offset + 3),
  );
}

void _expectColorsMatch(
  _RgbaColor actual,
  _RgbaColor expected, {
  int tolerance = 2,
  required String reason,
}) {
  expect(
    (actual.r - expected.r).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$reason: Red channel mismatch ($actual vs $expected)',
  );
  expect(
    (actual.g - expected.g).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$reason: Green channel mismatch ($actual vs $expected)',
  );
  expect(
    (actual.b - expected.b).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$reason: Blue channel mismatch ($actual vs $expected)',
  );
  expect(
    (actual.a - expected.a).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$reason: Alpha channel mismatch ($actual vs $expected)',
  );
}

void main() {
  group('Brand Mark Pixel Consistency (In-App Mark vs Generated Icons)', () {
    testWidgets(
        'in-app SiratiMark renders identical gradient circle colours to generated icon PNG',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final appDir = _resolveFlutterAppDir();
      final iconFile =
          File('${appDir.path}/assets/branding/sirati_app_icon_1024.png');
      expect(iconFile.existsSync(), isTrue,
          reason: 'App icon 1024 must exist on disk');

      // 1. Decode PNG from disk into raw RGBA bytes
      final iconBytes = iconFile.readAsBytesSync();
      final codec = await tester.runAsync(() => ui.instantiateImageCodec(iconBytes));
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      final diskImage = frame!.image;
      expect(diskImage.width, 1024);
      expect(diskImage.height, 1024);
      final diskByteData = await tester
          .runAsync(() => diskImage.toByteData(format: ui.ImageByteFormat.rawRgba));

      // 2. Render in-app SiratiMark with identical widget hierarchy
      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: Container(
                width: 1024,
                height: 1024,
                color: const Color(0xFF12384F),
                alignment: Alignment.center,
                child: const SiratiMark(size: 635, elevated: false),
              ),
            ),
          ),
        ),
      );

      final boundary = repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final inAppImage =
          await tester.runAsync(() => boundary.toImage(pixelRatio: 1.0));
      final inAppByteData = await tester.runAsync(
          () => inAppImage!.toByteData(format: ui.ImageByteFormat.rawRgba));

      // 3. Sample center pixel (512, 512):
      // The mark center is the gradient midpoint between #12384F and #0E8F86.
      final diskCenter = _getPixel(diskByteData!, 1024, 512, 512);
      final inAppCenter = _getPixel(inAppByteData!, 1024, 512, 512);

      _expectColorsMatch(
        diskCenter,
        inAppCenter,
        tolerance: 2,
        reason: 'Center pixel of generated icon must match in-app mark',
      );

      // Verify center color matches theoretical gradient t=0.5:
      // (18+14)/2 = 16, (56+143)/2 ≈ 100, (79+134)/2 ≈ 107
      expect((diskCenter.r - 16).abs(), lessThanOrEqualTo(2));
      expect((diskCenter.g - 100).abs(), lessThanOrEqualTo(2));
      expect((diskCenter.b - 107).abs(), lessThanOrEqualTo(2));
      expect(diskCenter.a, 255);

      // 4. Sample ring pixels around the center at radius r = 200:
      // Angles: 135° (bottom-right: towards #0E8F86), 315° (top-left: towards #12384F)
      const ringRadius = 200.0;
      final sampleAngles = [
        -3 * pi / 4, // top-left (navy gradient start)
        -pi / 4, // top-right
        pi / 4, // bottom-right (teal gradient end)
        3 * pi / 4, // bottom-left
      ];

      for (final angle in sampleAngles) {
        final x = (512 + ringRadius * cos(angle)).round();
        final y = (512 + ringRadius * sin(angle)).round();

        final diskRing = _getPixel(diskByteData, 1024, x, y);
        final inAppRing = _getPixel(inAppByteData, 1024, x, y);

        _expectColorsMatch(
          diskRing,
          inAppRing,
          tolerance: 2,
          reason: 'Ring pixel at ($x, $y) must match in-app mark',
        );
      }

      // 5. Verify gradient directionality across ring:
      // Top-left should have higher blue/navy, bottom-right should have higher teal/green.
      final tlPixel = _getPixel(diskByteData, 1024, (512 - 141), (512 - 141));
      final brPixel = _getPixel(diskByteData, 1024, (512 + 141), (512 + 141));
      expect(brPixel.g, greaterThan(tlPixel.g),
          reason: 'Teal bottom-right must have higher green than navy top-left');

      // 6. Full-bleed background verification: no transparent corners for iOS!
      final corners = [
        const Point(0, 0),
        const Point(1023, 0),
        const Point(0, 1023),
        const Point(1023, 1023),
      ];
      for (final pt in corners) {
        final cornerPixel = _getPixel(diskByteData, 1024, pt.x, pt.y);
        expect(cornerPixel.a, 255,
            reason: 'App icon corner at ${pt.x},${pt.y} must be fully opaque');
        expect(cornerPixel.r, 18, reason: 'Background must be navy #12384F');
        expect(cornerPixel.g, 56, reason: 'Background must be navy #12384F');
        expect(cornerPixel.b, 79, reason: 'Background must be navy #12384F');
      }
    });

    testWidgets(
        'Android adaptive foreground PNG has transparent corners and mark within safe zone',
        (tester) async {
      final appDir = _resolveFlutterAppDir();
      final adaptiveFile = File(
          '${appDir.path}/assets/branding/sirati_adaptive_foreground_1024.png');
      expect(adaptiveFile.existsSync(), isTrue);

      final bytes = adaptiveFile.readAsBytesSync();
      final codec = await tester.runAsync(() => ui.instantiateImageCodec(bytes));
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      final img = frame!.image;
      expect(img.width, 1024);
      expect(img.height, 1024);

      final byteData =
          await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));

      // Corners must be 100% transparent
      final cornerTL = _getPixel(byteData!, 1024, 0, 0);
      final cornerBR = _getPixel(byteData, 1024, 1023, 1023);
      expect(cornerTL.a, 0, reason: 'Adaptive icon foreground corner must be transparent');
      expect(cornerBR.a, 0, reason: 'Adaptive icon foreground corner must be transparent');

      // Center must be opaque and match gradient center
      final center = _getPixel(byteData, 1024, 512, 512);
      expect(center.a, 255);
      expect((center.r - 16).abs(), lessThanOrEqualTo(2));
      expect((center.g - 100).abs(), lessThanOrEqualTo(2));
      expect((center.b - 107).abs(), lessThanOrEqualTo(2));
    });
  });

  group('Brand Name Consistency (Siratie vs سيرتي)', () {
    test('English brand strings contain Siratie and Arabic strings remain سيرتي',
        () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));

      // English assertions
      expect(en.appTitle, 'Siratie');
      expect(en.welcomeToSirati, 'Welcome to Siratie');
      expect(en.contactUsEmailSubject, 'Siratie Support Inquiry');
      expect(en.premiumGateAppBar, 'Siratie Premium');

      // Arabic assertions (must remain untouched)
      expect(ar.appTitle, 'سيرتي');
      expect(ar.welcomeToSirati, 'مرحباً بك في سيرتي');
      expect(ar.contactUsEmailSubject, 'استفسار الدعم الفني - سيرتي');
      expect(ar.premiumGateAppBar, 'سيرتي المميز');
    });

    test('Repository check: no English "Sirati " (without e) remains in app_en.arb',
        () {
      final appDir = _resolveFlutterAppDir();
      final arbFile = File('${appDir.path}/lib/l10n/app_en.arb');
      expect(arbFile.existsSync(), isTrue);

      final arbContent = arbFile.readAsStringSync();

      // Rule: No "Sirati" word followed by space or boundary without 'e'
      // Matches "Sirati " or "Sirati\"" but not "Siratie"
      final regex = RegExp(r'\bSirati\b(?!e)');
      final matches = regex.allMatches(arbContent);

      expect(
        matches.isEmpty,
        isTrue,
        reason:
            'Found obsolete "Sirati" (without e) in app_en.arb: ${matches.map((m) => m.input.substring(max(0, m.start - 10), min(m.input.length, m.end + 10))).toList()}',
      );
    });
  });
}
