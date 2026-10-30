import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ats_grade.dart';
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

Map<String, dynamic> _cv(int id, {int? score, String? title}) => {
      'id': id,
      'title': title ?? 'CV $id',
      'score_total': score,
      'can_download': true,
      'pdf_url': 'https://example.test/$id.pdf',
      'template_pdf_url': 'https://example.test/$id.pdf',
    };

void main() {
  late List<RouteSettings> pushed;

  setUp(() {
    pushed = [];
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(
    WidgetTester tester,
    List<Map<String, dynamic>> items, {
    String language = 'ar',
    bool dark = false,
  }) async {
    AppLocale.languageCode.value = language;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final arabic = language == 'ar';
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mobileContentServiceProvider.overrideWithValue(_Content(items)),
      ],
      child: MaterialApp(
        theme: dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic),
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: MyCvsScreen()),
        onGenerateRoute: (settings) {
          pushed.add(settings);
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('pushed')),
          );
        },
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapAndReturn(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
  }

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      final variant = '$language/${dark ? 'dark' : 'light'}';

      testWidgets('$variant: no CVs shows the empty card under the tools',
          (tester) async {
        await pump(tester, const [], language: language, dark: dark);
        expect(find.byType(MyCvsToolsCard), findsOneWidget);
        expect(find.byType(MyCvsEmptyCard), findsOneWidget);
        expect(find.byType(CvDocumentCard), findsNothing);
        // The empty card sits below the tools card.
        expect(
          tester.getTopLeft(find.byType(MyCvsEmptyCard)).dy,
          greaterThan(tester.getBottomLeft(find.byType(MyCvsToolsCard)).dy),
        );

        await tapAndReturn(tester, find.byKey(MyCvsEmptyCard.uploadKey));
        final args = pushed.single.arguments as AtsScanArgs;
        expect(pushed.single.name, AppRoutes.atsScan);
        expect(args.upload, isTrue);
        expect(args.cvId, isNull);
      });

      testWidgets('$variant: each tool opens its own destination',
          (tester) async {
        await pump(tester, [_cv(3, score: 80)], language: language, dark: dark);

        await tapAndReturn(tester, find.byKey(MyCvsToolsCard.scanKey));
        await tapAndReturn(tester, find.byKey(MyCvsToolsCard.uploadKey));
        await tapAndReturn(tester, find.byKey(MyCvsToolsCard.targetKey));

        expect(pushed.map((s) => s.name), [
          AppRoutes.atsScan,
          AppRoutes.atsScan,
          AppRoutes.jobMatch,
        ]);
        final scan = pushed[0].arguments as AtsScanArgs;
        final upload = pushed[1].arguments as AtsScanArgs;
        expect((scan.upload, scan.cvId), (false, null));
        expect((upload.upload, upload.cvId), (true, null));
      });
    }
  }

  testWidgets('every row opens its own CV; unscored rows scan that CV',
      (tester) async {
    final ids = [11, 4, 907];
    final scores = <int?>[null, 37, 100];
    await pump(tester, [
      for (var i = 0; i < ids.length; i++) _cv(ids[i], score: scores[i]),
    ]);
    final l = AppLocalizations.of(tester.element(find.byType(MyCvsScreen)));

    expect(find.byType(MyCvsEmptyCard), findsNothing);

    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      final score = scores[i];
      pushed.clear();
      await tapAndReturn(tester, find.byKey(CvDocumentCard.openKey(id)));
      expect(pushed.single.name, AppRoutes.cv(id));

      final card = find.ancestor(
        of: find.byKey(CvDocumentCard.openKey(id)),
        matching: find.byType(CvDocumentCard),
      );
      final scan = find.byKey(CvDocumentCard.scanKey(id));
      if (score == null) {
        pushed.clear();
        await tapAndReturn(tester, scan);
        expect(pushed.single.name, AppRoutes.atsScan);
        expect((pushed.single.arguments as AtsScanArgs).cvId, id);
        expect(
          find.descendant(of: card, matching: find.text(l.cvCardNotScanned)),
          findsOneWidget,
        );
      } else {
        expect(scan, findsNothing);
        expect(
          find.descendant(of: card, matching: find.text(l.cvCardScore(score))),
          findsOneWidget,
        );
      }
      // Only a weak-band score carries the warning.
      expect(
        find.descendant(of: card, matching: find.text(l.cvCardNeedsWork)),
        score != null && ScoreBand.of(score) == ScoreBand.weak
            ? findsOneWidget
            : findsNothing,
      );
    }
  });

  group('score_total parsing', () {
    test('every in-range score survives as an int', () {
      for (var score = 0; score <= 100; score++) {
        for (final raw in <Object>[
          score,
          score.toDouble(),
          '$score',
          ' $score '
        ]) {
          expect(CvListItem.fromJson({'id': 1, 'score_total': raw}).scoreTotal,
              score,
              reason: 'raw: ${raw.runtimeType} $raw');
        }
      }
    });

    test('missing, malformed or out-of-range scores mean "not scanned"', () {
      for (final raw in <Object?>[
        null,
        '',
        'abc',
        -1,
        101,
        1e9,
        -0.6,
        '200',
        true,
        const []
      ]) {
        expect(CvListItem.fromJson({'id': 1, 'score_total': raw}).scoreTotal,
            isNull,
            reason: 'raw: $raw');
      }
    });
  });
}
