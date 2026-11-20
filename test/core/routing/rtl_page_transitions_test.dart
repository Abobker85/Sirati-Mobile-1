import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/edge_back_swipe.dart';
import 'package:sirati/core/routing/expand_page_route.dart';
import 'package:sirati/core/routing/fade_through_page_route.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

const _a = ValueKey('page-a');
const _b = ValueKey('page-b');
const _size = Size(400, 800);

/// The three kinds of page the app pushes.
enum _Kind { standard, expand, fadeThrough }

PageRoute<void> _route(_Kind kind, Widget page) => switch (kind) {
      _Kind.standard => MaterialPageRoute<void>(builder: (_) => page),
      _Kind.expand => ExpandPageRoute<void>(
          origin: const ExpandOrigin(rect: Rect.fromLTWH(40, 200, 240, 96)),
          builder: (_) => page,
        ),
      _Kind.fadeThrough => FadeThroughPageRoute<void>(builder: (_) => page),
    };

Widget _page(Key key) => Scaffold(
      key: key,
      body: const Center(child: Text('page')),
    );

/// Pumps page A in the real app theme and returns a context to push from.
Future<BuildContext> _pumpApp(
  WidgetTester tester, {
  required TextDirection direction,
  bool reduce = false,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final rtl = direction == TextDirection.rtl;
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    // The app theme is cached, so the platform is set explicitly.
    theme: AppTheme.lightFor(arabic: rtl).copyWith(platform: platform),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(rtl ? 'ar' : 'en'),
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: c!,
    ),
    home: Builder(builder: (c) {
      ctx = c;
      return _page(_a);
    }),
  ));
  return ctx;
}

/// Pushes [route] and lets it settle.
Future<void> _push(
    WidgetTester tester, BuildContext ctx, PageRoute<void> route) async {
  unawaited(Navigator.of(ctx).push(route));
  await tester.pumpAndSettle();
}

double _x(WidgetTester tester, Key key) =>
    tester.getTopLeft(find.byKey(key)).dx;

/// +1 toward the end edge (left in Arabic), as screen x.
double _endSign(TextDirection d) => d == TextDirection.rtl ? -1 : 1;

/// A point just inside the start edge (the right in Arabic).
Offset _startEdge(TextDirection d) =>
    Offset(d == TextDirection.rtl ? _size.width - 5 : 5, _size.height / 2);

/// A point just inside the end edge.
Offset _endEdge(TextDirection d) =>
    Offset(d == TextDirection.rtl ? 5 : _size.width - 5, _size.height / 2);

NavigatorState _nav(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

/// Starts a drag at [from] and moves it [distance] toward the end edge in
/// small steps, pumping each. Returns the gesture, still down.
Future<TestGesture> _dragToward(
  WidgetTester tester,
  TextDirection d,
  Offset from,
  double distance,
) async {
  final gesture = await tester.startGesture(from);
  const steps = 20;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(_endSign(d) * distance / steps, 0));
    await tester.pump(const Duration(milliseconds: 50));
  }
  return gesture;
}

void main() {
  group('push direction', () {
    for (final platform in const [TargetPlatform.android, TargetPlatform.iOS]) {
      for (final d in TextDirection.values) {
        testWidgets(
            '${platform.name} ${d.name}: the new page slides in from the end '
            'edge and the old one moves toward the start; back is the mirror',
            (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          final ctx = await _pumpApp(tester, direction: d, platform: platform);
          final end = _endSign(d);
          unawaited(Navigator.of(ctx)
              .push(MaterialPageRoute<void>(builder: (_) => _page(_b))));
          await tester.pump();
          await tester.pump(SiratiPageTransitionsBuilder.duration ~/ 4);
          // Arabic: comes from the left (x < 0), old page moves right.
          expect(_x(tester, _b) * end, greaterThan(0));
          expect(_x(tester, _a) * end, lessThan(0));
          await tester.pumpAndSettle();
          expect(_x(tester, _b), 0);

          Navigator.of(ctx).pop();
          await tester.pump();
          await tester.pump(SiratiPageTransitionsBuilder.duration ~/ 4);
          expect(_x(tester, _b) * end, greaterThan(0),
              reason: 'leaves toward the end edge');
          expect(_x(tester, _a) * end, lessThan(0),
              reason: 'old page comes back from the start side');
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsNothing);
          expect(_x(tester, _a), 0);
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }

    test('push and back take about 350ms', () {
      const b = SiratiPageTransitionsBuilder();
      expect(b.transitionDuration, const Duration(milliseconds: 350));
      expect(b.reverseTransitionDuration, const Duration(milliseconds: 350));
    });

    for (final d in TextDirection.values) {
      testWidgets('${d.name}: under an expanding page the page below stays put',
          (tester) async {
        final ctx = await _pumpApp(tester, direction: d);
        unawaited(Navigator.of(ctx).push(_route(_Kind.expand, _page(_b))));
        for (var f = 0; f < 6; f++) {
          await tester.pump(const Duration(milliseconds: 40));
          expect(_x(tester, _a), 0, reason: 'frame $f');
        }
        await tester.pumpAndSettle();
      });
    }
  });

  group('back swipe', () {
    for (final kind in _Kind.values) {
      for (final d in TextDirection.values) {
        final label = '${kind.name} ${d.name}';

        testWidgets(
            '$label: follows the finger from the start edge, and a '
            'long drag goes back', (tester) async {
          final ctx = await _pumpApp(tester, direction: d);
          final route = _route(kind, _page(_b));
          await _push(tester, ctx, route);
          final gesture =
              await _dragToward(tester, d, _startEdge(d), _size.width * .3);
          // Mid-swipe: the page is part way out, under the finger.
          final shown = route.animation!.value;
          expect(shown, lessThan(.85));
          expect(shown, greaterThan(.55));
          expect(_nav(tester).userGestureInProgress, isTrue);
          if (kind == _Kind.standard) {
            expect(_x(tester, _b) * _endSign(d), greaterThan(80));
          }
          // On past half way, without reaching the far edge.
          for (var i = 0; i < 8; i++) {
            await gesture.moveBy(Offset(_endSign(d) * 20, 0));
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.pump(const Duration(milliseconds: 400));
          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsNothing);
          expect(find.byKey(_a), findsOneWidget);
          expect(_nav(tester).userGestureInProgress, isFalse);
        });

        testWidgets('$label: letting go early cancels it', (tester) async {
          final ctx = await _pumpApp(tester, direction: d);
          final route = _route(kind, _page(_b));
          await _push(tester, ctx, route);
          final gesture =
              await _dragToward(tester, d, _startEdge(d), _size.width * .25);
          expect(route.animation!.value, lessThan(.9));
          // Hold still so the release has no fling.
          await tester.pump(const Duration(milliseconds: 400));
          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsOneWidget);
          expect(route.isCurrent, isTrue);
          expect(route.animation!.value, 1);
          expect(_x(tester, _b), 0);
          expect(_nav(tester).userGestureInProgress, isFalse);
          // And the page still goes back normally afterwards.
          Navigator.of(ctx).pop();
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsNothing);
        });

        testWidgets('$label: a quick flick goes back even from early on',
            (tester) async {
          final ctx = await _pumpApp(tester, direction: d);
          await _push(tester, ctx, _route(kind, _page(_b)));
          await tester.timedDragFrom(
            _startEdge(d),
            Offset(_endSign(d) * _size.width * .3, 0),
            const Duration(milliseconds: 100),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsNothing);
        });

        testWidgets('$label: a drag from the end edge does nothing',
            (tester) async {
          final ctx = await _pumpApp(tester, direction: d);
          final route = _route(kind, _page(_b));
          await _push(tester, ctx, route);
          // Toward the start, from the end edge (the mirror of a swipe).
          await tester.timedDragFrom(
            _endEdge(d),
            Offset(-_endSign(d) * _size.width * .8, 0),
            const Duration(milliseconds: 400),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsOneWidget);
          expect(route.animation!.value, 1);
        });

        testWidgets('$label: a screen that blocks back refuses it',
            (tester) async {
          final ctx = await _pumpApp(tester, direction: d);
          final route = _route(kind, PopScope(canPop: false, child: _page(_b)));
          await _push(tester, ctx, route);
          await tester.timedDragFrom(
            _startEdge(d),
            Offset(_endSign(d) * _size.width * .8, 0),
            const Duration(milliseconds: 400),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsOneWidget);
          expect(route.animation!.value, 1);
        });
      }
    }

    test('the swipe strip is the usual edge width', () {
      expect(EdgeBackSwipe.edgeWidth, 20);
    });
  });

  group('reduced motion', () {
    for (final kind in _Kind.values) {
      for (final d in TextDirection.values) {
        testWidgets(
            '${kind.name} ${d.name}: the page is in place on the first '
            'frame, and the back swipe still works', (tester) async {
          final ctx = await _pumpApp(tester, direction: d, reduce: true);
          unawaited(Navigator.of(ctx).push(_route(kind, _page(_b))));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(_x(tester, _b), 0);
          expect(tester.getSize(find.byKey(_b)), _size);
          await tester.pumpAndSettle();
          if (kind == _Kind.standard) {
            // Nothing slides under the page either.
            expect(find.byKey(_a, skipOffstage: false), findsOneWidget);
          }
          await tester.timedDragFrom(
            _startEdge(d),
            Offset(_endSign(d) * _size.width * .8, 0),
            const Duration(milliseconds: 400),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(_b), findsNothing);
        });
      }
    }
  });
}
