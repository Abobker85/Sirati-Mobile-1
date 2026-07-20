import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/preference_store.dart';

/// App-wide appearance: system / light / dark.
///
/// [themeMode] is observed by [MaterialApp]; [bootstrap] loads storage before
/// [runApp]; [setMode] persists and notifies immediately.
class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static const PreferenceStore _prefs = PreferenceStore();

  static Future<void> bootstrap() async {
    try {
      final stored = await _prefs.readThemeMode();
      themeMode.value = _parse(stored);
    } catch (_) {
      // Keep system default.
    }
  }

  static Future<void> setMode(ThemeMode mode) async {
    final changed = themeMode.value != mode;
    themeMode.value = mode;
    final serialized = _serialize(mode);
    try {
      await _prefs.saveThemeMode(serialized);
    } catch (_) {
      // In-memory still applied.
    }
    if (changed) {
      AnalyticsService.setThemeMode(serialized);
      AnalyticsService.logThemeChanged(mode: serialized);
    }
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
