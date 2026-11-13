import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/routing/expand_page_route.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/shared/widgets/motion.dart';

const _screen = Size(400, 800);
const _destination = ValueKey('destination');

/// Card positions a list can produce: either edge, mid-list, full width, and
/// one scrolled half off the bottom of the screen.
const _origins = <Rect>[
  Rect.fromLTWH(16, 120, 368, 150),
  Rect.fromLTWH(0, 0, 400, 90),
  Rect.fromLTWH(210, 560, 174, 220),
  Rect.fromLTWH(16, 300, 174, 60),
  Rect.fromLTWH(16, 740, 368, 150),
];

Future<NavigatorState> _pumpHost(
  WidgetTester tester, {
  bool reduceMotion = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navigator,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Directionality(textDirection: direction, child: child!),
    ),
    home: const Scaffold(body: Text('list')),
  ));
  return navigator.currentState!;
}

ExpandPageRoute<void> _route(Rect origin, {double radius = 16}) =>
    ExpandPageRoute<void>(
      origin: ExpandOrigin(rect: origin, radius: radius),
      builder: (_) => const Scaffold(key: _destination, body: Text('page')),
    );

/// The rounded rectangle the destination page is visible through right now.
RRect _reveal(WidgetTester tester) {
  final clip = tester.widget<ClipRRect>(find.byKey(ExpandPageRoute.revealKey));
  if (clip.clipBehavior == Clip.none) {
    return RRect.fromRectAndRadius(Offset.zero & _screen, Radius.zero);
  }
  return clip.clipper!.getClip(_screen);
}

/// The part of a card that is on screen, which is where the reveal starts.
Rect _visible(Rect origin) => origin.intersect(Offset.zero & _screen);

bool _contains(Rect outer, Rect inner) =>
    outer.left <= inner.left + 1e-6 &&
    outer.top <= inner.top + 1e-6 &&
    outer.right >= inner.right - 1e-6 &&
    outer.bottom >= inner.bottom - 1e-6;

void main() {
  test('expand timing is the shared card-expand token', () {
    expect(ExpandPageRoute.duration, MotionDurations.slow);
    expect(ExpandPageRoute.curve, MotionCurves.standard);
  });

  for (final direction in TextDirection.values) {
    for (final origin in _origins) {
      testWidgets(
        'page grows from $origin to the full screen (${direction.name})',
        (tester) async {
          final navigator = await _pumpHost(tester, direction: direction);
          const radius = 16.0;
          unawaited(navigator.push(_route(origin, radius: radius)));
          // One frame inserts the route, the next builds it at progress 0.
          await tester.pump();
          await tester.pump();

          final start = _reveal(tester);
          expect(start.outerRect, _visible(origin));
          expect(start.tlRadiusX, radius);

          var previous = start;
          const frames = 14;
          for (var i = 0; i < frames; i++) {
            await tester.pump(ExpandPageRoute.duration ~/ frames);
            final now = _reveal(tester);
            expect(
              _contains(now.outerRect, previous.outerRect),
              isTrue,
              reason: 'frame $i shrank: ${previous.outerRect} → '
                  '${now.outerRect}',
            );
            expect(now.tlRadiusX, lessThanOrEqualTo(previous.tlRadiusX));
            previous = now;
          }

          await tester.pumpAndSettle();
          final end = _reveal(tester);
          expect(end.outerRect, Offset.zero & _screen);
          expect(end.tlRadiusX, 0);
          expect(tester.getSize(find.byKey(_destination)), _screen);
        },
      );

      testWidgets(
        'going back shrinks the page onto $origin (${direction.name})',
        (tester) async {
          final navigator = await _pumpHost(tester, direction: direction);
          unawaited(navigator.push(_route(origin)));
          await tester.pumpAndSettle();

          navigator.pop();
          await tester.pump();
          var previous = _reveal(tester);
          const frames = 14;
          for (var i = 0; i < frames - 1; i++) {
            await tester.pump(ExpandPageRoute.duration ~/ frames);
            final now = _reveal(tester);
            expect(_contains(previous.outerRect, now.outerRect), isTrue);
            expect(_contains(now.outerRect, _visible(origin)), isTrue);
            previous = now;
          }

          await tester.pumpAndSettle();
          expect(find.byKey(_destination), findsNothing);
          expect(find.text('list'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('the page keeps its state when the expand finishes',
      (tester) async {
    final navigator = await _pumpHost(tester);
    var builds = 0;
    unawaited(navigator.push(ExpandPageRoute<void>(
      origin: const ExpandOrigin(rect: Rect.fromLTWH(16, 120, 368, 150)),
      builder: (_) => _Counter(onInit: () => builds++),
    )));
    await tester.pumpAndSettle();
    expect(builds, 1);
  });

  testWidgets('reduced motion shows the whole page on the first frame',
      (tester) async {
    for (final origin in _origins) {
      final navigator = await _pumpHost(tester, reduceMotion: true);
      unawaited(navigator.push(_route(origin)));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(ExpandPageRoute.revealKey), findsNothing);
      expect(tester.getSize(find.byKey(_destination)), _screen);
      final opacities = tester.widgetList<FadeTransition>(find.ancestor(
        of: find.byKey(_destination),
        matching: find.byType(FadeTransition),
      ));
      for (final fade in opacities) {
        expect(fade.opacity.value, 1);
      }
      await tester.pumpAndSettle();
    }
  });

  testWidgets('ExpandOrigin.of measures the widget inside its navigator',
      (tester) async {
    for (final origin in _origins.take(4)) {
      await _pumpHost(tester);
      late BuildContext cardContext;
      await tester.pumpWidget(MaterialApp(
        home: Stack(children: [
          Positioned.fromRect(
            rect: origin,
            child: Builder(builder: (context) {
              cardContext = context;
              return const ColoredBox(color: Colors.black);
            }),
          ),
        ]),
      ));
      final measured = ExpandOrigin.of(cardContext, radius: 12);
      expect(measured, ExpandOrigin(rect: origin, radius: 12));
    }
  });

  group('AppRouter', () {
    setUpAll(registerSiratiRouteWidgets);

    testWidgets('ExpandFrom arguments produce an expanding page',
        (tester) async {
      for (final origin in _origins) {
        final route = AppRouter.onGenerateRoute(RouteSettings(
          name: AppRoutes.cv(7),
          arguments: ExpandFrom(ExpandOrigin(rect: origin)),
        ));
        expect(route, isA<ExpandPageRoute<dynamic>>());
        expect((route as ExpandPageRoute).origin.rect, origin);
        expect(route.settings.name, AppRoutes.cv(7));
      }
    });

    test('routes without ExpandFrom keep the standard page', () {
      final route = AppRouter.onGenerateRoute(
        RouteSettings(name: AppRoutes.cv(7)),
      );
      expect(route, isNot(isA<ExpandPageRoute<dynamic>>()));
    });

    test('ExpandFrom forwards the wrapped arguments to the page', () {
      const inner = Object();
      const wrapped = ExpandFrom(
        ExpandOrigin(rect: Rect.fromLTWH(0, 0, 10, 10)),
        arguments: inner,
      );
      expect(ExpandFrom.unwrap(wrapped), same(inner));
      expect(ExpandFrom.unwrap(inner), same(inner));
      expect(ExpandFrom.unwrap(null), isNull);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('page'));
}
