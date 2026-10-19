// ignore_for_file: avoid_print
import 'dart:io';

/// Regenerates all Sirati brand assets and launcher icons:
/// 1. Runs the Flutter widget test that renders [SiratiMark] to 1024x1024 PNGs
///    (app icon, adaptive foreground, web favicon and PWA icons).
/// 2. Runs `flutter_launcher_icons` to update Android mipmaps and iOS AppIconset.
///
/// Usage:
///   dart run tool/generate_brand_assets.dart
/// or
///   dart tool/generate_brand_assets.dart
Future<void> main() async {
  print('Step 1/2: Rendering SiratiMark to brand assets via Flutter test...');
  final testResult = await Process.run(
    'flutter',
    ['test', 'test/branding/generate_brand_assets_test.dart'],
    runInShell: true,
  );
  stdout.write(testResult.stdout);
  stderr.write(testResult.stderr);

  if (testResult.exitCode != 0) {
    print('Failed to render brand assets.');
    exit(testResult.exitCode);
  }

  print('\nStep 2/2: Generating platform launcher icons via flutter_launcher_icons...');
  final launcherResult = await Process.run(
    'dart',
    ['run', 'flutter_launcher_icons'],
    runInShell: true,
  );
  stdout.write(launcherResult.stdout);
  stderr.write(launcherResult.stderr);

  if (launcherResult.exitCode != 0) {
    print('Failed to generate launcher icons.');
    exit(launcherResult.exitCode);
  }

  print('\n✓ All brand assets and launcher icons regenerated successfully!');
}
