import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final text = FontLoader('IBM Plex Sans Arabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await icons.load();
  });

  // Keep font registration isolated from the other golden baselines.
  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      final tag = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}';
      testWidgets('submit button states $tag', (tester) async {
        await tester.binding.setSurfaceSize(goldenSurfaceSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(goldenShell(
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          english: !rtl,
          child: SingleChildScrollView(
            child: GoldenSubmitButtonStates(english: !rtl),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 50));
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/submit_button_states_$tag.png'));
      }, tags: ['golden']);
    }
  }
}
