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
  group('press', () {
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
      expect(frames.map((r) => r.width).reduce((a, b) => a > b ? a : b),
          greaterThan(_size + .1),
          reason: 'it springs a little past its size');
      expect(_same(frames.last, _rest), isTrue);
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
}
