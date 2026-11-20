import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'card_chrome.dart';

/// Mutation tests for [expectNoCardChrome]: every kind of card outline or
/// lift must be rejected, and plain fills must pass. (Cases from the ticket
/// 17 review.)
bool _fails(void Function() check) {
  try {
    check();
    return false;
  } on TestFailure {
    return true;
  }
}

Future<void> _pump(WidgetTester tester, Widget body) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));

void main() {
  final rejected = <String, Widget>{
    'Border.all': Container(
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: Colors.grey))),
    'hairline BorderDirectional': Container(
        decoration: const BoxDecoration(
            border: BorderDirectional(
                start: BorderSide(color: Colors.grey, width: 0.5)))),
    'width 0 solid side (a 1px hairline)': Container(
        decoration:
            BoxDecoration(border: Border.all(color: Colors.grey, width: 0))),
    'BoxShadow': Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)])),
    'Card elevation': const Card(child: SizedBox(height: 10)),
    'Card outlined': const Card(
        elevation: 0,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey))),
    'Material outlined': const Material(
        shape: StadiumBorder(side: BorderSide(color: Colors.grey)),
        child: SizedBox(height: 10)),
    'ShapeDecoration side': Container(
        decoration: const ShapeDecoration(
            shape:
                RoundedRectangleBorder(side: BorderSide(color: Colors.grey)))),
    'ShapeDecoration shadow': Container(
        decoration: const ShapeDecoration(
            shape: RoundedRectangleBorder(),
            shadows: [BoxShadow(blurRadius: 8, color: Colors.black26)])),
    'PhysicalModel elevation': const PhysicalModel(
        color: Colors.white, elevation: 6, child: SizedBox(height: 10)),
    'PhysicalShape elevation': const PhysicalShape(
        clipper: ShapeBorderClipper(shape: StadiumBorder()),
        color: Colors.white,
        elevation: 6,
        child: SizedBox(height: 10)),
    'canvas Material elevation': const Material(
        type: MaterialType.canvas, elevation: 6, child: SizedBox(height: 10)),
  };
  for (final MapEntry(key: name, value: widget) in rejected.entries) {
    testWidgets('card_chrome rejects $name', (tester) async {
      await _pump(
        tester,
        Column(children: [
          // A clean fill beside it, so the walk is not empty either way.
          Container(
              decoration: const BoxDecoration(color: Colors.white), height: 5),
          SizedBox(width: 100, height: 40, child: widget),
        ]),
      );
      expect(
          _fails(() => expectNoCardChrome(find.byType(Scaffold), name)), isTrue,
          reason: '$name slipped through');
    });
  }

  final accepted = <String, Widget>{
    'a borderless rounded fill': Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12))),
    'a flat Material fill': Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(height: 10)),
    'a borderless ShapeDecoration': Container(
        decoration:
            const ShapeDecoration(color: Colors.white, shape: StadiumBorder())),
    'a list separator': const Divider(height: 1, thickness: 0),
    'buttons keep their own outline':
        OutlinedButton(onPressed: () {}, child: const Text('ok')),
  };
  for (final MapEntry(key: name, value: widget) in accepted.entries) {
    testWidgets('card_chrome passes $name', (tester) async {
      await _pump(tester, Center(child: widget));
      expect(_fails(() => expectNoCardChrome(find.byType(Scaffold), name)),
          isFalse);
    });
  }

  testWidgets('a page of Materials only is still walked', (tester) async {
    await _pump(tester, const Material(child: SizedBox(height: 10)));
    expect(_fails(() => expectNoCardChrome(find.byType(Scaffold), 'materials')),
        isFalse,
        reason: 'the Scaffold page and the flat Material count as walked');
  });

  testWidgets('excluded subtrees are skipped', (tester) async {
    await _pump(
      tester,
      Container(
        key: const ValueKey('owned-elsewhere'),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: const SizedBox(height: 10),
      ),
    );
    expect(
        _fails(() => expectNoCardChrome(find.byType(Scaffold), 'excluded',
            exclude: [find.byKey(const ValueKey('owned-elsewhere'))])),
        isFalse,
        reason: 'a border inside an excluded subtree is not this screen\'s');
  });
}
