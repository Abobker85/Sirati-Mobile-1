import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/job_match/domain/job_match.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';

/// Typed access to the Job Match API on top of [CvApiService].
class JobMatchRepository {
  const JobMatchRepository(this._api);

  final CvApiService _api;

  Future<JobMatch> create({
    required int generatedCvId,
    required String jobDescription,
    String? targetJobTitle,
    required String idempotencyKey,
  }) async =>
      JobMatch.fromJson(await _api.createJobMatch(
        generatedCvId: generatedCvId,
        jobDescription: jobDescription,
        targetJobTitle: targetJobTitle,
        idempotencyKey: idempotencyKey,
      ));

  Future<JobMatch> fetch(int id) async =>
      JobMatch.fromJson(await _api.getJobMatch(id));

  Future<JobMatch> retryAdvice(int id) async =>
      JobMatch.fromJson(await _api.retryJobMatchAdvice(id));

  Future<({GeneratedCv cv, JobMatch match})> apply(
    int id,
    List<String> suggestionKeys,
  ) async {
    final result = await _api.applyJobMatchSuggestions(id, suggestionKeys);
    return (cv: result.generatedCv, match: JobMatch.fromJson(result.jobMatch));
  }

  Future<List<GeneratedCv>> savedCvs() => _api.listGeneratedCvs();
}

final jobMatchRepositoryProvider = Provider<JobMatchRepository>(
  (ref) => JobMatchRepository(ref.watch(cvApiServiceProvider)),
);
