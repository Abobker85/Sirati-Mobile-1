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

void main() {
  testWidgets('Generate all Sirati brand assets directly from in-app SiratiMark',
      (tester) async {
    final appDir = _resolveFlutterAppDir();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const navy = Color(0xFF12384F);

    // 1. assets/branding/sirati_app_icon_1024.png
    // Full-bleed navy (#12384F) square background with the circle mark
    // centred at about 62% of the canvas (1024 * 0.62 = 634.88 -> 635).
    // iOS cannot have transparency and masks to a squircle.
    final appIconBytes = await _renderWidgetToPng(
      tester: tester,
      widget: Container(
        width: 1024,
        height: 1024,
        color: navy,
        alignment: Alignment.center,
        child: const SiratiMark(size: 635, elevated: false),
      ),
      size: const Size(1024, 1024),
    );
    final appIconFile =
        File('${appDir.path}/assets/branding/sirati_app_icon_1024.png');
    appIconFile.parent.createSync(recursive: true);
    appIconFile.writeAsBytesSync(appIconBytes);
    expect(appIconFile.existsSync(), isTrue);

    // 2. assets/branding/sirati_adaptive_foreground_1024.png
    // Transparent-background foreground for the Android adaptive icon. The
    // launcher may mask to a circle of diameter 66/108 (625.8px), so the
    // rounded square's farthest point, (s/2 - r)·√2 + r with r = 0.22·s,
    // i.e. 0.616·s, must stay within 312.9px: s <= 507 -> size: 500.
    final adaptiveBytes = await _renderWidgetToPng(
      tester: tester,
      widget: Container(
        width: 1024,
        height: 1024,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: const SiratiMark(size: adaptiveMarkSize, elevated: false),
      ),
      size: const Size(1024, 1024),
    );
    final adaptiveFile =
        File('${appDir.path}/assets/branding/sirati_adaptive_foreground_1024.png');
    adaptiveFile.parent.createSync(recursive: true);
    adaptiveFile.writeAsBytesSync(adaptiveBytes);
    expect(adaptiveFile.existsSync(), isTrue);

    // 3. web/favicon.png (32x32)
    // The transparent circle mark for browser tabs.
    final faviconBytes = await _renderWidgetToPng(
      tester: tester,
      widget: Container(
        width: 32,
        height: 32,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: const SiratiMark(size: 32, elevated: false),
      ),
      size: const Size(32, 32),
    );
    final faviconFile = File('${appDir.path}/web/favicon.png');
    faviconFile.parent.createSync(recursive: true);
    faviconFile.writeAsBytesSync(faviconBytes);
    expect(faviconFile.existsSync(), isTrue);

    // 4. web/icons/Icon-192.png (192x192)
    final icon192Bytes = await _renderWidgetToPng(
      tester: tester,
      widget: Container(
        width: 192,
        height: 192,
        color: navy,
        alignment: Alignment.center,
        child: const SiratiMark(size: 119, elevated: false), // 192 * 0.62
      ),
      size: const Size(192, 192),
    );
    final icon192File = File('${appDir.path}/web/icons/Icon-192.png');
    icon192File.parent.createSync(recursive: true);
    icon192File.writeAsBytesSync(icon192Bytes);
    expect(icon192File.existsSync(), isTrue);

    // 5. web/icons/Icon-512.png (512x512)
    final icon512Bytes = await _renderWidgetToPng(
      tester: tester,
      widget: Container(
        width: 512,
        height: 512,
        color: navy,
        alignment: Alignment.center,
        child: const SiratiMark(size: 317, elevated: false), // 512 * 0.62
      ),
      size: const Size(512, 512),
    );
    final icon512File = File('${appDir.path}/web/icons/Icon-512.png');
    icon512File.parent.createSync(recursive: true);
    icon512File.writeAsBytesSync(icon512Bytes);
    expect(icon512File.existsSync(), isTrue);

    // 6. web/icons/Icon-maskable-192.png (192x192)
    final maskable192File =
        File('${appDir.path}/web/icons/Icon-maskable-192.png');
    maskable192File.parent.createSync(recursive: true);
    maskable192File.writeAsBytesSync(icon192Bytes);
    expect(maskable192File.existsSync(), isTrue);

    // 7. web/icons/Icon-maskable-512.png (512x512)
    final maskable512File =
        File('${appDir.path}/web/icons/Icon-maskable-512.png');
    maskable512File.parent.createSync(recursive: true);
    maskable512File.writeAsBytesSync(icon512Bytes);
    expect(maskable512File.existsSync(), isTrue);

    // 8. Native launch screens: the transparent mark the OS shows before
    // Flutter starts (Android 72dp per density, iOS 128pt @1x/2x/3x).
    final launchImages = <String, int>{
      'android/app/src/main/res/drawable-mdpi/splash_logo.png': 72,
      'android/app/src/main/res/drawable-hdpi/splash_logo.png': 96,
      'android/app/src/main/res/drawable-xhdpi/splash_logo.png': 144,
      'android/app/src/main/res/drawable-xxhdpi/splash_logo.png': 192,
      'android/app/src/main/res/drawable-xxxhdpi/splash_logo.png': 288,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': 128,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png':
          256,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png':
          384,
    };
    for (final MapEntry(key: path, value: side) in launchImages.entries) {
      final bytes = await _renderWidgetToPng(
        tester: tester,
        widget: SizedBox.square(
          dimension: side.toDouble(),
          child: SiratiMark(size: side.toDouble(), elevated: false),
        ),
        size: Size.square(side.toDouble()),
      );
      final file = File('${appDir.path}/$path');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }
  });
}

/// Side of the mark on the Android adaptive foreground (see step 2).
const adaptiveMarkSize = 500.0;
