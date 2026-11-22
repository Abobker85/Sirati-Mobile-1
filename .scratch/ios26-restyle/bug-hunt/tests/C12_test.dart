import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/experience_education_editor.dart';
import 'package:sirati/shared/models/cv_document.dart';

import '_harness.dart';

void main() {
  // Invariant: editing one field never erases the English side of any other
  // field, for arbitrary English values (e.g. a CV imported in English).
  for (final en in ['Riyadh', 'New York, NY', 'B.Sc. Computer Science']) {
    testWidgets('editing experience title keeps location.en "$en"',
        (tester) async {
      final doc = CvDocument(
        exportLanguage: 'en', summary: const LocalizedText(),
        experience: [
          ExperienceEntry(
            id: 'e1',
            title: const LocalizedText(ar: 'مهندس', en: 'Engineer'),
            company: const LocalizedText(ar: 'شركة', en: 'Acme'),
            location: LocalizedText(en: en),
            startDate: '2020',
            isCurrent: true,
          ),
        ],
      );
      final controller = makeController(doc);
      await pumpEditor(tester, controller,
          () => ExperienceEducationEditor(controller: controller));
      await tester.enterText(fieldWithText('مهندس'), 'مهندس أول');
      await tester.pump();
      final e = controller.document.experience!.single;
      expect(e.title.ar, 'مهندس أول');
      expect(e.location.en, en);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('editing institution keeps degree/field .en "$en"',
        (tester) async {
      final doc = CvDocument(
        exportLanguage: 'en', summary: const LocalizedText(),
        education: [
          EducationEntry(
            id: 'ed1',
            institution: const LocalizedText(ar: 'جامعة', en: 'Uni'),
            degree: LocalizedText(en: en),
            fieldOfStudy: LocalizedText(en: '$en field'),
            startDate: '2015',
          ),
        ],
      );
      final controller = makeController(doc);
      await pumpEditor(tester, controller,
          () => ExperienceEducationEditor(controller: controller));
      await tester.enterText(fieldWithText('جامعة'), 'جامعة الملك');
      await tester.pump();
      final e = controller.document.education!.single;
      expect(e.institution.ar, 'جامعة الملك');
      expect(e.degree.en, en);
      expect(e.fieldOfStudy.en, '$en field');
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
