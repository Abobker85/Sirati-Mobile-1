import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';

/// Input contract supplied by the app's My CVs provider at the route boundary.
class SavedAnalysisCv {
  const SavedAnalysisCv({required this.id, required this.title});
  final int id;
  final String title;
}

/// Existing direct screen callers use the same cached saved-CV endpoint.
final analysisSavedCvsProvider = FutureProvider.autoDispose
    .family<List<SavedAnalysisCv>, bool>((ref, english) async {
      final data = await ref.read(mobileContentServiceProvider).myCvs(english);
      final rows = data['items'];
      if (rows is! List) return [];
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          if (int.tryParse('${row['id']}') case final int id when id > 0)
            SavedAnalysisCv(id: id, title: row['title']?.toString() ?? ''),
      ];
    });

final analysisSavedCvProvider = FutureProvider.autoDispose
    .family<GeneratedCv, int>(
      (ref, id) => ref.read(cvApiServiceProvider).getGeneratedCv(id),
    );
