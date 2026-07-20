import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Thin, never-throwing Firebase Analytics wrapper.
///
/// Mirrors [NotificationService] style: singleton access, static helpers, and
/// hard privacy rules — no CV text, names, emails, phones, free text, or exact
/// scores. Only buckets, ids, enums, and durations.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Attach to [MaterialApp.navigatorObservers] for automatic screen views.
  ///
  /// Prefer [navigatorObservers] so tests / early boot without
  /// [Firebase.initializeApp] do not throw.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Safe for [MaterialApp.navigatorObservers] when Firebase may be absent.
  static List<NavigatorObserver> get navigatorObservers {
    if (!_firebaseReady) return const <NavigatorObserver>[];
    try {
      return <NavigatorObserver>[observer];
    } catch (e, st) {
      _debugError('navigatorObservers', e, st);
      return const <NavigatorObserver>[];
    }
  }

  /// Call once after [Firebase.initializeApp].
  static Future<void> initialize() async {
    if (!_firebaseReady) return;
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
    } catch (e, st) {
      _debugError('initialize', e, st);
    }
  }

  // ── Core plumbing ────────────────────────────────────────────────────

  static Future<void> logEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      final safe = _sanitize(parameters);
      if (kDebugMode) {
        debugPrint('[Analytics] $name${safe.isEmpty ? '' : ' $safe'}');
      }
      // Widget/golden tests (and early boot) may run without Firebase.initializeApp.
      if (!_firebaseReady) return;
      await _analytics.logEvent(
        name: name,
        parameters: safe.isEmpty ? null : safe,
      );
    } catch (e, st) {
      _debugError(name, e, st);
    }
  }

  /// True once [Firebase.initializeApp] has created the default app.
  static bool get _firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[Analytics] screen_view name=$screenName');
      }
      if (!_firebaseReady) return;
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e, st) {
      _debugError('screen_view', e, st);
    }
  }

  /// Opaque backend user id only — never email.
  static Future<void> setUserId(String? userId) async {
    try {
      if (!_firebaseReady) return;
      final id = userId?.trim();
      if (id == null || id.isEmpty || id == '0') {
        await _analytics.setUserId(id: null);
        if (kDebugMode) debugPrint('[Analytics] setUserId=null');
        return;
      }
      await _analytics.setUserId(id: id);
      if (kDebugMode) debugPrint('[Analytics] setUserId=$id');
    } catch (e, st) {
      _debugError('setUserId', e, st);
    }
  }

  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      if (!_firebaseReady) return;
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        debugPrint('[Analytics] user_property $name=$value');
      }
    } catch (e, st) {
      _debugError('setUserProperty:$name', e, st);
    }
  }

  static Future<void> setAppLanguage(String lang) =>
      setUserProperty(name: 'app_language', value: lang == 'en' ? 'en' : 'ar');

  static Future<void> setThemeMode(String mode) {
    final normalized =
        (mode == 'light' || mode == 'dark' || mode == 'system') ? mode : 'system';
    return setUserProperty(name: 'theme_mode', value: normalized);
  }

  static Future<void> clearUser() async {
    await setUserId(null);
  }

  // ── Funnel events ────────────────────────────────────────────────────

  static Future<void> logOnboardingCompleted() =>
      logEvent('onboarding_completed');

  static Future<void> logOnboardingSkipped({required int pageIndex}) =>
      logEvent('onboarding_skipped', {'page_index': pageIndex});

  static Future<void> logLoginSuccess({required String method}) =>
      logEvent('login_success', {'method': method});

  static Future<void> logRegisterSuccess() => logEvent('register_success');

  static Future<void> logWizardStarted({required String mode}) =>
      logEvent('wizard_started', {
        'mode': mode == 'edit' ? 'edit' : 'create',
      });

  static Future<void> logWizardStepCompleted({required int step}) =>
      logEvent('wizard_step_completed', {'step': step});

  static Future<void> logWizardAbandoned({
    required int step,
    required bool dirty,
  }) =>
      logEvent('wizard_abandoned', {
        'step': step,
        'dirty': dirty ? 1 : 0,
      });

  static Future<void> logDraftSaved() => logEvent('draft_saved');

  static Future<void> logDraftRestored() => logEvent('draft_restored');

  static Future<void> logCvGenerated({
    String? templateId,
    required int durationMs,
  }) =>
      logEvent('cv_generated', {
        'template_id': (templateId == null || templateId.isEmpty)
            ? 'default'
            : templateId,
        'duration_ms': durationMs < 0 ? 0 : durationMs,
      });

  static Future<void> logCvGenerationFailed({required String errorType}) =>
      logEvent('cv_generation_failed', {
        'error_type': _safeErrorType(errorType),
      });

  static Future<void> logAnalysisStarted() => logEvent('analysis_started');

  static Future<void> logAnalysisCompleted({
    required int score,
    required int durationMs,
  }) =>
      logEvent('analysis_completed', {
        'score_bucket': scoreBucket(score),
        'duration_ms': durationMs < 0 ? 0 : durationMs,
      });

  static Future<void> logAnalysisFailed({required String errorType}) =>
      logEvent('analysis_failed', {
        'error_type': _safeErrorType(errorType),
      });

  static Future<void> logScoreBoosterTipShown({required String fieldId}) =>
      logEvent('score_booster_tip_shown', {
        'field_id': _safeId(fieldId),
      });

  static Future<void> logScoreBoosterCompleted() =>
      logEvent('score_booster_completed');

  static Future<void> logThemeChanged({required String mode}) =>
      logEvent('theme_changed', {
        'mode': (mode == 'light' || mode == 'dark' || mode == 'system')
            ? mode
            : 'system',
      });

  static Future<void> logLanguageChanged({required String lang}) =>
      logEvent('language_changed', {
        'lang': lang == 'en' ? 'en' : 'ar',
      });

  static Future<void> logOfflineFallbackShown({required String surface}) =>
      logEvent('offline_fallback_shown', {
        'surface': _safeSurface(surface),
      });

  // ── Helpers ──────────────────────────────────────────────────────────

  /// ATS score → coarse bucket only (never exact score).
  static String scoreBucket(int score) {
    if (score <= 40) return '0-40';
    if (score <= 70) return '41-70';
    return '71-100';
  }

  static String _safeErrorType(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return 'unknown';
    // Keep enum-like tokens only (letters, digits, underscore).
    final cleaned = t.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  static String _safeId(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return 'unknown';
    final cleaned = t.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  static String _safeSurface(String raw) {
    switch (raw) {
      case 'dashboard':
      case 'cvs':
      case 'news':
        return raw;
      default:
        return 'unknown';
    }
  }

  /// Drop non-primitive / oversized values so free text never slips in.
  static Map<String, Object> _sanitize(Map<String, Object>? parameters) {
    if (parameters == null || parameters.isEmpty) return const {};
    final out = <String, Object>{};
    parameters.forEach((key, value) {
      if (value is String) {
        // Guardrail: reject long strings that look like free text.
        if (value.length > 64) return;
        out[key] = value;
      } else if (value is num || value is bool) {
        out[key] = value;
      }
      // Skip lists, maps, objects.
    });
    return out;
  }

  static void _debugError(String where, Object e, StackTrace st) {
    if (kDebugMode) {
      debugPrint('[Analytics] suppressed error at $where: $e');
    }
  }
}
