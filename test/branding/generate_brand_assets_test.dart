import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<Uint8List> _renderWidgetToPng({
  required WidgetTester tester,
  required Widget widget,
  required Size size,
}) async {
  await tester.binding.setSurfaceSize(size);
  final repaintKey = GlobalKey();

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: repaintKey,
          child: widget,
        ),
      ),
    ),
  );

  final boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

  Uint8List? pngBytes;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    pngBytes = byteData?.buffer.asUint8List();
  });

  return pngBytes!;
}

/// Every place the OS shows the brand draws the agreed logo (Salem review,
/// 2026-10-24): the teal gradient with the white check. Where the OS cuts
/// the icon to its own shape (iOS squircle, Android adaptive masks, PWA
/// maskable) the gradient fills the canvas and the OS does the rounding;
/// where nothing rounds it, the rounded logo itself is drawn.
void main() {
  testWidgets('Generate all Sirati brand assets directly from in-app SiratiMark',
      (tester) async {
    final appDir = _resolveFlutterAppDir();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> write(String path, Widget widget, double side) async {
      final bytes = await _renderWidgetToPng(
        tester: tester,
        widget: SizedBox.square(dimension: side, child: widget),
        size: Size.square(side),
      );
      final file = File('${appDir.path}/$path');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      expect(file.existsSync(), isTrue, reason: path);
    }

    // Full-bleed logo: gradient to every edge; the OS rounds it.
    Widget fullBleed(double side) => SiratiMark(size: side, rounded: false);

    // The rounded logo on a transparent canvas, where nothing else rounds it.
    Widget rounded(double side) => SiratiMark(size: side);

    // Gradient to every edge with the check scaled into [checkShare] of the
    // side, for masks that may cut into the outer ring (adaptive, maskable).
    Widget masked(double side, double checkShare, {bool withFill = true}) =>
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: withFill ? SiratiMark.gradient : null,
          ),
          child: Center(child: SiratiCheck(size: side * checkShare)),
        );

    // 1. iOS icon (and the source flutter_launcher_icons reads): opaque, the
    //    OS masks it to a squircle, so it reads exactly as the logo.
    await write('assets/branding/sirati_app_icon_1024.png', fullBleed(1024), 1024);

    // 2. Android 7 and older: no masking, so the rounded logo itself.
    await write(
        'assets/branding/sirati_app_icon_android_1024.png', rounded(1024), 1024);

    // 3-4. Android 8+ adaptive icon. Layers are 108dp; launchers show the
    //    middle 72dp and may mask anywhere outside the 66dp safe circle. The
    //    background is the gradient; the check is drawn so it stays inside
    //    the safe circle (see brand_assets_test) yet fills the visible 72dp
    //    like it fills the logo.
    await write('assets/branding/sirati_adaptive_background_1024.png',
        const DecoratedBox(decoration: BoxDecoration(gradient: SiratiMark.gradient)),
        1024);
    await write('assets/branding/sirati_adaptive_foreground_1024.png',
        masked(1024, adaptiveCheckShare, withFill: false), 1024);

    // 5-8. Web: rounded logo for the tab and "any" icons, gradient + inset
    //    check for maskable icons (80% safe zone).
    await write('web/favicon.png', rounded(32), 32);
    await write('web/icons/Icon-192.png', rounded(192), 192);
    await write('web/icons/Icon-512.png', rounded(512), 512);
    await write('web/icons/Icon-maskable-192.png', masked(192, 0.6), 192);
    await write('web/icons/Icon-maskable-512.png', masked(512, 0.6), 512);

    // 9. Native launch screens, at the size the Flutter splash draws the
    //    logo (96pt/dp) so the hand-off does not jump. Android 12+ shows the
    //    same bitmap through drawable/splash_icon.xml.
    final launchImages = <String, double>{
      'android/app/src/main/res/drawable-mdpi/splash_logo.png': 96,
      'android/app/src/main/res/drawable-hdpi/splash_logo.png': 144,
      'android/app/src/main/res/drawable-xhdpi/splash_logo.png': 192,
      'android/app/src/main/res/drawable-xxhdpi/splash_logo.png': 288,
      'android/app/src/main/res/drawable-xxxhdpi/splash_logo.png': 384,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': 96,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png': 192,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': 288,
    };
    for (final MapEntry(key: path, value: side) in launchImages.entries) {
      await write(path, rounded(side), side);
    }

    // 10. Android 12+ launch icon: the system draws a 288dp icon box (and
    //     crops it to a 192dp circle), so the logo sits at the same 96dp in
    //     the middle of a transparent 288dp canvas. A plain bitmap, because
    //     an <inset> drawable here showed nothing on the emulator.
    for (final MapEntry(key: density, value: scale) in const {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    }.entries) {
      await write(
        'android/app/src/main/res/drawable-$density/splash_icon.png',
        Center(child: rounded(launchLogoSize * scale)),
        android12IconBox * scale,
      );
    }
  });
}

/// Side of the Android 12+ launch icon box, in dp.
const android12IconBox = 288.0;

/// Share of the adaptive foreground's side the check is laid out in. The
/// check's farthest painted point is 0.466 of its box from the centre, and
/// it must stay within the 66/108 safe circle: 0.466·s ≤ 1024·33/108.
const adaptiveCheckShare = 0.65;

/// Logo size of every launch screen and the Flutter splash, in pt/dp.
const launchLogoSize = 96.0;
