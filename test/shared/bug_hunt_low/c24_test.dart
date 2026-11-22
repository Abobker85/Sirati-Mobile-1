import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

String? _rule(String? v) {
  final t = v ?? '';
  if (t.isEmpty) return 'required';
  if (t.length < 3) return 'too short';
  return null;
}

/// Like login/register: the Form switches to onUserInteraction after submit.
class _Harness extends StatefulWidget {
  const _Harness(this.initial);
  final String initial;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final key = GlobalKey<FormState>();
  bool submitted = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            autovalidateMode: submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(children: [
              AppTextFormField(
                key: const ValueKey('f'),
                initialValue: widget.initial,
                validator: _rule,
              ),
              TextButton(
                onPressed: () => setState(() {
                  submitted = true;
                  key.currentState!.validate();
                }),
                child: const Text('submit'),
              ),
            ]),
          ),
        ),
      );
}

void main() {
  // Arbitrary valid starting texts and invalid edits typed while focused.
  for (final (initial, typed) in [
    ('abc', 'ab'),
    ('Sara Ali', 'S'),
    ('سارة', 'س'),
    ('abcdef', ''),
  ]) {
    testWidgets('typing "$typed" while focused adds no error ($initial)',
        (tester) async {
      await tester.pumpWidget(_Harness(initial));
      await tester.tap(find.text('submit'));
      await tester.pump();
      expect(find.text('required'), findsNothing);
      expect(find.text('too short'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
      final field = find.byType(TextField);
      final focused = tester.widget<TextField>(field).focusNode!.hasFocus;
      expect(focused, isTrue);
      expect(find.text(_rule(typed)!), findsNothing,
          reason: 'a new error must wait for blur or submit');
    });
  }

  testWidgets('typing while focused does not change an existing message',
      (tester) async {
    await tester.pumpWidget(const _Harness(''));
    await tester.tap(find.text('submit'));
    await tester.pump();
    expect(find.text('required'), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(find.text('too short'), findsNothing);
    expect(find.text('required'), findsOneWidget);
  });
}
