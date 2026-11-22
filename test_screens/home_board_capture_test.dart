// Renders Home with mock data to compare against the approved design board.
// Run: flutter test test_screens/home_board_capture_test.dart
// Output: build/home_board/*.png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_navigation_bar.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';

import '../test/features/dashboard/cv_analysis_home_acceptance_test.dart'
    show Api, Content, app, cv;

const _rootKey = ValueKey('home-board-root');

class _Jobs extends Content {
  _Jobs({super.latest});

  @override
  Future<Map<String, dynamic>> jobNews(
    bool english, {
    String? category,
    String? preset,
    String? city,
    String? region,
    int? jobTitleId,
    bool? isRemote,
    bool? isVerified,
    String? sourceType,
    String? employmentType,
    String? query,
    bool force = false,
  }) async {
    final now = DateTime.now().toUtc();
    return {
      'items': [
        {
          'id': 1,
          'title': 'مطور ويب',
          'company': 'شركة تقنية',
          'location': 'الرياض',
          'published_at':
              now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 2,
          'title': 'أخصائي موارد بشرية',
          'company': 'جهة حكومية',
          'location': 'جدة',
          'published_at':
              now.subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 3,
          'title': 'محاسب',
          'company': 'شركة تجارية',
          'location': 'الدمام',
          'published_at':
              now.subtract(const Duration(days: 1)).toIso8601String(),
        },
      ],
    };
  }
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
  setUpAll(() async {
    await _loadFonts();
    Directory('build/home_board').createSync(recursive: true);
  });
  setUp(() {
    MobileContentService.invalidate();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
  });

  for (final arabic in [true, false]) {
    for (final dark in [false, true]) {
      for (final hasCv in [true, false]) {
        testWidgets('home ar=$arabic dark=$dark cv=$hasCv', (tester) async {
          tester.view.physicalSize = const Size(390, 1900) * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          final latest = hasCv ? cv(72, id: 71) : null;
          await tester.pumpWidget(RepaintBoundary(
            key: _rootKey,
            child: app(
              Scaffold(
                body: DashboardHomeTab(onNavigate: (_) {}),
                bottomNavigationBar: DashboardNavigationBar(
                  current: DashboardTab.home,
                  onChanged: (_) {},
                ),
              ),
              arabic: arabic,
              dark: dark,
              scale: 1,
              latest: latest,
              api: Api(latest: latest),
              content: _Jobs(latest: latest),
            ),
          ));
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          final boundary =
              tester.renderObject<RenderRepaintBoundary>(find.byKey(_rootKey));
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('build/home_board/home-${arabic ? 'ar' : 'en'}-${dark ? 'dark' : 'light'}-${hasCv ? 'cv' : 'empty'}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
          // Let first-launch one-shot timers (intro, greeting) run out.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 30));
        });
      }
    }
  }
}
