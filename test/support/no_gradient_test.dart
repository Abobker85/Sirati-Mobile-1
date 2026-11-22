import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'no_gradient.dart';

void main() {
  const root = ValueKey('root');
  const linear = LinearGradient(colors: [Color(0xFF000000), Color(0xFF0000FF)]);
  const radial = RadialGradient(colors: [Color(0xFF000000), Color(0xFF0000FF)]);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: KeyedSubtree(
              key: root,
              child: Column(children: [
                // A plain fill, so a clean tree is never a vacuous pass.
                const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFFFFFFF)),
                    child: SizedBox(width: 10, height: 10)),
                child,
              ]),
            ),
          ),
        ),
      );

  bool fails(void Function() check) {
    try {
      check();
    } on TestFailure {
      return true;
    }
    return false;
  }

  final planted = <String, Widget>{
    'BoxDecoration linear': const DecoratedBox(
        decoration: BoxDecoration(gradient: linear), child: SizedBox()),
    'BoxDecoration radial': const DecoratedBox(
        decoration: BoxDecoration(gradient: radial), child: SizedBox()),
    'ShapeDecoration': const DecoratedBox(
        decoration: ShapeDecoration(shape: StadiumBorder(), gradient: linear),
        child: SizedBox()),
    'Container': Container(
        decoration: const BoxDecoration(gradient: linear), width: 4, height: 4),
    'Ink': Ink(
        decoration: const BoxDecoration(gradient: linear), width: 4, height: 4),
    'ShaderMask': ShaderMask(
        shaderCallback: (rect) => linear.createShader(rect),
        child: const SizedBox(width: 4, height: 4)),
  };

  for (final entry in planted.entries) {
    testWidgets('rejects a planted ${entry.key}', (tester) async {
      await pump(tester, entry.value);
      expect(
          fails(() => expectNoGradient(find.byKey(root), entry.key)), isTrue);
    });
  }

  testWidgets('passes flat fills', (tester) async {
    await pump(
        tester,
        Container(
            decoration: BoxDecoration(
                color: const Color(0xFF00FF00),
                borderRadius: BorderRadius.circular(8)),
            width: 4,
            height: 4));
    expect(expectNoGradient(find.byKey(root), 'flat'), greaterThan(1));
  });

  testWidgets('a walk that checked nothing fails', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: KeyedSubtree(key: root, child: SizedBox())));
    expect(fails(() => expectNoGradient(find.byKey(root), 'empty')), isTrue);
  });
}
