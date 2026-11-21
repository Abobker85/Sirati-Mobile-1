import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/motion.dart';

class _Step extends StatefulWidget {
  const _Step(this.name, this.log);
  final String name;
  final List<String> log;
  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.log.add('init ${widget.name}');
  }

  @override
  void dispose() {
    widget.log.add('dispose ${widget.name}');
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Material(child: TextField(key: ValueKey('f${widget.name}'), controller: controller));
}

void main() {
  for (final dir in const [TextDirection.ltr, TextDirection.rtl]) {
    for (final forward in const [1, -1]) {
      testWidgets('outgoing step keeps its state while it fades out ($dir, $forward)',
          (tester) async {
        final log = <String>[];
        var step = 0;
        late StateSetter set;
        await tester.pumpWidget(MaterialApp(
          home: Directionality(
            textDirection: dir,
            child: StatefulBuilder(builder: (context, s) {
              set = s;
              return MotionStepSwitcher(
                stepKey: step,
                direction: forward,
                child: _Step('$step', log),
              );
            }),
          ),
        ));
        await tester.enterText(find.byKey(const ValueKey('f0')), 'typed text');
        log.clear();
        set(() => step = 1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        // Step 0 is still on screen fading out: it must be the same state.
        expect(find.byKey(const ValueKey('f0')), findsOneWidget);
        expect(log, isNot(contains('init 0')),
            reason: 'outgoing step was torn down and rebuilt: $log');
        expect(find.text('typed text'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(log.where((e) => e == 'dispose 0').length, 1);
      });
    }
  }
}
