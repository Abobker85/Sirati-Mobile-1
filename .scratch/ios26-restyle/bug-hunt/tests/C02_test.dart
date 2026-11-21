import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/expand_page_route.dart';

Rect _reveal(WidgetTester tester) {
  final clip = tester.widget<ClipRRect>(find.byKey(ExpandPageRoute.revealKey));
  final size = tester.getSize(find.byKey(ExpandPageRoute.revealKey));
  return clip.clipper!.getClip(size).outerRect;
}

double _jump(Rect a, Rect b) => [
      (a.left - b.left).abs(),
      (a.top - b.top).abs(),
      (a.right - b.right).abs(),
      (a.bottom - b.bottom).abs(),
    ].reduce((x, y) => x > y ? x : y);

void main() {
  // Invariant: the reveal is continuous in time. Interrupting a push at any
  // point must not move the clip in a frame where (almost) no time passes.
  for (final ms in [40, 100, 160, 220]) {
    testWidgets('C02 pop ${ms}ms into the push does not snap the reveal',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: SizedBox.expand()),
      ));
      nav.currentState!.push(ExpandPageRoute<void>(
        origin: const ExpandOrigin(rect: Rect.fromLTWH(16, 300, 174, 60)),
        builder: (_) => const Scaffold(body: Text('page')),
      ));
      await tester.pump();
      await tester.pump(Duration(milliseconds: ms));
      final before = _reveal(tester);
      nav.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final after = _reveal(tester);
      // 1 ms of a 280 ms transition can move the clip by at most a few px.
      expect(_jump(before, after), lessThan(5),
          reason: 'before=$before after=$after');
      await tester.pumpAndSettle();
    });
  }
}
