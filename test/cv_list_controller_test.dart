import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/models/generated_cv.dart';
import 'package:sirati/state/async_state.dart';
import 'package:sirati/state/cv_list_controller.dart';

void main() {
  group('CvListController', () {
    test('starts in loading, then success', () async {
      final cvs = [_cv(id: 3)];
      final controller = CvListController(loader: () async => cvs);

      expect(controller.state, isA<AsyncLoading<List<GeneratedCv>>>());

      await controller.load();

      expect(controller.state, isA<AsyncSuccess<List<GeneratedCv>>>());
      expect(controller.state.dataOrNull, hasLength(1));
      expect(controller.state.dataOrNull!.single.id, 3);
    });

    test('surfaces errors without throwing', () async {
      final controller = CvListController(
        loader: () async => throw StateError('offline'),
      );

      await controller.load();

      expect(controller.state, isA<AsyncFailure<List<GeneratedCv>>>());
      expect(controller.state.errorOrNull, isA<StateError>());
      expect(controller.state.dataOrNull, isNull);
    });

    test('ignores a stale load when a newer load starts', () async {
      var calls = 0;
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();

      final controller = CvListController(
        loader: () async {
          calls++;
          if (calls == 1) {
            firstEntered.complete();
            await releaseFirst.future;
            return [_cv(id: 1)];
          }
          return [_cv(id: 2)];
        },
      );

      final first = controller.load();
      await firstEntered.future;
      await controller.load();
      releaseFirst.complete();
      await first;

      expect(controller.state, isA<AsyncSuccess<List<GeneratedCv>>>());
      expect(controller.state.dataOrNull!.single.id, 2);
    });

    test('does not throw or notify if disposed while load is in flight',
        () async {
      final releaseLoader = Completer<void>();
      final controller = CvListController(
        loader: () async {
          await releaseLoader.future;
          return [_cv(id: 1)];
        },
      );

      final loadFuture = controller.load();
      controller.dispose();
      releaseLoader.complete();
      await expectLater(loadFuture, completes);
    });
  });
}

GeneratedCv _cv({required int id}) {
  return GeneratedCv(
    id: id,
    fullName: 'Sara',
    email: 'sara@example.com',
    phone: null,
    linkedin: null,
    location: null,
    targetJobTitle: 'Developer',
    jobDescriptionInput: null,
    language: 'en',
    summaryInput: null,
    skillsInput: 'Dart',
    experienceInput: 'Built apps',
    educationInput: 'BSc',
    certificationsInput: null,
    generatedMarkdown: '## Experience',
    aiStatus: 'completed',
    aiOutput: null,
    aiError: null,
    scoreTotal: 80,
    grade: 'A',
    criteria: const [],
    pdfUrl: null,
    templatePdfUrl: null,
    createdAt: DateTime.utc(2026, 9, 1),
  );
}
