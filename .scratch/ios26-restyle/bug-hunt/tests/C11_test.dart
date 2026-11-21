import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/experience_education_editor.dart';
import 'package:sirati/shared/models/cv_document.dart';

import '_harness.dart';

EditableText editable(WidgetTester t, String text) =>
    t.widget<EditableText>(fieldWithText(text));

void main() {
  Future<void> typeTwoChars(WidgetTester tester, String start) async {
    await tester.showKeyboard(fieldWithText(start));
    await tester.pump();
    final stateBefore = tester.state(fieldWithText(start));
    expect(editable(tester, start).focusNode.hasFocus, isTrue);

    await tester.enterText(fieldWithText(start), '${start}2');
    await tester.pump();

    // Focus and the field's State must survive one keystroke.
    expect(editable(tester, '${start}2').focusNode.hasFocus, isTrue,
        reason: 'focus lost after one character');
    expect(identical(tester.state(fieldWithText('${start}2')), stateBefore),
        isTrue,
        reason: 'field State was recreated after one character');
  }

  testWidgets('experience tile keeps focus while typing', (tester) async {
    final controller = makeController(const CvDocument(
      exportLanguage: 'ar', summary: LocalizedText(),
      experience: [
        ExperienceEntry(
            id: 'e1',
            title: LocalizedText(ar: 'Engineer'),
            company: LocalizedText(ar: 'Acme'),
            startDate: '2020',
            isCurrent: true),
      ],
    ));
    await pumpEditor(tester, controller,
        () => ExperienceEducationEditor(controller: controller));
    await typeTwoChars(tester, 'Engineer');
    expect(controller.document.experience!.single.title.ar, 'Engineer2');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('education tile keeps focus while typing', (tester) async {
    final controller = makeController(const CvDocument(
      exportLanguage: 'ar', summary: LocalizedText(),
      education: [
        EducationEntry(
            id: 'ed1',
            institution: LocalizedText(ar: 'جامعة'),
            degree: LocalizedText(ar: 'Bachelor'),
            startDate: '2015'),
      ],
    ));
    await pumpEditor(tester, controller,
        () => ExperienceEducationEditor(controller: controller));
    await typeTwoChars(tester, 'Bachelor');
    await tester.pump(const Duration(seconds: 2));
  });
}
