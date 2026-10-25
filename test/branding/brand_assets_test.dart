import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import 'generate_brand_assets_test.dart'
    show adaptiveCheckShare, android12IconBox, launchLogoSize;

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
    Future<(ByteData, int, int)> decode(WidgetTester tester, String path) async {
      final file = File('${_resolveFlutterAppDir().path}/$path');
      expect(file.existsSync(), isTrue, reason: '$path must exist');
      final codec =
          await tester.runAsync(() => ui.instantiateImageCodec(file.readAsBytesSync()));
      final image = (await tester.runAsync(() => codec!.getNextFrame()))!.image;
      final data = await tester
          .runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba));
      return (data!, image.width, image.height);
    }

    Future<ByteData> render(WidgetTester tester, Widget widget, int side) async {
      await tester.binding.setSurfaceSize(Size.square(side.toDouble()));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(key: key, child: widget)),
      ));
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await tester.runAsync(boundary.toImage);
      return (await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
    }

    testWidgets(
        'icons the OS rounds are the logo edge to edge: the in-app gradient and check',
        (tester) async {
      for (final path in [
        'assets/branding/sirati_app_icon_1024.png',
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      ]) {
        final (disk, w, h) = await decode(tester, path);
        expect((w, h), (1024, 1024), reason: path);
        final inApp = await render(
            tester, const SiratiMark(size: 1024, rounded: false), 1024);
        // Corners, edges and inner points all match the in-app logo: no
        // frame of another colour, no transparency (App Store rule).
        for (final (x, y) in [
          (0, 0), (1023, 0), (0, 1023), (1023, 1023), (512, 0), (0, 512),
          (512, 512), (300, 300), (724, 724), (180, 560), (760, 230),
        ]) {
          final pixel = _getPixel(disk, w, x, y);
          expect(pixel.a, 255, reason: '$path ($x,$y) opaque');
          _expectColorsMatch(pixel, _getPixel(inApp, 1024, x, y),
              tolerance: 3, reason: '$path ($x,$y)');
        }
      }
    });

    testWidgets(
        'Android adaptive icon: gradient background, white check inside the safe circle',
        (tester) async {
      final (back, bw, _) =
          await decode(tester, 'assets/branding/sirati_adaptive_background_1024.png');
      final gradient = await render(
          tester,
          const SizedBox.square(
              dimension: 1024,
              child: DecoratedBox(
                  decoration: BoxDecoration(gradient: SiratiMark.gradient))),
          1024);
      for (final (x, y) in [(0, 0), (1023, 1023), (512, 512), (200, 800)]) {
        _expectColorsMatch(_getPixel(back, bw, x, y), _getPixel(gradient, 1024, x, y),
            tolerance: 3, reason: 'background ($x,$y)');
      }

      final (fore, fw, _) =
          await decode(tester, 'assets/branding/sirati_adaptive_foreground_1024.png');
      expect(_getPixel(fore, fw, 0, 0).a, 0, reason: 'foreground corners transparent');
      const safeRadius = 1024 * 33 / 108;
      var white = 0;
      for (var y = 0; y < 1024; y += 4) {
        for (var x = 0; x < 1024; x += 4) {
          final p = _getPixel(fore, fw, x, y);
          if (p.a == 0) continue;
          // Edge pixels are anti-aliased (and premultiplied): only solid
          // pixels must be pure white.
          if (p.a == 255) {
            expect((p.r, p.g, p.b), (255, 255, 255), reason: 'only the white check ($x,$y)');
            white++;
          }
          final d = sqrt(pow(x + .5 - 512, 2) + pow(y + .5 - 512, 2));
          expect(d, lessThanOrEqualTo(safeRadius),
              reason: 'painted pixel ($x, $y) is outside the safe zone');
        }
      }
      // The check fills the visible 72dp about as it fills the logo.
      expect(white, greaterThan(2500));
      expect(adaptiveCheckShare * 1024, greaterThan(1024 * 72 / 108 * 0.9));

      // No navy frame or extra inset left in the generated launcher files.
      final xml = File('${_resolveFlutterAppDir().path}/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(xml, contains('@drawable/ic_launcher_background'));
      expect(xml, isNot(contains('android:inset="16%"')));
    });

    testWidgets('every launch screen shows the rounded logo at the Flutter splash size',
        (tester) async {
      final root = _resolveFlutterAppDir().path;
      for (final (path, side) in [
        ('android/app/src/main/res/drawable-mdpi/splash_logo.png', 1.0),
        ('android/app/src/main/res/drawable-hdpi/splash_logo.png', 1.5),
        ('android/app/src/main/res/drawable-xhdpi/splash_logo.png', 2.0),
        ('android/app/src/main/res/drawable-xxhdpi/splash_logo.png', 3.0),
        ('android/app/src/main/res/drawable-xxxhdpi/splash_logo.png', 4.0),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png', 1.0),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png', 2.0),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', 3.0),
      ]) {
        final (data, w, h) = await decode(tester, path);
        final px = (launchLogoSize * side).round();
        expect((w, h), (px, px), reason: path);
        expect(_getPixel(data, w, 0, 0).a, lessThan(60), reason: '$path rounded corner');
        expect(_getPixel(data, w, w ~/ 7, h ~/ 7).a, 255, reason: '$path square body');
      }
      // Android 12+: the same logo, same size, centred in the 288dp box.
      for (final (density, scale) in const [
        ('mdpi', 1.0), ('hdpi', 1.5), ('xhdpi', 2.0), ('xxhdpi', 3.0), ('xxxhdpi', 4.0),
      ]) {
        final path = 'android/app/src/main/res/drawable-$density/splash_icon.png';
        final (data, w, h) = await decode(tester, path);
        final box = (android12IconBox * scale).round();
        expect((w, h), (box, box), reason: path);
        final logo = launchLogoSize * scale;
        final edge = ((box - logo) / 2).round();
        expect(_getPixel(data, w, edge - 2, box ~/ 2).a, 0, reason: '$path left of logo');
        expect(_getPixel(data, w, edge + 3, box ~/ 2).a, 255, reason: '$path logo body');
        expect(_getPixel(data, w, box ~/ 2, box ~/ 2).a, 255, reason: '$path centre');
        expect(_getPixel(data, w, box - edge + 2, box ~/ 2).a, 0,
            reason: '$path right of logo');
      }
      for (final v31 in ['values-v31', 'values-night-v31']) {
        final styles =
            File('$root/android/app/src/main/res/$v31/styles.xml').readAsStringSync();
        expect(styles, contains('@drawable/splash_icon'), reason: v31);
        expect(styles, contains('@color/splash_background'), reason: v31);
      }
      // Flutter swaps to NormalTheme at once: it must keep the logo up until
      // Flutter's first frame, in light and dark.
      for (final values in ['values', 'values-night']) {
        final styles =
            File('$root/android/app/src/main/res/$values/styles.xml').readAsStringSync();
        final normal = styles.substring(styles.indexOf('name="NormalTheme"'));
        expect(
          normal.substring(0, normal.indexOf('</style>')),
          contains('<item name="android:windowBackground">@drawable/launch_background</item>'),
          reason: values,
        );
      }
      expect(
        File('$root/ios/Runner/Base.lproj/LaunchScreen.storyboard').readAsStringSync(),
        contains('<image name="LaunchImage" width="${launchLogoSize.round()}" '
            'height="${launchLogoSize.round()}"/>'),
      );
    });

    testWidgets('the mark is the agreed rounded square at every size',
        (tester) async {
      for (final side in [22.0, 56.0, 96.0, 288.0, 635.0]) {
        await tester.binding.setSurfaceSize(Size.square(side));
        final key = GlobalKey();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SiratiMark(size: side),
            ),
          ),
        ));
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await tester.runAsync(boundary.toImage);
        final data = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
        final n = side.round();
        _RgbaColor at(double fx, double fy) => _getPixel(
            data!, n, (fx * (n - 1)).round(), (fy * (n - 1)).round());

        // Inside a square but outside the circle it replaced: painted.
        for (final (fx, fy) in [(.14, .14), (.86, .14), (.14, .86), (.86, .86)]) {
          expect(at(fx, fy).a, greaterThan(200),
              reason: '$side: ($fx, $fy) must be painted (square body)');
        }
        // The very corners are rounded off: transparent.
        for (final (fx, fy) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
          expect(at(fx, fy).a, lessThan(60),
              reason: '$side: corner ($fx, $fy) must be rounded off');
        }
      }
      await tester.binding.setSurfaceSize(null);
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
