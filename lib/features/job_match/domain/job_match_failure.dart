import 'package:sirati/core/network/api_exception.dart';

/// Which Job Match request failed; the same status means different things
/// for create and apply (e.g. 409).
enum JobMatchOperation { create, refresh, apply }

enum JobMatchFailureKind {
  /// 402 — not subscribed.
  subscriptionRequired,

  /// 429 — daily Job Match quota or the AI request limit.
  limitReached,

  /// 409 on create — the retry key belongs to a different request.
  conflict,

  /// 409 on apply — the CV or advice changed since the match was made.
  stale,

  /// 422 on create — the saved CV is longer than Job Match accepts.
  cvTooLong,

  /// 422 on create — the job description was rejected.
  invalidJobDescription,

  /// 422 on apply — a selected suggestion cannot be applied automatically.
  invalidSelection,

  /// 503 — Job Match is switched off or misconfigured server-side.
  unavailable,

  /// 404 — the match or CV no longer exists.
  notFound,

  /// Offline / timeout.
  network,

  /// Other 5xx.
  server,

  unknown,
}

class JobMatchFailure {
  const JobMatchFailure(this.kind, {this.cause});

  final JobMatchFailureKind kind;
  final Object? cause;

  bool get retryable =>
      kind == JobMatchFailureKind.network || kind == JobMatchFailureKind.server;

  /// Whether the failure means the user's entitlement changed and the
  /// screen should re-read it from the server.
  bool get affectsEntitlement =>
      kind == JobMatchFailureKind.subscriptionRequired ||
      kind == JobMatchFailureKind.unavailable;

  factory JobMatchFailure.from(Object error, JobMatchOperation operation) {
    if (error is! ApiException) {
      return JobMatchFailure(JobMatchFailureKind.unknown, cause: error);
    }
    if (error.type == ApiErrorType.network ||
        error.type == ApiErrorType.timeout) {
      return JobMatchFailure(JobMatchFailureKind.network, cause: error);
    }
    final kind = switch (error.statusCode) {
      402 => JobMatchFailureKind.subscriptionRequired,
      429 => JobMatchFailureKind.limitReached,
      409 => operation == JobMatchOperation.apply
          ? JobMatchFailureKind.stale
          : JobMatchFailureKind.conflict,
      422 => switch (operation) {
          JobMatchOperation.apply => JobMatchFailureKind.invalidSelection,
          _ when error.errors.containsKey('generated_cv_id') =>
            JobMatchFailureKind.cvTooLong,
          _ => JobMatchFailureKind.invalidJobDescription,
        },
      503 => JobMatchFailureKind.unavailable,
      404 => JobMatchFailureKind.notFound,
      final int status when status >= 500 => JobMatchFailureKind.server,
      _ => JobMatchFailureKind.unknown,
    };
    return JobMatchFailure(kind, cause: error);
  }
}
