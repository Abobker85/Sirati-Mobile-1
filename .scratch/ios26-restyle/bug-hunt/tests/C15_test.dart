import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Widget _host(TextEditingController ctrl, {required bool enabled, VoidCallback? onChanged}) =>
    MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SkillChipsSelector(
            controller: ctrl,
            targetJobTitle: '',
            english: true,
            allJobTitles: const [],
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
      ),
    );

void main() {
  // Invariant: while the selector is disabled (AI enhancement running), no
  // control in it may change the shared skills value.
  for (final initial in ['Dart, Flutter', 'SQL', 'A, B, C, D']) {
    testWidgets('disabled selector: Clear all leaves "$initial" untouched',
        (tester) async {
      final ctrl = TextEditingController(text: initial);
      var changes = 0;
      await tester.pumpWidget(
          _host(ctrl, enabled: false, onChanged: () => changes++));
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final clear = find.text(l.cvSkillsClearAll);
      expect(clear, findsOneWidget);
      await tester.tap(clear, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(ctrl.text, initial);
      expect(changes, 0);
    });
  }

  testWidgets('enabled selector: Clear all still clears', (tester) async {
    final ctrl = TextEditingController(text: 'Dart, Flutter');
    await tester.pumpWidget(_host(ctrl, enabled: true));
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l.cvSkillsClearAll));
    await tester.pumpAndSettle();
    expect(ctrl.text, '');
  });
}
