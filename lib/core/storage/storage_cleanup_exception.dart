typedef StorageCleanupFailure = ({
  String operation,
  Object error,
  StackTrace stackTrace,
});

/// Retains storage failures after all independent removals were attempted.
class StorageCleanupException implements Exception {
  StorageCleanupException(Iterable<StorageCleanupFailure> failures)
      : failures = List.unmodifiable(failures);

  final List<StorageCleanupFailure> failures;

  @override
  String toString() => 'Storage cleanup failed (${failures.length} operations)';
}
