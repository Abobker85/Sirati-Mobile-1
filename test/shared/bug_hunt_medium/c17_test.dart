import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

void main() {
  for (final labels in [
    ['One', 'Two'],
    ['يومي', 'أسبوعي', 'شهري'],
  ]) {
    testWidgets('assistive tech can select each segment of $labels',
        (tester) async {
      final handle = tester.ensureSemantics();
      int value = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => MotionSegmentedPill<int>(
                options: [
                  for (var i = 0; i < labels.length; i++)
                    MotionSegmentOption(value: i, label: labels[i]),
                ],
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      for (var i = labels.length - 1; i >= 1; i--) {
        final node = tester.getSemantics(find.bySemanticsLabel(labels[i]));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue,
            reason: 'segment "${labels[i]}" exposes no tap action');
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(value, i);
      }
      handle.dispose();
    });
  }
}
