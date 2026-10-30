import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/storage/storage_cleanup_exception.dart';

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
/// Envelope: `{ schemaVersion, cacheEpoch, savedAt, data }`.
/// Schema or session epoch mismatch → empty.
class DiskCache {
  DiskCache._();

  static final DiskCache instance = DiskCache._();
  int _generation = 0;
  Future<void>? _pendingClear;

  // Kept outside keyPrefix so wiping entries preserves the session boundary.
  static const _epochKey = 'sirati_content_cache_epoch';

  /// Bump when the envelope or expected payload shape changes incompatibly.
  static const schemaVersion = 2;

  /// Skip write when serialized envelope exceeds this size (~200KB).
  static const maxBytes = 200 * 1024;

  static const keyPrefix = 'sirati_cache_';

  // ── Namespaced keys ──────────────────────────────────────────────────

  static String dashboardKey(String lang) =>
      '${keyPrefix}dashboard_${_normLang(lang)}';

  /// CVs list is language-scoped so payloads never overwrite each other.
  static String cvsKey(String lang) => '${keyPrefix}cvs_${_normLang(lang)}';

  static String newsKey(String lang) => '${keyPrefix}news_${_normLang(lang)}';

  /// Job title taxonomy is language-agnostic (payload includes AR + EN names).
  static String jobTitlesKey() => '${keyPrefix}job_titles';

  /// One key per language code; an unreadable code gets its own `und` key.
  static String _normLang(String lang) => normalizeLanguageCode(lang) ?? 'und';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Returns `{data, savedAt}` or null when missing / corrupt / schema mismatch.
  Future<DiskCacheEntry?> get(String key) async {
    final generation = _generation;
    try {
      await _pendingClear;
      final prefs = await _prefs;
      if (generation != _generation) return null;
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
      // A platform write dispatched before clear may finish after the wipe.
      // Its old epoch stays unreadable, including after preferences reload.
      if (map['cacheEpoch'] != (prefs.getString(_epochKey) ?? '')) return null;

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
    final generation = _generation;
    try {
      await _pendingClear;
      final prefs = await _prefs;
      if (generation != _generation) return;
      final envelope = <String, dynamic>{
        'schemaVersion': schemaVersion,
        'cacheEpoch': prefs.getString(_epochKey) ?? '',
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      };
      final encoded = jsonEncode(envelope);
      // utf8 length ≈ code-unit length for JSON ASCII; reject large blobs.
      if (encoded.length > maxBytes) return;

      await prefs.setString(key, encoded);
    } catch (_) {
      // Best-effort offline cache — never block the UI.
    }
  }

  /// Removes every `sirati_cache_*` key (logout / session expiry).
  Future<void> clear() {
    _generation++;
    final clearing = _clear(_pendingClear);
    _pendingClear = clearing;
    return clearing;
  }

  Future<void> _clear(Future<void>? previous) async {
    // A failed wipe must not prevent a later retry from rotating the epoch.
    var previousFailed = false;
    try {
      await previous;
    } catch (_) {
      previousFailed = true;
    }
    final failures = <StorageCleanupFailure>[];
    try {
      final prefs = await _prefs;
      // Failed removals may already be absent from the preferences memo.
      if (previousFailed) await prefs.reload();
      try {
        final random = Random.secure();
        final epoch = List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        if (!await prefs.setString(_epochKey, epoch)) {
          throw StateError('Cache epoch rotation failed');
        }
      } catch (error, stackTrace) {
        failures
            .add((operation: 'epoch', error: error, stackTrace: stackTrace));
      }
      final keys =
          prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();
      for (final key in keys) {
        try {
          if (!await prefs.remove(key)) {
            throw StateError('Cache entry removal failed');
          }
        } catch (error, stackTrace) {
          failures.add((operation: key, error: error, stackTrace: stackTrace));
        }
      }
    } catch (error, stackTrace) {
      failures.add((operation: 'cache', error: error, stackTrace: stackTrace));
    }
    if (failures.isNotEmpty) throw StorageCleanupException(failures);
  }
}
