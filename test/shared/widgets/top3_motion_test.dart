import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/features/dashboard/presentation/premium_unlocked_mark.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/loading/branded_loader.dart';
import 'package:sirati/shared/widgets/loading/cv_drafting_scene.dart';
import 'package:sirati/shared/widgets/loading/scan_paper_scene.dart';
import 'package:sirati/shared/widgets/sirati_refresh_indicator.dart';

Widget _app(
  Widget home, {
  bool reduce = false,
  TextDirection direction = TextDirection.ltr,
  TargetPlatform platform = TargetPlatform.android,
}) =>
    MaterialApp(
      theme: AppTheme.lightFor(arabic: direction == TextDirection.rtl)
          .copyWith(platform: platform),
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: home,
    );

void main() {
  final haptics = <String>[];
  setUp(() {
    haptics.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add('${call.arguments}');
      }
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('pull to refresh', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets(
          '${platform.name}: the ring fills with the pull, pops once at the '
          'refresh point, sweeps while loading, ends with a tick and goes',
          (tester) async {
        final refresh = Completer<void>();
        var calls = 0;
        await tester.pumpWidget(_app(
          Scaffold(
            body: SiratiRefreshIndicator(
              onRefresh: () {
                calls++;
                return refresh.future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 30; i++) const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          platform: platform,
        ));
        SiratiRefreshIndicatorState s() =>
            tester.state(find.byType(SiratiRefreshIndicator));

        final g = await tester.startGesture(const Offset(400, 200));
        var lastFill = 0.0;
        for (var i = 0; i < 30; i++) {
          await g.moveBy(const Offset(0, 12));
          await tester.pump(const Duration(milliseconds: 16));
          if (s().status == RefreshIndicatorStatus.drag ||
              s().status == RefreshIndicatorStatus.armed) {
            expect(s().fill, greaterThanOrEqualTo(lastFill - 1e-9));
            lastFill = s().fill;
          }
        }
        expect(s().status, RefreshIndicatorStatus.armed);
        expect(lastFill, 1);
        expect(haptics.where((h) => h.contains('selection')), hasLength(1),
            reason: 'one click at the refresh point');
        await g.up();
        // Let go: it snaps into place, then refreshes.
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(s().loading, isTrue);
        expect(calls, 1);
        final painter = tester
            .widget<CustomPaint>(find.byKey(SiratiRefreshIndicator.markKey))
            .painter! as RefreshMarkPainter;
        expect(painter.spinning, isTrue);

        refresh.complete();
        await tester.pump();
        var sawTick = false;
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          final mark = find.byKey(SiratiRefreshIndicator.markKey);
          if (mark.evaluate().isEmpty) break;
          final p =
              tester.widget<CustomPaint>(mark).painter! as RefreshMarkPainter;
          if (p.tick > 0) sawTick = true;
        }
        expect(sawTick, isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(SiratiRefreshIndicator.markKey), findsNothing);
      });
    }

    testWidgets('a short pull that is let go early refreshes nothing',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(_app(Scaffold(
        body: SiratiRefreshIndicator(
          onRefresh: () async => calls++,
          child: ListView(children: [
            for (var i = 0; i < 30; i++) const SizedBox(height: 60),
          ]),
        ),
      )));
      final g = await tester.startGesture(const Offset(400, 200));
      await g.moveBy(const Offset(0, 20));
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byKey(SiratiRefreshIndicator.markKey), findsNothing);
    });

    testWidgets('the sweep never outlasts its cap', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: SiratiRefreshIndicator(
          onRefresh: () => Completer<void>().future, // never ends
          child: ListView(children: [
            for (var i = 0; i < 30; i++) const SizedBox(height: 60),
          ]),
        ),
      )));
      final g = await tester.startGesture(const Offset(400, 200));
      for (var i = 0; i < 30; i++) {
        await g.moveBy(const Offset(0, 12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
          (tester
                  .widget<CustomPaint>(
                      find.byKey(SiratiRefreshIndicator.markKey))
                  .painter! as RefreshMarkPainter)
              .spinning,
          isTrue);
      await tester.pump(SiratiRefreshIndicator.maxSpin);
      await tester.pump(const Duration(seconds: 1));
      final painter = tester
          .widget<CustomPaint>(find.byKey(SiratiRefreshIndicator.markKey))
          .painter! as RefreshMarkPainter;
      final turn = painter.turn;
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          (tester
                  .widget<CustomPaint>(
                      find.byKey(SiratiRefreshIndicator.markKey))
                  .painter! as RefreshMarkPainter)
              .turn,
          turn,
          reason: 'the sweep has stopped');
    });
  });

  group('plan selection halo', () {
    Widget plans(int selected, {bool reduce = false}) => _app(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: PlanSelectionHalo(
                selected: selected,
                children: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(key: ValueKey('plan-$i'), height: 80),
                ],
              ),
            ),
          ),
          reduce: reduce,
        );
    Rect halo(WidgetTester tester) => tester
        .state<PlanSelectionHaloState>(find.byType(PlanSelectionHalo))
        .paintedHalo!;
    Rect card(WidgetTester tester, int i) =>
        tester.getRect(find.byKey(ValueKey('plan-$i')));

    testWidgets('it rests around the chosen card and slides between them',
        (tester) async {
      await tester.pumpWidget(plans(0));
      await tester.pump();
      for (final (from, to) in [(0, 2), (2, 1), (1, 0)]) {
        await tester.pumpWidget(plans(from));
        await tester.pumpAndSettle();
        expect(
            halo(tester), card(tester, from).inflate(PlanSelectionHalo.outset));
        await tester.pumpWidget(plans(to));
        await tester.pump(const Duration(milliseconds: 140));
        final mid = halo(tester).center.dy;
        final a = card(tester, from).center.dy;
        final b = card(tester, to).center.dy;
        expect(mid, greaterThan(a < b ? a : b));
        expect(mid, lessThan(a < b ? b : a));
        await tester.pumpAndSettle();
        expect(
            halo(tester), card(tester, to).inflate(PlanSelectionHalo.outset));
      }
    });

    testWidgets('reduced motion moves it at once', (tester) async {
      await tester.pumpWidget(plans(0, reduce: true));
      await tester.pump();
      await tester.pumpWidget(plans(2, reduce: true));
      await tester.pump();
      expect(halo(tester), card(tester, 2).inflate(PlanSelectionHalo.outset));
    });
  });

  group('Premium unlocked', () {
    Finder icon(IconData i) => find.byIcon(i);

    testWidgets(
        'the lock opens, the crown stamps in with one haptic, sparkles fly '
        'and are gone', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PremiumUnlockedMark(confirmed: true)))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(icon(Icons.lock_rounded), findsOneWidget);
      var sawSparkles = false;
      var hapticAt = -1.0;
      for (var f = 0; f < 120; f++) {
        final before = haptics.length;
        await tester.pump(const Duration(milliseconds: 16));
        final p = tester
            .state<PremiumUnlockedMarkState>(find.byType(PremiumUnlockedMark))
            .progress;
        if (haptics.length > before) hapticAt = p;
        if (find.byKey(PremiumUnlockedMark.sparklesKey).evaluate().isNotEmpty) {
          sawSparkles = true;
        }
      }
      await tester.pumpAndSettle();
      expect(icon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(icon(Icons.lock_rounded), findsNothing);
      expect(icon(Icons.lock_open_rounded), findsNothing);
      expect(haptics, hasLength(1));
      expect(hapticAt, greaterThanOrEqualTo(PremiumUnlockedMark.stampAt));
      expect(sawSparkles, isTrue);
      expect(find.byKey(PremiumUnlockedMark.sparklesKey), findsNothing);
    });

    testWidgets('paid but not confirmed: an hourglass, no celebration',
        (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PremiumUnlockedMark(confirmed: false)))));
      await tester.pumpAndSettle();
      expect(icon(Icons.hourglass_top_rounded), findsOneWidget);
      expect(icon(Icons.workspace_premium_rounded), findsNothing);
      expect(haptics, isEmpty);

      // Confirmed later ("Check again"): now it celebrates.
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PremiumUnlockedMark(confirmed: true)))));
      await tester.pumpAndSettle();
      expect(icon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(haptics, hasLength(1));
    });

    testWidgets('the second time it is quicker', (tester) async {
      final lengths = <int>[];
      for (var i = 0; i < 2; i++) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_app(Scaffold(
            body: Center(
                child:
                    PremiumUnlockedMark(key: ValueKey(i), confirmed: true)))));
        await tester.pump();
        var frames = 0;
        PremiumUnlockedMarkState s() =>
            tester.state(find.byType(PremiumUnlockedMark));
        await tester.pump(const Duration(milliseconds: 10));
        while (s().progress < 1 && frames < 400) {
          await tester.pump(const Duration(milliseconds: 10));
          frames++;
        }
        lengths.add(frames * 10);
      }
      expect(
          lengths[0], closeTo(PremiumUnlockedMark.duration.inMilliseconds, 40));
      expect(lengths[1],
          closeTo(PremiumUnlockedMark.quickDuration.inMilliseconds, 40));
    });

    testWidgets('reduced motion: the crown at once, one haptic',
        (tester) async {
      await tester.pumpWidget(_app(
          const Scaffold(
              body: Center(child: PremiumUnlockedMark(confirmed: true))),
          reduce: true));
      await tester.pump();
      expect(icon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.byKey(PremiumUnlockedMark.sparklesKey), findsNothing);
      await tester.pumpAndSettle();
      expect(haptics, hasLength(1));
    });
  });

  group('scan scene', () {
    ScanPaperPainter painter(WidgetTester tester) =>
        tester.widget<CustomPaint>(find.byKey(ScanPaperScene.paintKey)).painter!
            as ScanPaperPainter;

    Widget scene(ScanStage stage, {TextDirection d = TextDirection.ltr}) =>
        _app(Scaffold(body: Center(child: ScanPaperScene(stage: stage))),
            direction: d);

    testWidgets('the beam sweeps top to bottom over the paper each pass',
        (tester) async {
      await tester.pumpWidget(scene(ScanStage.reading));
      const size = ScanPaperScene.size;
      final paper = ScanPaperPainter.paperRect(size);
      final ys = <double>[];
      for (var f = 0; f < 10; f++) {
        await tester.pump(ScanPaperScene.pass ~/ 12);
        ys.add(painter(tester).beamY(size)!);
      }
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]));
      }
      for (final y in ys) {
        expect(y, inInclusiveRange(paper.top, paper.bottom));
      }
    });

    testWidgets(
        'stages blend: chips while scoring, the ring when preparing, '
        'closed ring and no beam when done', (tester) async {
      await tester.pumpWidget(scene(ScanStage.reading));
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter(tester).scoring, 0);
      await tester.pumpWidget(scene(ScanStage.scoring));
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter(tester).scoring, inExclusiveRange(0, 1),
          reason: 'fading in, not snapping');
      await tester.pump(const Duration(milliseconds: 400));
      expect(painter(tester).scoring, 1);
      await tester.pumpWidget(scene(ScanStage.preparing));
      await tester.pump(const Duration(milliseconds: 600));
      expect(painter(tester).preparing, 1);
      expect(painter(tester).scoring, 0);
      await tester.pumpWidget(scene(ScanStage.done));
      await tester.pumpAndSettle();
      expect(painter(tester).done, 1);
      expect(painter(tester).beamY(ScanPaperScene.size), isNull);
      expect(
          tester
              .state<ScanPaperSceneState>(find.byType(ScanPaperScene))
              .scanning,
          isFalse);
    });

    for (final d in TextDirection.values) {
      testWidgets('$d: the ring waits on the trailing side of the paper',
          (tester) async {
        final paper = ScanPaperPainter.paperRect(ScanPaperScene.size);
        final ring = ScanPaperPainter.ringCenter(ScanPaperScene.size,
            rtl: d == TextDirection.rtl);
        if (d == TextDirection.rtl) {
          expect(ring.dx, lessThan(paper.center.dx));
        } else {
          expect(ring.dx, greaterThan(paper.center.dx));
        }
      });
    }

    testWidgets('the beam never runs past its cap', (tester) async {
      await tester.pumpWidget(scene(ScanStage.reading));
      await tester.pump(ScanPaperScene.maxScan);
      await tester.pump(ScanPaperScene.pass);
      expect(
          tester
              .state<ScanPaperSceneState>(find.byType(ScanPaperScene))
              .scanning,
          isFalse);
    });

    for (final (kind, reduce) in [
      (AiProgressKind.analysis, false),
      (AiProgressKind.analysis, true),
      (AiProgressKind.generation, false),
      (AiProgressKind.generation, true),
    ]) {
      final showScan = !reduce && kind == AiProgressKind.analysis;
      final showDraft = !reduce && kind == AiProgressKind.generation;
      final showLoader = reduce;
      testWidgets(
          'overlay: ${kind.name}${reduce ? ' (reduced motion)' : ''} shows '
          '${showScan ? 'the scan scene' : showDraft ? 'the drafting scene' : 'the loader'}',
          (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_app(
          Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
          reduce: reduce,
        ));
        unawaited(AiProgressOverlay.show(ctx, kind: kind, english: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(ScanPaperScene),
            showScan ? findsOneWidget : findsNothing);
        expect(find.byType(CvDraftingScene),
            showDraft ? findsOneWidget : findsNothing);
        expect(find.byType(BrandedLoader),
            showLoader ? findsOneWidget : findsNothing);
        // Closing the app disposes the overlay and its timers.
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
