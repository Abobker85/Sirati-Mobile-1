import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_input.dart';
import 'package:sirati/shared/widgets/motion.dart';

class _Host extends StatefulWidget {
  const _Host({required this.controller});
  final TextEditingController? controller;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? error;
  void setError(String e) => setState(() => error = e);
  @override
  Widget build(BuildContext context) => AppInput(
        controller: widget.controller,
        label: 'Name',
        errorText: error,
        onChanged: (_) {},
      );
}

Future<void> _pump(WidgetTester tester, TextEditingController? c) async {
  ErrorShake.reset();
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: _Host(controller: c))),
  ));
}

EditableTextState _editable(WidgetTester tester) =>
    tester.state<EditableTextState>(find.byType(EditableText));

void main() {
  for (final typed in ['a', 'hello world', 'مرحبا بك']) {
    testWidgets(
        'field without controller keeps text "$typed" and focus when a new error shakes it',
        (tester) async {
      await _pump(tester, null);
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
      final before = _editable(tester);
      expect(before.widget.focusNode.hasFocus, isTrue);

      tester.state<_HostState>(find.byType(_Host)).setError('Required');
      await tester.pump(); // shake starts
      await tester.pump(const Duration(milliseconds: 60)); // mid-shake
      expect(_editable(tester), same(before),
          reason: 'field state recreated mid-shake');
      expect(_editable(tester).textEditingValue.text, typed);
      expect(_editable(tester).widget.focusNode.hasFocus, isTrue);
      await tester.pumpAndSettle(); // shake ends
      expect(_editable(tester), same(before),
          reason: 'field state recreated at shake end');
      expect(_editable(tester).textEditingValue.text, typed);
      expect(_editable(tester).widget.focusNode.hasFocus, isTrue);
    });
  }

  testWidgets(
      'field with external controller keeps focus when a new error shakes it',
      (tester) async {
    final c = TextEditingController();
    await _pump(tester, c);
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    tester.state<_HostState>(find.byType(_Host)).setError('Bad');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_editable(tester).widget.focusNode.hasFocus, isTrue);
    await tester.pumpAndSettle();
    expect(_editable(tester).widget.focusNode.hasFocus, isTrue);
    expect(c.text, 'abc');
  });
}
