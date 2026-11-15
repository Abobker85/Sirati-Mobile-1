import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/motion.dart';

const _box = ValueKey('box');

Widget _host(
  Widget child, {
  bool reduce = false,
  bool shown = true,
  TextDirection direction = TextDirection.ltr,
}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Directionality(
        textDirection: direction,
        child: TickerMode(
          enabled: shown,
          child: Center(child: child),
        ),
      ),
    );

/// Records the loop's progress every [step] for [total].
Future<List<double>> _record(
  WidgetTester tester,
  List<double> Function() read, {
  Duration step = const Duration(milliseconds: 50),
  required Duration total,
}) async {
  final out = <double>[];
  for (var e = Duration.zero; e < total; e += step) {
    await tester.pump(step);
    out.addAll(read());
  }
  return out;
}

/// Ends a test with nothing on screen and the conductor's quiet gap run
/// out, so no timer is left pending.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(AmbientConductor.gap);
}

void main() {
  setUp(() {
    AmbientMotion.enabled.value = true;
    AmbientConductor.reset();
  });
  tearDown(() {
    AmbientMotion.enabled.value = false;
    AmbientConductor.reset();
  });

  group('ambient loop', () {
    late double last;
    Widget loop({
      bool reduce = false,
      bool shown = true,
      bool enabled = true,
    }) =>
        _host(
          AmbientLoop(
            active: const Duration(milliseconds: 400),
            rest: const Duration(seconds: 2),
            delay: const Duration(seconds: 1),
            enabled: enabled,
            builder: (context, t, _) {
              last = t;
              return const SizedBox(key: _box, width: 10, height: 10);
            },
          ),
          reduce: reduce,
          shown: shown,
        );

    testWidgets('waits, moves, rests without drawing, and moves again',
        (tester) async {
      last = 0;
      await tester.pumpWidget(loop());
      // Before the delay: still, and no frames are being drawn.
      await tester.pump(const Duration(milliseconds: 900));
      expect(last, 0);
      expect(tester.hasRunningAnimations, isFalse);

      var moves = 0;
      var restingTicks = 0;
      var wasMoving = false;
      for (var i = 0; i < 300; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final moving = last > 0;
        if (moving && !wasMoving) moves++;
        if (!moving && !wasMoving && !tester.hasRunningAnimations) {
          restingTicks++;
        }
        wasMoving = moving;
      }
      // 15 s from the first second: each cycle is the move plus the longer
      // of its rest and the conductor's quiet gap (0.4 + 4 s).
      expect(moves, inInclusiveRange(3, 4));
      // Resting is most of the time, and it draws no frames: at least the
      // 2 s rest of every 2.5 s cycle (minus the ticks around each start).
      expect(restingTicks, greaterThan(300 * .7));
      await _finish(tester);
    });

    for (final (name, reduce, shown, enabled) in [
      ('reduced motion', true, true, true),
      ('a hidden tab or covered page', false, false, true),
      ('switched off by the caller', false, true, false),
    ]) {
      testWidgets('$name: never moves', (tester) async {
        last = 0;
        await tester
            .pumpWidget(loop(reduce: reduce, shown: shown, enabled: enabled));
        final seen = await _record(tester, () => [last],
            total: const Duration(seconds: 8));
        expect(seen.every((t) => t == 0), isTrue);
        expect(tester.hasRunningAnimations, isFalse);
        await _finish(tester);
      });
    }

    testWidgets('a hidden loop stops at rest and starts again when shown',
        (tester) async {
      last = 0;
      await tester.pumpWidget(loop());
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(last, greaterThan(0), reason: 'moving');
      await tester.pumpWidget(loop(shown: false));
      expect(last, 0, reason: 'back at rest at once');
      final hidden = await _record(tester, () => [last],
          total: const Duration(seconds: 6));
      expect(hidden.every((t) => t == 0), isTrue);
      await tester.pumpWidget(loop());
      final shownAgain = await _record(tester, () => [last],
          total: const Duration(seconds: 3));
      expect(shownAgain.any((t) => t > 0), isTrue);
      await _finish(tester);
    });

    testWidgets('switching ambient motion off app-wide stops it',
        (tester) async {
      last = 0;
      await tester.pumpWidget(loop());
      AmbientMotion.enabled.value = false;
      await tester.pump();
      final seen = await _record(tester, () => [last],
          total: const Duration(seconds: 6));
      expect(seen.every((t) => t == 0), isTrue);
      await _finish(tester);
    });
  });

  group('ambient moves', () {
    for (final kind in AmbientKind.values) {
      for (final d in TextDirection.values) {
        testWidgets('$kind ($d): moves, then rests exactly in place',
            (tester) async {
          await tester.pumpWidget(_host(
            AmbientMove(
              kind: kind,
              delay: Duration.zero,
              rest: const Duration(seconds: 10),
              child: const SizedBox(key: _box, width: 40, height: 40),
            ),
            direction: d,
          ));
          final rest = tester.getRect(find.byKey(_box));
          final rects = <Rect>[];
          for (var i = 0; i < 60; i++) {
            await tester.pump(const Duration(milliseconds: 50));
            rects.add(tester.getRect(find.byKey(_box)));
          }
          expect(rects.any((r) => r != rest), isTrue, reason: 'it moved');
          expect(rects.last, rest, reason: 'resting in place');
          if (kind == AmbientKind.nudge) {
            final dx = rects.map((r) => r.left - rest.left);
            if (d == TextDirection.rtl) {
              expect(dx.every((x) => x <= .01), isTrue);
            } else {
              expect(dx.every((x) => x >= -.01), isTrue);
            }
          }
          await _finish(tester);
        });
      }
    }
  });

  group('light sweep', () {
    for (final d in TextDirection.values) {
      testWidgets('$d: light only mid-pass, moving leading → trailing',
          (tester) async {
        double? bandX(double t) {
          final band = find.byKey(LightSweep.bandKey);
          if (band.evaluate().isEmpty) return null;
          final g = (tester
                  .widget<DecoratedBox>(find.descendant(
                      of: band, matching: find.byType(DecoratedBox)))
                  .decoration as BoxDecoration)
              .gradient! as LinearGradient;
          return ((g.begin as Alignment).x + (g.end as Alignment).x) / 2;
        }

        final xs = <double>[];
        for (final t in [0.0, .2, .4, .6, .8, 1.0]) {
          await tester.pumpWidget(_host(
            LightSweep(
              t: t,
              radius: 12,
              color: const Color(0xFFFFFFFF),
              child: const SizedBox(width: 100, height: 60),
            ),
            direction: d,
          ));
          final x = bandX(t);
          if (t == 0 || t == 1) {
            expect(x, isNull, reason: 't=$t');
          } else {
            xs.add(x!);
          }
        }
        for (var i = 1; i < xs.length; i++) {
          if (d == TextDirection.rtl) {
            expect(xs[i], lessThan(xs[i - 1]));
          } else {
            expect(xs[i], greaterThan(xs[i - 1]));
          }
        }
      });
    }
  });

  group('breathing band', () {
    testWidgets('the glow is only ever the band\'s own deep colour',
        (tester) async {
      const deep = Color(0xFF12384F);
      await tester.pumpWidget(_host(const BreathingBand(
        deep: deep,
        delay: Duration.zero,
        child: SizedBox(width: 300, height: 120),
      )));
      var seen = 0;
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final glow = find.byKey(BreathingBand.glowKey);
        if (glow.evaluate().isEmpty) continue;
        seen++;
        final g =
            (tester.widget<DecoratedBox>(glow).decoration as BoxDecoration)
                .gradient! as RadialGradient;
        for (final c in g.colors) {
          // Darkening only: same hue as the band, at most 45%.
          expect(c.withValues(alpha: 1), deep);
          expect(c.a, lessThanOrEqualTo(.45 + 1e-6));
        }
      }
      expect(seen, greaterThan(0));
      await _finish(tester);
    });
  });

  group('idle hint', () {
    double scale(WidgetTester tester) => tester
        .widget<Transform>(find
            .ancestor(of: find.byKey(_box), matching: find.byType(Transform))
            .first)
        .transform
        .entry(0, 0);

    testWidgets(
        'after the idle wait it pulses; a touch restarts the wait; at most '
        'three hints', (tester) async {
      await tester.pumpWidget(_host(const IdleNudge(
        maxHints: 3,
        child: SizedBox(key: _box, width: 80, height: 40),
      )));
      IdleNudgeState s() => tester.state(find.byType(IdleNudge));

      await tester.pump(const Duration(seconds: 5));
      expect(s().hints, 0);
      // A touch anywhere restarts the wait.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(seconds: 5));
      expect(s().hints, 0, reason: 'the touch restarted the wait');
      await tester.pump(const Duration(seconds: 1, milliseconds: 100));
      expect(s().hints, 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(tester), greaterThan(1), reason: 'pulsing');
      await tester.pump(const Duration(seconds: 1));
      expect(scale(tester), 1, reason: 'settled');

      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 7));
      }
      expect(s().hints, 3, reason: 'never more than three');
      await _finish(tester);
    });

    testWidgets('reduced motion: no hint', (tester) async {
      await tester.pumpWidget(_host(
          const IdleNudge(child: SizedBox(key: _box, width: 80, height: 40)),
          reduce: true));
      await tester.pump(const Duration(seconds: 20));
      expect(tester.state<IdleNudgeState>(find.byType(IdleNudge)).hints, 0);
      await _finish(tester);
    });
  });

  group('content arrives on every tab visit', () {
    Widget tabs(int current) => _host(
          SizedBox(
            width: 300,
            height: 300,
            child: MotionTabStack(
              currentIndex: current,
              children: const [
                MotionReveal(child: SizedBox(key: ValueKey('a'), height: 50)),
                MotionReveal(child: SizedBox(key: ValueKey('b'), height: 50)),
              ],
            ),
          ),
        );

    double opacity(WidgetTester tester, String key) => tester
        .widget<FadeTransition>(find
            .ancestor(
                of: find.byKey(ValueKey(key)),
                matching: find.byType(FadeTransition))
            .first)
        .opacity
        .value;

    testWidgets(
        'back to a tab after a while away: its content arrives again; a '
        'quick switch back keeps it as it was', (tester) async {
      await tester.pumpWidget(tabs(0));
      await tester.pumpAndSettle();
      expect(opacity(tester, 'a'), 1);

      // Quick back-and-forth: nothing replays.
      await tester.pumpWidget(tabs(1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(tabs(0));
      await tester.pump();
      expect(opacity(tester, 'a'), 1, reason: 'a quick switch replays nothing');
      await tester.pumpAndSettle();

      // Away for longer than staleAfter: it arrives again.
      await tester.pumpWidget(tabs(1));
      await tester.pumpAndSettle();
      await tester.pump(MotionTabStack.staleAfter);
      await tester.pumpWidget(tabs(0));
      await tester.pump();
      expect(opacity(tester, 'a'), lessThan(1), reason: 'arriving again');
      await tester.pumpAndSettle();
      expect(opacity(tester, 'a'), 1);
    });

    testWidgets('with ambient motion off it stays put', (tester) async {
      AmbientMotion.enabled.value = false;
      await tester.pumpWidget(tabs(0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(tabs(1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(tabs(0));
      await tester.pump();
      expect(opacity(tester, 'a'), 1);
    });
  });

  group('conductor priority', () {
    // Every ordered pair of priorities: whichever was asked for first, the
    // higher one gets the next turn; equal ones go first come, first served.
    for (final first in AmbientPriority.values) {
      for (final second in AmbientPriority.values) {
        testWidgets('${first.name} queued before ${second.name}',
            (tester) async {
          final started = <String>[];
          final playing = Object();
          AmbientConductor.request(playing, () {});
          AmbientConductor.request(#first, () => started.add('first'),
              priority: first);
          AmbientConductor.request(#second, () => started.add('second'),
              priority: second);
          AmbientConductor.done(playing);
          await tester.pump(AmbientConductor.gap);
          final winner = second.index > first.index ? 'second' : 'first';
          expect(started, [winner]);
          AmbientConductor.reset();
        });
      }
    }
  });

  group('decaying cadence', () {
    test('each rest is decay times the one before, for any base', () {
      for (final ms in [1, 450, 2000, 6000, 30000]) {
        final base = Duration(milliseconds: ms);
        expect(AmbientLoop.restAfter(base, 1), base);
        for (var k = 2; k <= AmbientLoop.maxPlays; k++) {
          final before = AmbientLoop.restAfter(base, k - 1);
          final now = AmbientLoop.restAfter(base, k);
          expect(now.inMicroseconds,
              closeTo(before.inMicroseconds * AmbientLoop.decay, 1));
        }
      }
    });

    testWidgets(
        'a loop stops after maxPlays moves, and a new session revives it',
        (tester) async {
      final key = GlobalKey<AmbientLoopState>();
      await tester.pumpWidget(_host(AmbientLoop(
        key: key,
        active: const Duration(milliseconds: 100),
        rest: const Duration(milliseconds: 500),
        builder: (context, t, _) => const SizedBox(width: 10, height: 10),
      )));
      // Far longer than six moves with growing rests and quiet gaps.
      for (var i = 0; i < 1200; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(key.currentState!.plays, AmbientLoop.maxPlays);
      expect(tester.hasRunningAnimations, isFalse);

      AmbientMotion.foreground.value = false;
      await tester.pump();
      AmbientMotion.foreground.value = true;
      await tester.pump(AmbientConductor.gap);
      await tester.pump(const Duration(milliseconds: 50));
      expect(key.currentState!.plays, 1, reason: 'a new session starts over');
      await _finish(tester);
    });
  });
}
