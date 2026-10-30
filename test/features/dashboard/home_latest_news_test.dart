import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/domain/dashboard_summary.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/dashboard/presentation/home/home_service_tile.dart';

import 'cv_analysis_home_acceptance_test.dart' show Content, app;

/// The server sends `latest_news` only as a real job, or not at all
/// (Abobker85/Sirati#15). Home renders the same either way.
class _NewsContent extends Content {
  _NewsContent(this.news, {this.omit = false});
  final Object? news;
  final bool omit;

  @override
  Future<Map<String, dynamic>> dashboard(
    bool english, {
    bool force = false,
  }) async =>
      {
        'profile': {'name': 'Mona منى'},
        'stats': {'generated_cvs': 2, 'analyses': 1},
        if (!omit) 'latest_news': news,
      };
}

void main() {
  final shapes = <String, _NewsContent Function()>{
    'omitted': () => _NewsContent(null, omit: true),
    'null': () => _NewsContent(null),
    'a real job': () => _NewsContent({
          'id': 991,
          'title': 'Nurse ممرض',
          'location': null,
          'published_at': '2026-10-29T08:00:00.000000Z',
        }),
  };

  for (final arabic in [true, false]) {
    for (final entry in shapes.entries) {
      testWidgets('home renders with latest_news ${entry.key} (ar=$arabic)',
          (tester) async {
        await tester.pumpWidget(
          app(
            Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
            arabic: arabic,
            dark: false,
            scale: 1,
            content: entry.value(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(HomeServiceTile), findsWidgets);
        expect(find.textContaining('Mona'), findsWidgets);
        // Nothing from the old fixed copy can reach the screen.
        expect(find.textContaining('2 hours ago'), findsNothing);
        expect(find.textContaining('منذ ساعتين'), findsNothing);
      });
    }
  }

  test('a real latest job, or none, parses without invented copy', () {
    final none = DashboardSummary.fromPayload({}, english: true);
    expect(none.hasLatestNews, isFalse);
    final real = DashboardSummary.fromPayload({
      'latest_news': {'id': 4, 'title': 'Welder', 'location': 'Jubail'},
    }, english: true);
    expect(real.latestNewsTitle, 'Welder');
    expect(real.latestNewsSubtitle, isEmpty);
  });
}
