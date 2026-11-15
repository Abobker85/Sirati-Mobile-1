import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/storage/user_scoped_storage.dart';

/// Remembers, on this device, the last ATS score for each CV and job title,
/// so a rescan can show how far the score moved since last time.
///
/// It is account data: stored under [UserScopedKeys.lastScanScoresKey], so a
/// sign-out removes it. Local only; nothing is sent to the server.
abstract final class LastScanScores {
  /// Oldest entries are dropped past this many.
  static const maxEntries = 50;

  /// The memory key for a scan, or null when the scan cannot be matched to
  /// an earlier one (no job title, or no CV to name).
  ///
  /// A saved CV is matched by its id; an uploaded file by its name. The job
  /// title is part of the key, because the same CV scores differently
  /// against different jobs.
  static String? keyFor({
    int? savedCvId,
    String? fileName,
    required String jobTitle,
  }) {
    final title = _normalise(jobTitle);
    if (title.isEmpty) return null;
    if (savedCvId != null) return 'saved:$savedCvId|$title';
    final file = _normalise(fileName ?? '');
    if (file.isEmpty) return null;
    return 'file:$file|$title';
  }

  static String _normalise(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// The score last stored under [key], or null when there is none (or
  /// storage failed: the rescan then just shows no comparison).
  static Future<int?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _read(prefs.getString(UserScopedKeys.lastScanScoresKey))[key];
    } catch (_) {
      return null;
    }
  }

  /// Stores [score] under [key] as the newest entry. A failure is ignored:
  /// the next rescan just shows no comparison.
  static Future<void> write(String key, int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = _read(prefs.getString(UserScopedKeys.lastScanScoresKey));
      scores.remove(key);
      scores[key] = score;
      while (scores.length > maxEntries) {
        scores.remove(scores.keys.first);
      }
      await prefs.setString(
        UserScopedKeys.lastScanScoresKey,
        jsonEncode(scores),
      );
    } catch (_) {
      // Keep going without it.
    }
  }

  static Map<String, int> _read(String? raw) {
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is int) '${e.key}': e.value as int,
      };
    } catch (_) {
      return {};
    }
  }
}
