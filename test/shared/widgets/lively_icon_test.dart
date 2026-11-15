import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';

const _size = 24.0;
const _key = ValueKey('icon');

Future<void> _pump(
  WidgetTester tester,
  Widget icon, {
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
  bool settle = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: IconPressListener(
            child: SizedBox.square(
              key: const ValueKey('target'),
              dimension: 80,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Where the glyph is drawn, transforms included.
Rect _drawn(WidgetTester tester) => tester.getRect(
    find.descendant(of: find.byKey(_key), matching: find.byType(Icon)));

Rect get _rest => Rect.fromCenter(
    center: const Offset(400, 300), width: _size, height: _size);

bool _same(Rect a, Rect b) =>
    (a.topLeft - b.topLeft).distance < .01 &&
    (a.bottomRight - b.bottomRight).distance < .01;

/// Samples the drawn rect every frame until nothing is moving.
Future<List<Rect>> _record(WidgetTester tester) async {
  final frames = <Rect>[];
  for (var i = 0; i < 400; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    frames.add(_drawn(tester));
    if (!tester.state<LivelyIconState>(find.byKey(_key)).isMoving) break;
  }
  return frames;
}

void main() {
  // Turns are shared app-wide; every test starts with none taken.
  setUp(LivelyIcon.debugResetTurns);

  group('press', () {
    for (final hold in const [30, 60, 90]) {
      testWidgets('a quick ${hold}ms tap still bounces visibly',
          (tester) async {
        await _pump(
            tester, const LivelyIcon(Icons.star, key: _key, size: _size),
            settle: true);
        final g = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('target'))));
        await tester.pump();
        await tester.pump(Duration(milliseconds: hold));
        await g.up();
        final frames = await _record(tester);
        final peak = frames.map((r) => r.width).reduce((a, b) => a > b ? a : b);
        expect(peak / _size, inInclusiveRange(1.03, 1.15));
        expect(_same(frames.last, _rest), isTrue);
      });
    }

    testWidgets('squishes while held, bounces past rest, settles exactly',
        (tester) async {
      await _pump(tester, const LivelyIcon(Icons.star, key: _key, size: _size),
          settle: true);
      expect(_same(_drawn(tester), _rest), isTrue);

      final g = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('target'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
          _drawn(tester).width, closeTo(_size * LivelyIcon.pressedScale, .01));

      await g.up();
      final frames = await _record(tester);
      final peak = frames.map((r) => r.width).reduce((a, b) => a > b ? a : b);
      // A bounce you can see, but not a wobble.
      expect(peak / _size, inInclusiveRange(1.04, 1.15),
          reason: 'it springs visibly past its size');
      expect(_same(frames.last, _rest), isTrue);
      expect(frames.length * 16, lessThanOrEqualTo(500),
          reason: 'settles within half a second');
    });

    testWidgets('a cancelled press springs back too', (tester) async {
      await _pump(tester, const LivelyIcon(Icons.star, key: _key, size: _size),
          settle: true);
      final g = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('target'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await g.cancel();
      await tester.pumpAndSettle();
      expect(_same(_drawn(tester), _rest), isTrue);
    });

    testWidgets('with reduced motion a press changes nothing', (tester) async {
      await _pump(tester, const LivelyIcon(Icons.star, key: _key, size: _size),
          reduce: true, settle: true);
      final g = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('target'))));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(_same(_drawn(tester), _rest), isTrue);
      }
      await g.up();
    });
  });

  group('life', () {
    final moving = IconLife.values.where((l) => l != IconLife.none);
    for (final life in moving) {
      for (final plays in [1, 3]) {
        testWidgets('$life × $plays: moves, then rests exactly, then stops',
            (tester) async {
          await _pump(
              tester,
              LivelyIcon(Icons.star,
                  key: _key, size: _size, life: life, plays: plays));
          final frames = await _record(tester);
          expect(frames.any((r) => !_same(r, _rest)), isTrue,
              reason: 'it should visibly move');
          expect(_same(frames.last, _rest), isTrue);
          // It stops on its own: no endless loop.
          expect(tester.state<LivelyIconState>(find.byKey(_key)).isMoving,
              isFalse);
          final elapsed = frames.length * 16;
          expect(
              elapsed,
              lessThanOrEqualTo(
                  LivelyIcon.lifeDuration.inMilliseconds * plays + 100));
        });
      }

      testWidgets('$life: still with reduced motion or no plays',
          (tester) async {
        for (final (reduce, plays) in [(true, 2), (false, 0)]) {
          await tester.pumpWidget(const SizedBox());
          await _pump(
              tester,
              LivelyIcon(Icons.star,
                  key: _key, size: _size, life: life, plays: plays),
              reduce: reduce);
          for (var i = 0; i < 120; i++) {
            await tester.pump(const Duration(milliseconds: 16));
            expect(_same(_drawn(tester), _rest), isTrue,
                reason: 'reduce=$reduce plays=$plays');
          }
        }
      });
    }

    testWidgets('a new trigger plays the move again', (tester) async {
      Widget icon(int count) => LivelyIcon(Icons.notifications,
          key: _key,
          size: _size,
          life: IconLife.ring,
          plays: 1,
          trigger: count);
      await _pump(tester, icon(1), settle: true);
      await _pump(tester, icon(1));
      expect((await _record(tester)).every((r) => _same(r, _rest)), isTrue,
          reason: 'same trigger: no replay');
      await _pump(tester, icon(2));
      expect((await _record(tester)).any((r) => !_same(r, _rest)), isTrue);
    });

    for (final direction in TextDirection.values) {
      testWidgets('nudge points toward the trailing edge in $direction',
          (tester) async {
        await _pump(
            tester,
            const LivelyIcon(Icons.chevron_right,
                key: _key, size: _size, life: IconLife.nudge, plays: 1),
            direction: direction);
        final dx = [for (final r in await _record(tester)) r.left - _rest.left];
        if (direction == TextDirection.rtl) {
          expect(dx.reduce((a, b) => a < b ? a : b), lessThan(-1));
          expect(dx.every((d) => d <= .01), isTrue);
        } else {
          expect(dx.reduce((a, b) => a > b ? a : b), greaterThan(1));
          expect(dx.every((d) => d >= -.01), isTrue);
        }
      });
    }
  });

  group('taking turns', () {
    Future<void> pumpMany(WidgetTester tester, int count,
        {bool visible = true}) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: visible,
          child: Row(children: [
            for (var i = 0; i < count; i++)
              LivelyIcon(Icons.star,
                  key: ValueKey('icon-$i'), life: IconLife.float, plays: 1),
          ]),
        ),
      ));
    }

    List<LivelyIconState> states(WidgetTester tester, int count) => [
          for (var i = 0; i < count; i++)
            tester.state<LivelyIconState>(find.byKey(ValueKey('icon-$i'))),
        ];

    for (final count in [2, 3, 4, 6, 9]) {
      testWidgets(
          '$count icons: never more than 2 at once, none starts after the '
          'wait limit, and every one that fits in time moves', (tester) async {
        await pumpMany(tester, count);
        final startedAt = <int, int>{};
        var elapsed = 0;
        for (var f = 0; f < 800; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          elapsed += 16;
          final s = states(tester, count);
          final moving = [
            for (var i = 0; i < count; i++)
              if (s[i].isMoving) i,
          ];
          expect(moving.length, lessThanOrEqualTo(2), reason: 'frame $f');
          for (final i in moving) {
            startedAt.putIfAbsent(i, () => elapsed);
          }
          if (s.every((x) => !x.isMoving && !x.isWaiting)) break;
        }
        // Nothing starts long after the page appeared.
        for (final t in startedAt.values) {
          expect(
              t, lessThanOrEqualTo(LivelyIcon.maxWait.inMilliseconds + 2 * 16));
        }
        // Turns go in order, two at a time: icon i starts at about
        // (i ~/ 2) plays in; every icon whose turn comes within the limit
        // gets it.
        final play = LivelyIcon.lifeDuration.inMilliseconds;
        for (var i = 0; i < count; i++) {
          final due = (i ~/ 2) * play;
          if (due < LivelyIcon.maxWait.inMilliseconds - 100) {
            expect(startedAt.containsKey(i), isTrue, reason: 'icon $i');
          }
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a hidden icon waits, then moves once it is shown',
        (tester) async {
      await pumpMany(tester, 1, visible: false);
      for (var f = 0; f < 60; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(states(tester, 1).single.isMoving, isFalse);
      }
      await pumpMany(tester, 1);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(states(tester, 1).single.isMoving, isTrue);
      await tester.pumpAndSettle();
      expect(states(tester, 1).single.isMoving, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'hiding moving icons while others wait hands the turn on cleanly',
        (tester) async {
      Widget build(bool firstShown) => Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              for (var i = 0; i < 2; i++)
                TickerMode(
                  enabled: firstShown,
                  child: LivelyIcon(Icons.star,
                      key: ValueKey('icon-$i'), life: IconLife.float, plays: 1),
                ),
              for (var i = 2; i < 4; i++)
                LivelyIcon(Icons.star,
                    key: ValueKey('icon-$i'), life: IconLife.float, plays: 1),
            ]),
          );
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(states(tester, 4).where((s) => s.isMoving), hasLength(2));
      // The two moving icons are hidden mid-move (a tab switch).
      await tester.pumpWidget(build(false));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final s = states(tester, 4);
      expect(s[2].isMoving && s[3].isMoving, isTrue,
          reason: 'the waiting icons got the turns');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a move that waited too long is dropped, not played late',
        (tester) async {
      // Two long movers hold the turns well past the wait limit.
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          for (var i = 0; i < 2; i++)
            LivelyIcon(Icons.star,
                key: ValueKey('icon-$i'), life: IconLife.float, plays: 3),
          const LivelyIcon(Icons.star,
              key: ValueKey('icon-2'), life: IconLife.float, plays: 1),
        ]),
      ));
      await tester.pump(const Duration(milliseconds: 16));
      final late = states(tester, 3)[2];
      expect(late.isWaiting, isTrue);
      expect(LivelyIcon.lifeDuration * 3, greaterThan(LivelyIcon.maxWait));
      for (var f = 0; f < 400; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(late.isMoving, isFalse, reason: 'frame $f');
      }
      expect(late.isWaiting, isFalse, reason: 'dropped from the queue');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hidden icons do not hold turns from visible ones',
        (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          for (var i = 0; i < 3; i++)
            TickerMode(
              enabled: false,
              child: LivelyIcon(Icons.star,
                  key: ValueKey('hidden-$i'), life: IconLife.float),
            ),
          const LivelyIcon(Icons.star,
              key: ValueKey('shown'), life: IconLife.float, plays: 1),
        ]),
      ));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
          tester
              .state<LivelyIconState>(find.byKey(const ValueKey('shown')))
              .isMoving,
          isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
