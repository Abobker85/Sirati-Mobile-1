import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ats_grade.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/score_ring.dart';

import '../../support/contrast_probe.dart';
import '../../support/non_text_contrast.dart';

/// One score at each edge of every band, from the band rules themselves.
final _scores = <int>{
  0,
  100,
  for (var s = 1; s <= 100; s++)
    if (ScoreBand.of(s) != ScoreBand.of(s - 1)) ...[s - 1, s],
}.toList()
  ..sort();

class _Content extends MobileContentService {
  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {'title': 'My CVs', 'items': <Map<String, dynamic>>[]};
}

Widget _app({
  required bool dark,
  required bool grouped,
  required Widget child,
}) {
  final scaffold = Scaffold(body: SingleChildScrollView(child: child));
  return MaterialApp(
    theme: dark
        ? AppTheme.darkFor(arabic: true)
        : AppTheme.lightFor(arabic: true),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: grouped ? GroupedSurface(child: scaffold) : scaffold,
  );
}

/// The ring's track and arc, read off the pumped indicator, against every
/// surface actually painted under it.
void _expectRingTrack(WidgetTester tester, String label) {
  final ring = find.byType(ScoreRing);
  expect(ring, findsOneWidget, reason: label);
  final indicator = tester.widget<CircularProgressIndicator>(
      find.descendant(of: ring, matching: find.byType(CircularProgressIndicator)));
  final element = tester.element(
      find.descendant(of: ring, matching: find.byType(CircularProgressIndicator)));
  final track = indicator.backgroundColor!;
  final arc = indicator.color!;

  // Not a warm (beige) grey: blue never falls under red.
  expect(track.b, greaterThanOrEqualTo(track.r),
      reason: '$label track $track is warm');

  final backgrounds = paintedBackgroundsOf(element);
  expect(backgrounds, isNotEmpty, reason: label);
  for (final background in backgrounds) {
    expect(AppContrast.ratio(track, background), greaterThanOrEqualTo(1.3),
        reason: '$label track versus $background');
    expect(AppContrast.ratio(arc, background), greaterThanOrEqualTo(3),
        reason: '$label arc versus $background');
  }
  expect(AppContrast.ratio(arc, track), greaterThanOrEqualTo(3),
      reason: '$label arc versus track');
  // The shared painted-controls gate agrees.
  expectPaintedControlsAa(label);
}

void main() {
  setUp(() => AppLocale.languageCode.value = 'ar');

  for (final dark in [false, true]) {
    for (final grouped in [false, true]) {
      final label =
          '${dark ? 'dark' : 'light'}/${grouped ? 'grouped' : 'plain'}';

      testWidgets('$label: My CVs card ring track is neutral and readable',
          (tester) async {
        for (final score in _scores) {
          await tester.pumpWidget(_app(
            dark: dark,
            grouped: grouped,
            child: CvDocumentCard(
              item: CvListItem.fromJson({
                'id': 1,
                'title': 'سيرة Backend Developer',
                'is_draft': false,
                'score_total': score,
                'updated_label': '2 days ago',
              }),
              onOpen: () {},
              onEdit: () {},
              onDelete: () {},
              onDownload: () {},
              onScan: () {},
            ),
          ));
          await tester.pumpAndSettle();
          _expectRingTrack(tester, '$label my cvs $score');
        }
      });

      testWidgets('$label: Home latest CV ring track is neutral and readable',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        for (final score in _scores) {
          await tester.pumpWidget(ProviderScope(
            key: UniqueKey(),
            overrides: [
              mobileContentServiceProvider.overrideWithValue(_Content()),
              latestDashboardCvProvider(false).overrideWith(
                (ref) async => GeneratedCv.fromJson({
                  'id': 5,
                  'target_job_title': 'محلل بيانات',
                  'generated_markdown': 'خبرة',
                  'score_total': score,
                  'ai_status': 'completed',
                  'created_at': '2026-10-17T12:00:00Z',
                }),
              ),
            ],
            child: _app(
              dark: dark,
              grouped: grouped,
              child: HomeLatestCvSection(onViewAll: () {}),
            ),
          ));
          await tester.pumpAndSettle();
          _expectRingTrack(tester, '$label home $score');
        }
      });
    }
  }
}
