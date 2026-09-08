import 'package:flutter/material.dart';

/// Build flavor selected at compile time via `--dart-define=FLAVOR=...`
/// or by a dedicated entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`).
enum AppFlavor {
  dev,
  staging,
  prod;

  bool get isProd => this == AppFlavor.prod;

  bool get showBanner => this != AppFlavor.prod;

  String get label => switch (this) {
        AppFlavor.dev => 'DEV',
        AppFlavor.staging => 'STAGING',
        AppFlavor.prod => 'PROD',
      };

  /// Ribbon color for the on-device [FlavorBanner]. Prod never renders it.
  Color get bannerColor => switch (this) {
        AppFlavor.dev => const Color(0xFFF9A825),
        AppFlavor.staging => const Color(0xFF1565C0),
        AppFlavor.prod => const Color(0x00000000),
      };

  static AppFlavor? _current;
  static bool _bootstrapped = false;

  static AppFlavor get current => _current ?? AppFlavor.prod;

  /// Pin the flavor from a dedicated entrypoint. Wins over `--dart-define`.
  static void bootstrap(AppFlavor flavor) {
    _current = flavor;
    _bootstrapped = true;
  }

  /// Read `FLAVOR` from `--dart-define`. No-op if [bootstrap] already ran.
  static void ensureInitialized() {
    if (_bootstrapped) return;
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
    _current = switch (raw.trim().toLowerCase()) {
      'dev' => AppFlavor.dev,
      'staging' => AppFlavor.staging,
      'prod' => AppFlavor.prod,
      _ => AppFlavor.prod,
    };
    _bootstrapped = true;
  }

  @visibleForTesting
  static void resetForTest([AppFlavor? flavor]) {
    _current = flavor;
    _bootstrapped = flavor != null;
  }
}
