import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bridges Riverpod's [AsyncValue] to the [AsyncSnapshot] shape that
/// `AppAsyncBody` and older FutureBuilder-based widgets expect, so screens
/// can move to providers without rewriting their loading/error UI.
extension AsyncValueSnapshot<T> on AsyncValue<T> {
  AsyncSnapshot<T> toSnapshot() {
    // A failed reload is an error, not the previous data: Riverpod keeps
    // that data on the error, but showing it would present stale results
    // as current with no way to retry. Retrying with no data keeps the
    // error up (its retry UI shows progress) rather than a loader.
    if (hasError && !(isLoading && hasValue)) {
      return AsyncSnapshot<T>.withError(
        ConnectionState.done,
        error!,
        stackTrace ?? StackTrace.empty,
      );
    }
    if (hasValue) {
      // A reload in flight keeps the previous data visible, like
      // FutureBuilder does when its future is swapped.
      return AsyncSnapshot<T>.withData(
        isLoading ? ConnectionState.waiting : ConnectionState.done,
        value as T,
      );
    }
    return AsyncSnapshot<T>.waiting();
  }
}
