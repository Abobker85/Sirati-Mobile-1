import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/skills_languages_editor.dart';
import 'package:sirati/shared/models/cv_document.dart';

import '_harness.dart';

void main() {
  // Invariant: clearing the project URL field clears the stored URL,
  // whatever the URL was and however it was cleared.
  for (final url in ['https://github.com/x', 'http://a.b/c?d=1', 'h']) {
    for (final stepwise in [true, false]) {
      testWidgets('clearing URL "$url" (stepwise=$stepwise) clears stored url',
          (tester) async {
        final controller = makeController(CvDocument(
          exportLanguage: 'ar', summary: LocalizedText(),
          projects: [
            Project(id: 'p1', title: const LocalizedText(ar: 'مشروع'), url: url),
          ],
        ));
        await pumpEditor(tester, controller,
            () => SkillsLanguagesEditor(controller: controller));

        var current = url;
        if (stepwise) {
          while (current.isNotEmpty) {
            final next = current.substring(0, current.length - 1);
            await tester.enterText(fieldWithText(current), next);
            await tester.pump();
            current = next;
          }
        } else {
          await tester.enterText(fieldWithText(current), '');
          await tester.pump();
        }

        expect(controller.document.projects!.single.url, isNull);
        expect(controller.document.projects!.single.toJson()['url'], isNull);
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }
}
