import 'dart:async';

import 'package:sirati/shared/widgets/ambient_motion.dart';

import 'golden/tolerant_golden.dart';

/// Directory-level test config (picked up automatically by `flutter test`).
///
/// Also installed from golden test [setUpAll] — see [installTolerantGoldenComparator].
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Motion that loops by itself never lets "wait until still" finish; the
  // ambient tests switch it back on for themselves.
  AmbientMotion.enabled.value = false;
  installTolerantGoldenComparator(
      precisionTolerance: defaultGoldenPrecisionTolerance);
  await testMain();
}
