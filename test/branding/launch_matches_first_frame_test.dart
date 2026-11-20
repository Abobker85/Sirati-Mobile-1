import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/application/session_bootstrap.dart';
import 'package:sirati/features/dashboard/presentation/splash_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:xml/xml.dart';

import '../android_night_launch_theme_test.dart' show AndroidResourceTable;
import '../support/contrast_probe.dart';

/// The native launch screen hands over to Flutter's first frame (the boot
/// beat of [SplashScreen]). Both must paint the same page colour in light
/// and dark, or a cold start flashes one colour then the other.
void main() {
  /// What the first Flutter frame paints behind the boot mark.
  Future<int> firstFramePage(WidgetTester tester, {required bool dark}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sessionBootstrapProvider.overrideWithValue(SessionBootstrap(
          // Never resolves: the boot beat stays up.
          readToken: () => Completer<String?>().future,
          fetchUser: () async => null,
          onboardingCompleted: () async => true,
        )),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SplashScreen(),
      ),
    ));
    await tester.pump();
    final painted = paintedBackgroundsOf(
      tester.element(find.byKey(const ValueKey('splash_circle'))),
    );
    expect(painted.toSet(), hasLength(1));
    return painted.single.toARGB32();
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('Android launch window equals the first frame ($mode)',
        (tester) async {
      final page = await firstFramePage(tester, dark: dark);
      for (final api in [19, 21, 31, 34]) {
        final table = AndroidResourceTable.parse(
          Directory('android/app/src/main/res'),
          api: api,
        );
        expect(table.launchWindowColor(night: dark), page,
            reason: 'LaunchTheme windowBackground, API $api');
        expect(table.launchBackground(night: dark).color, page,
            reason: 'launch_background layer, API $api');
        // Android 12+ draws its own splash from splash_background.
        expect(table.colorValue('splash_background', night: dark), page,
            reason: 'splash_background, API $api');
      }
    });

    testWidgets('iOS launch screen equals the first frame ($mode)',
        (tester) async {
      final page = await firstFramePage(tester, dark: dark);
      expect(_iosLaunchBackground(dark: dark), page);
    });
  }
}

/// The colour iOS paints behind LaunchScreen.storyboard's root view: a named
/// colour resolved through the asset catalog for the given appearance.
int _iosLaunchBackground({required bool dark}) {
  final storyboard = XmlDocument.parse(
    File('ios/Runner/Base.lproj/LaunchScreen.storyboard').readAsStringSync(),
  );
  final view = storyboard
      .findAllElements('view')
      .singleWhere((v) => v.getAttribute('key') == 'view');
  final background = view.childElements.singleWhere((e) =>
      e.name.local == 'color' && e.getAttribute('key') == 'backgroundColor');
  final name = background.getAttribute('name');
  expect(name, isNotNull,
      reason: 'a literal colour has no dark variant; use a named colour');

  final json = jsonDecode(File(
    'ios/Runner/Assets.xcassets/$name.colorset/Contents.json',
  ).readAsStringSync()) as Map<String, dynamic>;
  final entries = (json['colors'] as List).cast<Map<String, dynamic>>();
  bool isDark(Map<String, dynamic> entry) =>
      ((entry['appearances'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .any((a) => a['appearance'] == 'luminosity' && a['value'] == 'dark');
  final entry = dark
      ? entries.singleWhere(isDark)
      : entries.singleWhere((e) => e['appearances'] == null);
  final color = entry['color'] as Map<String, dynamic>;
  expect(color['color-space'], 'srgb');
  final c = (color['components'] as Map).cast<String, String>();
  int channel(String raw) => raw.startsWith('0x')
      ? int.parse(raw.substring(2), radix: 16)
      : (double.parse(raw) * 255).round();
  expect(double.parse(c['alpha']!), 1.0);
  return 0xFF000000 |
      channel(c['red']!) << 16 |
      channel(c['green']!) << 8 |
      channel(c['blue']!);
}
