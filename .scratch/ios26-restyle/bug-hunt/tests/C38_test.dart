import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

void main() {
  for (final arabic in const [true, false]) {
    testWidgets('app bar reserves the height the segmented bar paints (arabic=$arabic)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final failures = <String>[];
      // Sweep label lengths across the wrap boundary.
      for (var a = 4; a <= 40; a++) {
        final tabs = [
          AppSegmentedTab(label: 'x' * a),
          const AppSegmentedTab(label: 'yyyy yyyy'),
          const AppSegmentedTab(label: 'zz'),
        ];
        final bar = AppSegmentedTabBar(
            tabs: tabs, textScaler: TextScaler.noScaling);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightFor(arabic: arabic),
          home: Directionality(
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            child: DefaultTabController(
              length: 3,
              child: Scaffold(appBar: AppBar(bottom: bar)),
            ),
          ),
        ));
        await tester.pump();
        final painted = tester.getSize(find.byType(SegmentedTrack)).height +
            bar.padding.vertical;
        if (painted > bar.preferredSize.height + 0.001) {
          failures.add('a=$a painted=$painted reserved=${bar.preferredSize.height}');
        }
      }
      expect(failures, isEmpty);
    });
  }
}
