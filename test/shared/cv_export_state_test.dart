import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/cv_export_state.dart';
import 'package:sirati/shared/models/generated_cv.dart';

void main() {
  test('malformed export blocks are ignored, not guessed', () {
    for (final raw in <Object?>[
      null,
      'ready',
      42,
      <String, Object?>{},
      {'ready': 'true'},
      {'ready': 1},
      {'ready': null, 'blocked_reason': 'missing_contact'},
    ]) {
      expect(CvExportState.fromJson(raw), isNull, reason: '$raw');
    }
  });

  test('messages fall back to the other language, blanks count as missing',
      () {
    for (final (ar, en) in <(String?, String?)>[
      ('عربي', 'English'),
      ('عربي', null),
      (null, 'English'),
      ('  ', 'English'),
      ('عربي', ''),
      (null, null),
    ]) {
      final state = CvExportState.fromJson({
        'ready': false,
        'blocked_reason': 'missing_contact',
        'message_ar': ar,
        'message_en': en,
      })!;
      String? clean(String? v) => (v?.trim().isEmpty ?? true) ? null : v;
      expect(state.message(english: false), clean(ar) ?? clean(en));
      expect(state.message(english: true), clean(en) ?? clean(ar));
    }
  });

  test('server readiness overrides the AI status in both directions', () {
    for (final status in [
      AiStatus.completed,
      AiStatus.notConfigured,
      AiStatus.failed,
      AiStatus.processing,
      AiStatus.queued,
    ]) {
      for (final ready in <bool?>[true, false, null]) {
        final cv = GeneratedCv.fromJson({
          'id': 1,
          'ai_status': status,
          if (ready != null) 'export': {'ready': ready},
        });
        final legacy = !AiStatus.isPending(status) && status != AiStatus.failed;
        expect(isCvReadyToSend(cv), ready ?? legacy,
            reason: 'status=$status ready=$ready');
      }
    }
  });

  test('My CVs rows carry the same export state', () {
    for (final ready in [true, false]) {
      final item = CvListItem.fromJson({
        'id': 7,
        'title': 'CV',
        'export': {
          'ready': ready,
          'blocked_reason': ready ? null : 'unstructured_experience',
          'message_en': ready ? null : 'Structure your experience.',
        },
      });
      expect(item.export!.ready, ready);
      expect(item.export!.blockedReason,
          ready ? isNull : CvExportState.unstructuredExperience);
    }
    expect(CvListItem.fromJson({'id': 7}).export, isNull);
  });
}
