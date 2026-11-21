import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  for (final english in [true, false]) {
    testWidgets('C01 remove-skill buttons are labelled 48dp targets (en=$english)',
        (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Flutter, Project management, SQL');
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        locale: Locale(english ? 'en' : 'ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SkillChipsSelector(
              controller: controller,
              targetJobTitle: 'Developer',
              english: english,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      final l10n = AppLocalizations.of(tester.element(find.byType(SkillChipsSelector)));
      final targets = [
        ...find.byIcon(Icons.close_rounded).evaluate().map((e) => find.byWidget(e.widget).first),
        find.text(l10n.cvSkillsClearAll),
      ];
      expect(targets.length, 4);
      for (final t in targets) {
        final node = tester.getSemantics(t);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(node.label.isNotEmpty || node.tooltip.isNotEmpty, isTrue, reason: 'unlabelled: $node');
        final size = node.rect.size;
        expect(size.width >= 48 && size.height >= 48, isTrue,
            reason: 'target $size < 48x48: $node');
      }
      handle.dispose();
    });
  }
}
