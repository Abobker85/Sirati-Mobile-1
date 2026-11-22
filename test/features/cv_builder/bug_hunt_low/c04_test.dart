import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// When an AI enhancement lands, the beat goes up and the result card appears.
/// The framed field must keep its state (focus, keyboard) and the frame must
/// resize smoothly around the new card, on the first beat and on later ones.
void main() {
  Widget appOf(TextEditingController controller, int beat,
          {required bool showResult}) =>
      MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: AiEnhancedBeatFrame(
              key: const Key('frame'),
              beat: beat,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: controller),
                  if (showResult) const SizedBox(height: 200, width: 10),
                ],
              ),
            ),
          ),
        ),
      );

  for (final from in [0, 1, 5]) {
    testWidgets('C04: beat $from -> ${from + 1} keeps field state and animates',
        (tester) async {
      final controller = TextEditingController(text: 'Some experience text');
      addTearDown(controller.dispose);
      bool fieldFocused() => tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .hasFocus;
      Widget app(int beat, {required bool showResult}) =>
          appOf(controller, beat, showResult: showResult);
      await tester.pumpWidget(app(from, showResult: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(fieldFocused(), isTrue);
      final stateBefore = tester.state(find.byType(EditableText));
      final heightBefore =
          tester.getSize(find.byKey(const Key('frame'))).height;

      await tester.pumpWidget(app(from + 1, showResult: true));
      await tester.pump(const Duration(milliseconds: 16));

      expect(fieldFocused(), isTrue, reason: 'field lost focus');
      expect(identical(tester.state(find.byType(EditableText)), stateBefore),
          isTrue,
          reason: 'field subtree was rebuilt');
      final heightMid = tester.getSize(find.byKey(const Key('frame'))).height;
      expect(heightMid, lessThan(heightBefore + 200),
          reason: 'frame jumped to the final size instead of resizing');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  }
}
