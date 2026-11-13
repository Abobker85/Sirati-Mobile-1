// Scratch preview: renders the My CVs tab with sample data to build/cv_tab.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Content extends MobileContentService {
  _Content(this.items);
  final List<Map<String, dynamic>> items;

  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {'title': english ? 'My CVs' : 'سيرتي', 'items': items};
}

List<Map<String, dynamic>> _sample(bool english) {
  final now = DateTime.now();
  Map<String, dynamic> cv(int id, String title, int? score, int daysAgo) => {
        'id': id,
        'title': title,
        'score_total': score,
        'can_download': true,
        'pdf_url': 'https://example.test/$id.pdf',
        'updated_at':
            now.subtract(Duration(days: daysAgo)).toUtc().toIso8601String(),
      };
  return english
      ? [
          cv(1, 'Senior Software Engineer', 86, 0),
          cv(2, 'Project Manager', 52, 3),
          cv(3, 'Data Analyst', null, 9),
        ]
      : [
          cv(1, 'مهندس برمجيات أول', 86, 0),
          cv(2, 'مدير مشاريع', 52, 3),
          cv(3, 'محلل بيانات', null, 9),
        ];
}

Future<void> _loadFonts() async {
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json'))
      as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  const rootKey = Key('root');
  setUpAll(_loadFonts);

  for (final (name, language, dark, empty) in [
    ('ar-light', 'ar', false, false),
    ('ar-dark', 'ar', true, false),
    ('ar-empty', 'ar', false, true),
    ('en-light', 'en', false, false),
  ]) {
    testWidgets('capture $name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppLocale.languageCode.value = language;
      tester.view.physicalSize = const Size(390 * 2, 1240 * 2);
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 47 * 2);
      addTearDown(tester.view.reset);
      final arabic = language == 'ar';
      final english = !arabic;
      await tester.pumpWidget(RepaintBoundary(
        key: rootKey,
        child: ProviderScope(
          overrides: [
            mobileContentServiceProvider.overrideWithValue(
                _Content(empty ? const [] : _sample(english))),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark
                ? AppTheme.darkFor(arabic: arabic)
                : AppTheme.lightFor(arabic: arabic),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: MyCvsScreen()),
          ),
        ),
      ));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(rootKey));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/cv_tab').createSync(recursive: true);
        File('build/cv_tab/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
