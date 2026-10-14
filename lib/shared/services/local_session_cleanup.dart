import 'dart:async';

import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/storage/user_scoped_storage.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/services/session_cache.dart';

typedef LocalCleanupFailure = ({
  String step,
  Object error,
  StackTrace stackTrace,
});

/// Passed to the signed-out route after confirmed account deletion.
class PendingLocalSessionCleanup {
  const PendingLocalSessionCleanup({required this.retry});

  final Future<void> Function() retry;
}

/// Reported only after every local cleanup step has been attempted.
class LocalSessionCleanupException implements Exception {
  LocalSessionCleanupException(Iterable<LocalCleanupFailure> failures)
      : failures = List.unmodifiable(failures);

  final List<LocalCleanupFailure> failures;

  /// Every step was attempted, so no token failure means it was removed.
  bool get tokenCleared => !failures.any((failure) => failure.step == 'token');

  @override
  String toString() =>
      'Local session cleanup failed: ${failures.map((f) => f.step).join(', ')}';
}

/// Shared teardown for logout, account deletion, and session expiry.
class LocalSessionCleanup {
  LocalSessionCleanup({
    required FutureOr<void> Function() clearToken,
    FutureOr<void> Function()? clearSession,
    FutureOr<void> Function()? clearCaches,
    FutureOr<void> Function()? wipeStorage,
    FutureOr<void> Function()? forgetDevice,
    FutureOr<void> Function()? clearAnalytics,
  }) : _steps = [
          (step: 'token', run: clearToken),
          (step: 'session', run: clearSession ?? SessionCache.instance.clear),
          (
            step: 'caches',
            run: clearCaches ?? MobileContentService.clearAllCaches,
          ),
          (step: 'storage', run: wipeStorage ?? wipeUserScopedStorage),
          (
            step: 'device',
            run: forgetDevice ??
                () => NotificationService.instance
                    .forgetDevice(reportFailure: true),
          ),
          (
            step: 'analytics',
            run: clearAnalytics ?? AnalyticsService.clearUser
          ),
        ];

  final List<({String step, FutureOr<void> Function() run})> _steps;

  Future<void> run() async {
    final failures = <LocalCleanupFailure>[];
    for (final action in _steps) {
      try {
        await action.run();
      } catch (error, stackTrace) {
        failures.add((step: action.step, error: error, stackTrace: stackTrace));
      }
    }
    if (failures.isNotEmpty) throw LocalSessionCleanupException(failures);
  }
}
