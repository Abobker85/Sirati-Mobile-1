import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/success_beat.dart';

Widget _app(
  Widget child, {
  bool reduce = false,
  TextDirection direction = TextDirection.ltr,
}) =>
    MaterialApp(
      theme: AppTheme.lightFor(arabic: direction == TextDirection.rtl),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

const _scoreColor = Color(0xFF0E7A4F);

int _shownNumber(WidgetTester tester) => int.parse(tester
    .widgetList<Text>(find.descendant(
        of: find.byType(AnimatedScoreRing), matching: find.byType(Text)))
    .first
    .data!);

ScoreRingPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(AnimatedScoreRing.ringKey)).painter!
        as ScoreRingPainter;

AnimatedScoreRingState _ring(WidgetTester tester) =>
    tester.state(find.byType(AnimatedScoreRing));

void main() {
  group('ATS score reveal', () {
    final haptics = <String>[];
    setUp(() {
      haptics.clear();
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

    for (final score in [0, 1, 37, 59, 60, 86, 99, 100]) {
      testWidgets(
          '$score: counts up without overshooting, lands once, ends exactly',
          (tester) async {
        await tester.pumpWidget(_app(AnimatedScoreRing(
            score: score, scoreColor: _scoreColor, reveal: true)));
        var previous = -1;
        var landedAt = -1;
        const step = Duration(milliseconds: 20);
        final frames = AnimatedScoreRing.duration.inMilliseconds ~/ 20 + 5;
        for (var f = 0; f < frames; f++) {
          await tester.pump(step);
          final n = _shownNumber(tester);
          expect(n, inInclusiveRange(previous, score), reason: 'frame $f');
          previous = n;
          final r = _ring(tester);
          // The landing only starts once the climb has finished.
          if (r.land > 0) {
            expect(r.climb, 1);
            if (landedAt < 0) landedAt = f;
          }
          // The glowing head is exactly on the end of the arc.
          final p = _painter(tester);
          final size = tester.getSize(find.byKey(AnimatedScoreRing.ringKey));
          if (p.head && p.value > 0) {
            expect(
              (Canvas canvas) => p.paint(canvas, size),
              paints
                ..circle()
                ..arc()
                ..circle()
                ..circle(
                  x: ScoreRingPainter.endOf(size, p.value).dx,
                  y: ScoreRingPainter.endOf(size, p.value).dy,
                ),
              reason: 'frame $f',
            );
          }
        }
        await tester.pumpAndSettle();
        expect(landedAt, greaterThan(0));
        expect(_shownNumber(tester), score);
        expect(_painter(tester).value, score / 100);
        expect(_painter(tester).color, _scoreColor);
        expect(_painter(tester).head, isFalse);
        expect(_painter(tester).land, 0, reason: 'nothing left painted');
        expect(
          haptics.where((h) => h.endsWith('lightImpact')),
          hasLength(1),
          reason: 'one tap as it lands',
        );
        expect(
          haptics.where((h) => h.endsWith('selectionClick')),
          hasLength(AnimatedScoreRing.crossingsTo(score).length),
          reason: 'one tick per band boundary passed',
        );
      });
    }

    testWidgets(
        'a ring without reveal (any new screen) shows its score '
        'at once', (tester) async {
      await tester.pumpWidget(
          _app(const AnimatedScoreRing(score: 77, scoreColor: _scoreColor)));
      expect(_shownNumber(tester), 77);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('on a page sliding in, the climb waits for the page to settle',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      unawaited(Navigator.of(ctx).push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: Center(
            child: AnimatedScoreRing(
                score: 80, scoreColor: _scoreColor, reveal: true),
          ),
        ),
      )));
      await tester.pump();
      await tester.pump();
      final route =
          ModalRoute.of(tester.element(find.byType(AnimatedScoreRing)))!;
      var frames = 0;
      while (!route.animation!.isCompleted) {
        expect(_ring(tester).climb, 0, reason: 'climbing under the page');
        await tester.pump(const Duration(milliseconds: 16));
        if (++frames > 100) fail('the page never settled');
      }
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_ring(tester).climb, greaterThan(0));
      expect(_ring(tester).climb, lessThan(.3), reason: 'seen from the start');
      await tester.pumpAndSettle();
      expect(_shownNumber(tester), 80);
    });

    testWidgets('it warms from grey into the score colour, never from red',
        (tester) async {
      await tester.pumpWidget(_app(const AnimatedScoreRing(
          score: 92, scoreColor: _scoreColor, reveal: true)));
      final c = tester.element(find.byType(AnimatedScoreRing)).sirati;
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      final early = _painter(tester).color;
      expect(
        (early.r - c.borderStrong.r).abs() +
            (early.g - c.borderStrong.g).abs() +
            (early.b - c.borderStrong.b).abs(),
        lessThan((early.r - c.error.r).abs() +
            (early.g - c.error.g).abs() +
            (early.b - c.error.b).abs()),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('a new score replays and lands on the new value',
        (tester) async {
      await tester.pumpWidget(_app(const AnimatedScoreRing(
          score: 40, scoreColor: _scoreColor, reveal: true)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const AnimatedScoreRing(
          score: 90, scoreColor: _scoreColor, reveal: true)));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_shownNumber(tester), lessThan(90));
      await tester.pumpAndSettle();
      expect(_shownNumber(tester), 90);
    });

    for (final (name, reduce, reveal) in [
      ('reduced motion', true, true),
      ('a saved result', false, false),
    ]) {
      testWidgets('$name: the final score on the first frame, no tap',
          (tester) async {
        for (final score in [0, 45, 100]) {
          await tester.pumpWidget(_app(
              AnimatedScoreRing(
                key: ValueKey(score),
                score: score,
                scoreColor: _scoreColor,
                reveal: reveal,
              ),
              reduce: reduce));
          expect(_shownNumber(tester), score);
          expect(_painter(tester).value, score / 100);
          expect(_painter(tester).head, isFalse);
          expect(tester.hasRunningAnimations, isFalse);
        }
        await tester.pumpAndSettle();
        expect(haptics, isEmpty);
      });
    }
  });

  group('CV created scene', () {
    // Haptic impacts the phone was asked for, with the scene progress at
    // that moment (null when no scene was showing).
    final haptics = <double?>[];
    double? sceneProgress(WidgetTester tester) {
      final scene = find.byType(CvCreatedScene);
      if (scene.evaluate().isEmpty) return null;
      return tester.widget<CvCreatedScene>(scene).progress;
    }

    late WidgetTester current;
    setUp(() {
      haptics.clear();
      SharedPreferences.setMockInitialValues({});
      // Answer the haptic call the way a phone does, and record it.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(sceneProgress(current));
        }
        return null;
      });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final ticks = [for (var i = 0; i <= 100; i++) i / 100];

    test('lines are written one after another, each fully', () {
      for (final p in ticks) {
        for (var i = 1; i < CvCreatedScene.lineCount; i++) {
          if (CvCreatedScene.lineWritten(p, i) > 0) {
            expect(CvCreatedScene.lineWritten(p, i - 1), 1,
                reason: 'line $i started before line ${i - 1} ended at $p');
          }
        }
      }
      for (var i = 0; i < CvCreatedScene.lineCount; i++) {
        expect(CvCreatedScene.lineWritten(0, i), 0);
        expect(CvCreatedScene.lineWritten(1, i), 1);
      }
    });

    for (final direction in TextDirection.values) {
      testWidgets('lines grow from the reading start edge ($direction)',
          (tester) async {
        for (final p in [.25, .35, .45, .6]) {
          await tester.pumpWidget(_app(
              SizedBox.square(
                  dimension: 260, child: CvCreatedScene(progress: p)),
              direction: direction));
          for (var i = 0; i < CvCreatedScene.lineCount; i++) {
            final line = find.byKey(CvCreatedScene.lineKey(i));
            if (CvCreatedScene.lineWritten(p, i) == 0) continue;
            final r = tester.getRect(line);
            final parent = tester.getRect(
                find.ancestor(of: line, matching: find.byType(Align)).first);
            if (direction == TextDirection.rtl) {
              expect(r.right, closeTo(parent.right, .5), reason: 'p=$p $i');
            } else {
              expect(r.left, closeTo(parent.left, .5), reason: 'p=$p $i');
            }
          }
        }
      });
    }

    testWidgets('the stamp lands at its own size and stays there',
        (tester) async {
      double scale(double p) {
        return tester
            .widget<Transform>(find.byKey(CvCreatedScene.stampKey))
            .transform
            .entry(0, 0);
      }

      for (final p in [.7, .8, .9, 1.0]) {
        await tester.pumpWidget(_app(CvCreatedScene(progress: p)));
        expect(scale(p), closeTo(1, .001), reason: 'p=$p');
      }
      await tester.pumpWidget(_app(const CvCreatedScene(progress: .5)));
      expect(scale(.5), greaterThan(1), reason: 'still dropping in');
    });

    Future<BuildContext> host(WidgetTester tester,
        {bool reduce = false}) async {
      current = tester;
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }), reduce: reduce));
      return ctx;
    }

    Future<void> openScene(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(CvCreatedScene), findsOneWidget);
    }

    testWidgets('one buzz, when the stamp lands, never before', (tester) async {
      final ctx = await host(tester);
      unawaited(SuccessBeat.play(ctx));
      await openScene(tester);
      // Frame by frame: the buzz arrives in the first frame at or past the
      // stamp, and in no frame before it.
      while (find.byType(CvCreatedScene).evaluate().isNotEmpty) {
        final before = haptics.length;
        await tester.pump(const Duration(milliseconds: 16));
        final p = sceneProgress(tester);
        if (p == null) break;
        if (p < SuccessBeat.stampAt) {
          expect(haptics, isEmpty, reason: 'buzz before the stamp at $p');
        } else if (before == 0) {
          expect(haptics, hasLength(1), reason: 'buzz late at $p');
        }
      }
      await tester.pumpAndSettle();
      expect(haptics, hasLength(1));
    });

    testWidgets('confetti stays inside the scene at every moment',
        (tester) async {
      for (var i = 0; i <= 50; i++) {
        final p = i / 50;
        await tester.pumpWidget(_app(SizedBox.square(
            dimension: 260, child: CvCreatedScene(progress: p))));
        final box = tester.getRect(find.byKey(CvCreatedScene.confettiKey));
        final painter = tester
            .widget<CustomPaint>(find.byKey(CvCreatedScene.confettiKey))
            .painter!;
        final bounds = <Rect>[];
        painter.paint(_BoundsCanvas(bounds), box.size);
        for (final b in bounds) {
          expect(
              (Offset.zero & box.size).inflate(.5).contains(b.center), isTrue,
              reason: 'piece at ${b.center} leaves the box at p=$p');
        }
      }
    });

    testWidgets('the barrier is read as "dismiss", the success only once',
        (tester) async {
      final ctx = await host(tester);
      unawaited(SuccessBeat.play(ctx));
      await openScene(tester);
      final barrier =
          tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
      expect(barrier.semanticsLabel,
          MaterialLocalizations.of(ctx).modalBarrierDismissLabel);
      expect(barrier.semanticsLabel, isNot(AppLocalizations.of(ctx).cvSaved));
      await tester.pumpAndSettle();
    });

    testWidgets('saving an edit: one buzz, no scene, no play counted',
        (tester) async {
      final ctx = await host(tester);
      var done = false;
      unawaited(SuccessBeat.celebrate(ctx).then((_) => done = true));
      await tester.pump();
      expect(find.byType(CvCreatedScene), findsNothing);
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(haptics, hasLength(1));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('success_beat.plays'), isNull);
    });

    testWidgets('a tap skips the scene and returns at once', (tester) async {
      final ctx = await host(tester);
      var done = false;
      unawaited(SuccessBeat.play(ctx).then((_) => done = true));
      await openScene(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CvCreatedScene), findsNothing);
      expect(done, isTrue);
    });

    testWidgets('a page opened on top during the scene stays open',
        (tester) async {
      final ctx = await host(tester);
      var done = false;
      unawaited(SuccessBeat.play(ctx).then((_) => done = true));
      await openScene(tester);
      unawaited(Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('on top')))));
      await tester.pumpAndSettle();
      expect(find.text('on top'), findsOneWidget);
      expect(find.byType(CvCreatedScene), findsNothing);
      expect(done, isTrue);
      // Going back lands on the page under it, not on a stale overlay.
      Navigator.of(ctx).pop();
      await tester.pumpAndSettle();
      expect(find.text('on top'), findsNothing);
      expect(find.byType(CvCreatedScene), findsNothing);
    });

    testWidgets('screen readers hear that the CV was saved', (tester) async {
      final ctx = await host(tester);
      final l10n = AppLocalizations.of(ctx);
      final said = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility,
              (message) async {
        final data = (message as Map)['data'] as Map?;
        if (data?['message'] case final String text) said.add(text);
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility, null));
      unawaited(SuccessBeat.play(ctx));
      await openScene(tester);
      await tester.pumpAndSettle();
      expect(said, [l10n.cvSaved]);
    });

    testWidgets('after a few plays the scene gets quicker, never longer',
        (tester) async {
      final ctx = await host(tester);
      final lengths = <int>[];
      for (var i = 0; i < SuccessBeat.fullPlays + 2; i++) {
        unawaited(SuccessBeat.play(ctx));
        await openScene(tester);
        var frames = 0;
        while (find.byType(CvCreatedScene).evaluate().isNotEmpty) {
          await tester.pump(const Duration(milliseconds: 10));
          frames++;
        }
        lengths.add(frames * 10);
      }
      for (var i = 0; i < lengths.length; i++) {
        final expected = i < SuccessBeat.fullPlays
            ? SuccessBeat.sceneDuration
            : SuccessBeat.quickSceneDuration;
        expect(lengths[i], closeTo(expected.inMilliseconds, 40),
            reason: 'play $i');
      }
      expect(haptics, hasLength(lengths.length), reason: 'one buzz each');
    });

    testWidgets('the overlay plays once, closes itself and returns',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      var done = false;
      unawaited(SuccessBeat.play(ctx).then((_) => done = true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(CvCreatedScene), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CvCreatedScene), findsNothing);
      expect(done, isTrue);
    });

    testWidgets('reduced motion: no scene at all', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }), reduce: true));
      var done = false;
      unawaited(SuccessBeat.play(ctx).then((_) => done = true));
      await tester.pump();
      expect(find.byType(CvCreatedScene), findsNothing);
      await tester.pumpAndSettle();
      expect(done, isTrue);
    });
  });
}

/// Records where each piece of confetti is drawn (centre of its transform).
class _BoundsCanvas implements Canvas {
  _BoundsCanvas(this.bounds);

  final List<Rect> bounds;
  final _stack = <Matrix4>[Matrix4.identity()];

  @override
  void save() => _stack.add(_stack.last.clone());

  @override
  void restore() => _stack.removeLast();

  @override
  void translate(double dx, double dy) =>
      _stack.last.translateByDouble(dx, dy, 0, 1);

  @override
  void rotate(double radians) => _stack.last.rotateZ(radians);

  @override
  void drawRRect(RRect rrect, Paint paint) {
    final c = MatrixUtils.transformPoint(_stack.last, rrect.center);
    bounds.add(Rect.fromCenter(center: c, width: 0, height: 0));
  }

  // The confetti painter only uses the calls above.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
