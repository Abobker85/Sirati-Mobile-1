import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Nearest painted background behind [element]: a decorated box, a
/// Material, or the button's own resolved fill.
Color _backgroundOf(Element element) {
  Color? found;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is DecoratedBox) {
      final d = widget.decoration;
      if (d is BoxDecoration && d.color != null) found = d.color;
    } else if (widget is Material &&
        widget.type != MaterialType.transparency &&
        widget.color != null) {
      found = widget.color;
    } else if (widget is ButtonStyleButton) {
      found = widget.style?.backgroundColor?.resolve({});
    }
    return found == null;
  });
  return found ?? fail('no painted background above ${element.widget}');
}

Color? _foregroundOf(Element element) {
  final text = element.widget as Text;
  // Button labels take their colour from the ambient DefaultTextStyle.
  return text.style?.color ?? DefaultTextStyle.of(element).style.color;
}

void main() {
  for (final (mode, theme) in [
    ('light', AppTheme.lightFor(arabic: false)),
    ('dark', AppTheme.darkFor(arabic: false)),
  ]) {
    for (final draft in [false, true]) {
      testWidgets('CV card texts are AA in $mode mode (draft: $draft)',
          (tester) async {
        final item = CvListItem.fromJson({
          'id': 1,
          'title': 'Backend Developer CV',
          'badge': draft ? 'Draft' : 'ATS 92',
          'is_draft': draft,
          'updated_label': '2 days ago',
        });
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ListView(
              children: [
                CvDocumentCard(
                  item: item,
                  onEdit: () {},
                  onDelete: () {},
                  onDownload: () {},
                ),
                CreateCvCard(english: true, onTap: () {}),
              ],
            ),
          ),
        ));

        final texts = find.byType(Text).evaluate().toList();
        expect(texts, isNotEmpty);
        for (final element in texts) {
          final text = element.widget as Text;
          final background = _backgroundOf(element);
          final foreground =
              Color.alphaBlend(_foregroundOf(element)!, background);
          final ratio =
              foreground.computeLuminance() > background.computeLuminance()
                  ? (foreground.computeLuminance() + .05) /
                      (background.computeLuminance() + .05)
                  : (background.computeLuminance() + .05) /
                      (foreground.computeLuminance() + .05);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '"${text.data}" in $mode (draft: $draft)',
          );
        }
      });
    }
  }
}
