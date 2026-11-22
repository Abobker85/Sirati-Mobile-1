import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components.dart';

int _count(String haystack, String needle) =>
    needle.allMatches(haystack).length;

void main() {
  for (final c in const [
    ['No CVs yet', 'Create your first one'],
    ['لا توجد سير', 'أنشئ واحدة'],
    ['Nothing here', null],
  ]) {
    testWidgets('empty state title is announced once: ${c[0]}', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.description_outlined,
            title: c[0]!,
            subtitle: c[1],
            scrollable: false,
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      final labels = <String>[];
      void visit(SemanticsNode n) {
        labels.add(n.label);
        n.visitChildren((ch) {
          visit(ch);
          return true;
        });
      }
      visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
      final all = labels.join('\n');
      expect(_count(all, c[0]!), 1, reason: 'labels: $labels');
      if (c[1] != null) expect(_count(all, c[1]!), 1, reason: 'labels: $labels');
      handle.dispose();
    });
  }
}
