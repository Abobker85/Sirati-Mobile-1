import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Disk-backed JSON entry for offline last-known mobile content.
class DiskCacheEntry {
  final Map<String, dynamic> data;
  final DateTime savedAt;

  const DiskCacheEntry({required this.data, required this.savedAt});
}

/// Small JSON cache over [SharedPreferences].
///
/// Used only for non-auth content (dashboard, CVs list, news). Never store
/// tokens or session payloads here.
///
/// Envelope: `{ schemaVersion, savedAt, data }`. Schema mismatch → empty.
class DiskCache {
  DiskCache._();

  static final DiskCache instance = DiskCache._();

  /// Bump when the envelope or expected payload shape changes incompatibly.
  static const schemaVersion = 1;

  /// Skip write when serialized envelope exceeds this size (~200KB).
  static const maxBytes = 200 * 1024;

  static const keyPrefix = 'sirati_cache_';

  // ── Namespaced keys ──────────────────────────────────────────────────

  static String dashboardKey(String lang) =>
      '${keyPrefix}dashboard_${_normLang(lang)}';

  /// CVs list is language-scoped so AR/EN payloads never overwrite each other.
  static String cvsKey(String lang) => '${keyPrefix}cvs_${_normLang(lang)}';

  static String newsKey(String lang) => '${keyPrefix}news_${_normLang(lang)}';

  /// Job title taxonomy is language-agnostic (payload includes AR + EN names).
  static String jobTitlesKey() => '${keyPrefix}job_titles';

  static String _normLang(String lang) => lang == 'en' ? 'en' : 'ar';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Returns `{data, savedAt}` or null when missing / corrupt / schema mismatch.
  Future<DiskCacheEntry?> get(String key) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);

      final version = map['schemaVersion'];
      final versionInt =
          version is int ? version : int.tryParse(version?.toString() ?? '');
      if (versionInt != schemaVersion) {
        await prefs.remove(key);
        return null;
      }

      final data = map['data'];
      if (data is! Map) return null;

      final savedAt = DateTime.tryParse(map['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return DiskCacheEntry(
        data: Map<String, dynamic>.from(data),
        savedAt: savedAt.toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Persists [data] under [key]. Oversized or failed writes are swallowed.
  Future<void> put(String key, Map<String, dynamic> data) async {
    try {
      final envelope = <String, dynamic>{
        'schemaVersion': schemaVersion,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      };
      final encoded = jsonEncode(envelope);
      // utf8 length ≈ code-unit length for JSON ASCII; reject large blobs.
      if (encoded.length > maxBytes) return;

      final prefs = await _prefs;
      await prefs.setString(key, encoded);
    } catch (_) {
      // Best-effort offline cache — never block the UI.
    }
  }

  /// Removes every `sirati_cache_*` key (logout / session expiry).
  Future<void> clear() async {
    try {
      final prefs = await _prefs;
      final keys =
          prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
