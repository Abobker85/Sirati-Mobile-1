import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/routing/expand_page_route.dart';
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
    double textScale = 1,
    bool reduceMotion = false,
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
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

  for (final language in ['ar', 'en']) {
    testWidgets('$language: opening a CV expands from that row\'s card',
        (tester) async {
      final ids = [11, 4, 907];
      await pump(
        tester,
        [for (final id in ids) _cv(id, score: id == 4 ? 37 : null)],
        language: language,
      );

      for (final id in ids) {
        final open = find.byKey(CvDocumentCard.openKey(id));
        await tester.ensureVisible(open);
        await tester.pumpAndSettle();
        final card = tester.getRect(find.ancestor(
          of: open,
          matching: find.byType(CvDocumentCard),
        ));

        pushed.clear();
        await tapAndReturn(tester, open);

        final from = pushed.single.arguments as ExpandFrom;
        expect(from.origin.rect, card);
        expect(from.arguments, isNull);
      }
    });
  }

  group('slim header', () {
    final slim = find.byType(MyCvsSlimHeader);
    final bandBell = find.byKey(MyCvsHeader.bellKey);
    final slimBell = find.byKey(MyCvsSlimHeader.bellKey);
    final list = find.byType(ListView);
    final many = [for (var i = 1; i <= 12; i++) _cv(i, score: i * 8)];

    /// At any resting scroll position there is exactly one bell to tap: the
    /// band's while it is fully on screen, the slim header's once it is not.
    void expectOneReachableBell(WidgetTester tester) {
      final bandBellOnScreen = bandBell.evaluate().isNotEmpty &&
          tester.getRect(bandBell).top >= 0;
      expect(slim.evaluate().isNotEmpty, !bandBellOnScreen);
      if (bandBellOnScreen) {
        expect(bandBell.hitTestable(), findsOneWidget);
        expect(slimBell, findsNothing);
      } else {
        expect(slimBell.hitTestable(), findsOneWidget);
        expect(bandBell.hitTestable(), findsNothing);
        final bar = tester.getRect(slim);
        expect(bar.top, 0);
        expect(bar.width, tester.getSize(find.byType(MyCvsScreen)).width);
      }
    }

    for (final language in ['ar', 'en']) {
      for (final textScale in [1.0, 1.6]) {
        for (final reduceMotion in [false, true]) {
          testWidgets(
              '$language x$textScale${reduceMotion ? ' reduced' : ''}: one '
              'bell is reachable at every scroll position', (tester) async {
            await pump(tester, many,
                language: language,
                textScale: textScale,
                reduceMotion: reduceMotion);
            expect(slim, findsNothing);
            expectOneReachableBell(tester);

            // Down in uneven steps (small ones around the switch), then
            // back to the top.
            for (final dy in <double>[
              -6, -9, -2, -1, -30, -120, -400, -900, 300, 700, 250, 30, 9, 4, //
              2000,
            ]) {
              await tester.drag(list, Offset(0, dy));
              await tester.pumpAndSettle();
              expectOneReachableBell(tester);
            }
            expect(slim, findsNothing);
          });
        }
      }
    }

    testWidgets('its bell opens notifications and its title is the page title',
        (tester) async {
      await pump(tester, many);
      final title = tester
          .widget<Text>(find
              .descendant(
                of: find.byType(MyCvsHeader),
                matching: find.byType(Text),
              )
              .first)
          .data!;
      await tester.drag(list, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: slim, matching: find.text(title)),
        findsOneWidget,
      );
      pushed.clear();
      await tapAndReturn(tester, slimBell);
      expect(pushed.single.name, AppRoutes.notifications);
    });

    testWidgets('reduced motion: it is in place on the first frame',
        (tester) async {
      await pump(tester, many, reduceMotion: true);
      await tester.drag(list, const Offset(0, -300));
      await tester.pump();
      expect(tester.getRect(slim).top, 0);
    });

    testWidgets('a list too short to scroll never shows it', (tester) async {
      await pump(tester, const []);
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expectOneReachableBell(tester);
    });
  });

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
