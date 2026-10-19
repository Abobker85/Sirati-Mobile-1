import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/utils/idempotency_key.dart';
import 'package:sirati/features/job_match/data/job_match_repository.dart';
import 'package:sirati/features/job_match/domain/job_match.dart';
import 'package:sirati/features/job_match/domain/job_match_entitlement.dart';
import 'package:sirati/features/job_match/domain/job_match_failure.dart';
import 'package:sirati/features/job_match/domain/job_match_input.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';

/// Server entitlement for Job Match (`/auth/me` → `subscription`).
/// Never derived from a local premium flag. Errors surface at once (no
/// automatic retry) so the screen can offer its own Retry.
final jobMatchEntitlementProvider =
    FutureProvider.autoDispose<JobMatchEntitlement>(
  (ref) async {
    final user = await ref.read(authApiServiceProvider).me();
    return JobMatchEntitlement.fromSubscription(user?.subscription);
  },
  retry: (_, __) => null,
);

/// The user's saved CVs to match against.
final jobMatchSavedCvsProvider =
    FutureProvider.autoDispose<List<GeneratedCv>>(
  (ref) => ref.read(jobMatchRepositoryProvider).savedCvs(),
  retry: (_, __) => null,
);

/// Waits between automatic refreshes while AI advice is pending.
///
/// `GET /job-matches/{id}` shares the `ai-heavy` limiter (10/hour) with
/// create and apply, so the schedule is short and sparse: after it runs out
/// the screen reports "still processing" and refreshes only on request.
final jobMatchPollScheduleProvider = Provider<List<Duration>>(
  (ref) => const [
    Duration(seconds: 6),
    Duration(seconds: 10),
    Duration(seconds: 15),
    Duration(seconds: 20),
  ],
);

enum JobMatchPollPhase {
  /// Nothing pending.
  idle,

  /// Automatic refreshes are running.
  polling,

  /// Advice is still pending after the automatic refreshes (or a refresh
  /// failed); the score stays valid and the user can check again.
  stillProcessing,
}

class JobMatchState {
  const JobMatchState({
    this.submitting = false,
    this.match,
    this.pollPhase = JobMatchPollPhase.idle,
    this.refreshFailure,
    this.selected = const {},
    this.applying = false,
    this.retryingAdvice = false,
    this.retryFailure,
  });

  final bool submitting;
  final JobMatch? match;
  final JobMatchPollPhase pollPhase;

  /// Why the last refresh failed, when it did.
  final JobMatchFailure? refreshFailure;
  final Set<String> selected;
  final bool applying;
  final bool retryingAdvice;
  final JobMatchFailure? retryFailure;

  JobMatchState copyWith({
    bool? submitting,
    JobMatch? match,
    JobMatchPollPhase? pollPhase,
    JobMatchFailure? refreshFailure,
    bool clearRefreshFailure = false,
    Set<String>? selected,
    bool? applying,
    bool? retryingAdvice,
    JobMatchFailure? retryFailure,
    bool clearRetryFailure = false,
  }) =>
      JobMatchState(
        submitting: submitting ?? this.submitting,
        match: match ?? this.match,
        pollPhase: pollPhase ?? this.pollPhase,
        refreshFailure:
            clearRefreshFailure ? null : (refreshFailure ?? this.refreshFailure),
        selected: selected ?? this.selected,
        applying: applying ?? this.applying,
        retryingAdvice: retryingAdvice ?? this.retryingAdvice,
        retryFailure:
            clearRetryFailure ? null : (retryFailure ?? this.retryFailure),
      );
}

sealed class JobMatchApplyOutcome {
  const JobMatchApplyOutcome();
}

final class JobMatchApplied extends JobMatchApplyOutcome {
  const JobMatchApplied(this.cv);

  /// The new tailored CV copy; the source CV is unchanged.
  final GeneratedCv cv;
}

final class JobMatchApplyFailed extends JobMatchApplyOutcome {
  const JobMatchApplyFailed(this.failure);

  final JobMatchFailure failure;
}

final jobMatchControllerProvider =
    NotifierProvider.autoDispose<JobMatchController, JobMatchState>(
  JobMatchController.new,
);

/// Submit → refresh while AI advice is pending → select → apply.
class JobMatchController extends Notifier<JobMatchState> {
  /// Bumped to abandon an in-flight refresh loop.
  int _pollGeneration = 0;
  Timer? _pollTimer;
  Completer<bool>? _pollWait;

  /// Reused while the request is unchanged so a retry (or a second tap)
  /// replays the same match instead of spending another quota unit.
  String? _idempotencyKey;
  String? _keyFingerprint;

  @override
  JobMatchState build() {
    ref.onDispose(_stopPolling);
    return const JobMatchState();
  }

  /// Abandons the refresh loop and cancels its pending wait.
  void _stopPolling() {
    _pollGeneration++;
    _pollTimer?.cancel();
    _pollTimer = null;
    final wait = _pollWait;
    _pollWait = null;
    if (wait != null && !wait.isCompleted) wait.complete(false);
  }

  /// Completes with false when polling was stopped before [delay] elapsed.
  Future<bool> _sleep(Duration delay) {
    final wait = Completer<bool>();
    _pollWait = wait;
    _pollTimer = Timer(delay, () {
      if (!wait.isCompleted) wait.complete(true);
    });
    return wait.future;
  }

  JobMatchRepository get _repository => ref.read(jobMatchRepositoryProvider);

  /// Creates the match. Returns null on success ([JobMatchState.match] is
  /// set and refreshing has started) or the failure to show.
  Future<JobMatchFailure?> submit({
    required int generatedCvId,
    required String jobDescription,
    String targetJobTitle = '',
  }) async {
    if (state.submitting) return null;
    if (JobMatchInput.validate(
          description: jobDescription,
          title: targetJobTitle,
        ) !=
        null) {
      return const JobMatchFailure(JobMatchFailureKind.invalidJobDescription);
    }

    final jd = jobDescription.trim();
    final title = targetJobTitle.trim();
    final fingerprint = '$generatedCvId\u0000$jd\u0000$title';
    if (fingerprint != _keyFingerprint) {
      _keyFingerprint = fingerprint;
      _idempotencyKey = newIdempotencyKey();
    }

    _stopPolling();
    state = state.copyWith(submitting: true, retryingAdvice: false);
    try {
      final match = await _repository.create(
        generatedCvId: generatedCvId,
        jobDescription: jd,
        targetJobTitle: title.isEmpty ? null : title,
        idempotencyKey: _idempotencyKey!,
      );
      if (!ref.mounted) return null;
      ref.invalidate(jobMatchEntitlementProvider);
      state = JobMatchState(
        match: match,
        pollPhase:
            match.aiPending ? JobMatchPollPhase.polling : JobMatchPollPhase.idle,
      );
      if (match.aiPending) unawaited(_pollUntilSettled());
      return null;
    } catch (error) {
      final failure = JobMatchFailure.from(error, JobMatchOperation.create);
      if (failure.kind == JobMatchFailureKind.conflict) {
        _keyFingerprint = null;
      }
      if (ref.mounted) {
        state = state.copyWith(
          submitting: false,
          // Starting a replacement stopped the previous polling loop. If
          // creation fails, that previous result must offer Check again.
          pollPhase: (state.match?.aiPending ?? false)
              ? JobMatchPollPhase.stillProcessing
              : JobMatchPollPhase.idle,
        );
      }
      return failure;
    }
  }

  Future<void> _pollUntilSettled() async {
    _stopPolling();
    final generation = _pollGeneration;
    final schedule = ref.read(jobMatchPollScheduleProvider);
    for (final delay in schedule) {
      if (!await _sleep(delay)) return;
      if (!ref.mounted || generation != _pollGeneration) return;
      if (!await _refreshOnce(generation)) return;
      if (!ref.mounted || generation != _pollGeneration) return;
      if (state.pollPhase != JobMatchPollPhase.polling) return;
    }
    if (ref.mounted && generation == _pollGeneration) {
      state = state.copyWith(pollPhase: JobMatchPollPhase.stillProcessing);
    }
  }

  /// Reuses the existing match and the initial advice polling flow.
  Future<void> retryAdvice() async {
    final match = state.match;
    if (match == null ||
        match.aiStatus != AiStatus.failed ||
        state.retryingAdvice ||
        state.submitting) {
      return;
    }
    _stopPolling();
    final generation = _pollGeneration;
    state = state.copyWith(retryingAdvice: true, clearRetryFailure: true);
    try {
      final retried = await _repository.retryAdvice(match.id);
      if (!ref.mounted || generation != _pollGeneration) return;
      ref.invalidate(jobMatchEntitlementProvider);
      state = JobMatchState(
        match: retried,
        pollPhase: retried.aiPending
            ? JobMatchPollPhase.polling
            : JobMatchPollPhase.idle,
      );
      if (retried.aiPending) unawaited(_pollUntilSettled());
    } catch (error) {
      if (!ref.mounted || generation != _pollGeneration) return;
      final failure = JobMatchFailure.from(error, JobMatchOperation.retryAdvice);
      if (failure.affectsEntitlement) {
        ref.invalidate(jobMatchEntitlementProvider);
      }
      state = state.copyWith(retryingAdvice: false, retryFailure: failure);
    }
  }

  /// One refresh. Returns false when the loop should stop (failure).
  Future<bool> _refreshOnce(int generation) async {
    final current = state.match;
    if (current == null) return false;
    try {
      final match = await _repository.fetch(current.id);
      if (!ref.mounted || generation != _pollGeneration) return false;
      state = state.copyWith(
        match: match,
        pollPhase: match.aiPending ? null : JobMatchPollPhase.idle,
        clearRefreshFailure: true,
        selected: _keepSelectable(state.selected, match),
      );
      return true;
    } catch (error) {
      if (!ref.mounted || generation != _pollGeneration) return false;
      state = state.copyWith(
        pollPhase: JobMatchPollPhase.stillProcessing,
        refreshFailure: JobMatchFailure.from(error, JobMatchOperation.refresh),
      );
      return false;
    }
  }

  /// User-requested refresh after "still processing".
  Future<void> checkAgain() async {
    if (state.match == null || state.pollPhase == JobMatchPollPhase.polling) {
      return;
    }
    _stopPolling();
    final generation = _pollGeneration;
    state = state.copyWith(
      pollPhase: JobMatchPollPhase.polling,
      clearRefreshFailure: true,
    );
    final ok = await _refreshOnce(generation);
    if (!ok || !ref.mounted || generation != _pollGeneration) return;
    if (state.match?.aiPending ?? false) {
      state = state.copyWith(pollPhase: JobMatchPollPhase.stillProcessing);
    }
  }

  void toggle(String key) {
    final match = state.match;
    if (match == null || state.applying) return;
    final suggestion = match.suggestions.where((s) => s.key == key).firstOrNull;
    if (suggestion == null || !_canApply(suggestion, match)) return;
    final next = {...state.selected};
    if (!next.remove(key)) next.add(key);
    state = state.copyWith(selected: next);
  }

  Future<JobMatchApplyOutcome?> apply() async {
    final match = state.match;
    if (match == null || state.applying || state.selected.isEmpty) return null;
    // Server order = suggestion order; keeps the request deterministic.
    final keys = [
      for (final s in match.suggestions)
        if (state.selected.contains(s.key) && _canApply(s, match)) s.key,
    ];
    if (keys.isEmpty) return null;

    state = state.copyWith(applying: true);
    try {
      final result = await _repository.apply(match.id, keys);
      MobileContentService.invalidateCvRelated();
      if (ref.mounted) {
        ref.invalidate(jobMatchSavedCvsProvider);
        if (state.match?.id == match.id) {
          state = state.copyWith(
            match: result.match,
            applying: false,
            selected: const {},
          );
        }
      }
      return JobMatchApplied(result.cv);
    } catch (error) {
      if (ref.mounted && state.match?.id == match.id) {
        state = state.copyWith(applying: false);
      }
      return JobMatchApplyFailed(
        JobMatchFailure.from(error, JobMatchOperation.apply),
      );
    }
  }

  static bool _canApply(JobMatchSuggestion s, JobMatch match) =>
      s.selectable && !match.appliedSuggestionKeys.contains(s.key);

  static Set<String> _keepSelectable(Set<String> selected, JobMatch match) {
    if (selected.isEmpty) return selected;
    final allowed = {
      for (final s in match.suggestions)
        if (_canApply(s, match)) s.key,
    };
    return selected.where(allowed.contains).toSet();
  }
}
