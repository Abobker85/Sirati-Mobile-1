import 'dart:async';
import 'dart:ui' show FrameTiming, ImageFilter, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// A frosted-glass pane: whatever is behind it is blurred and tinted with
/// the theme's glass fill, with a thin light edge and a soft lift.
///
/// The pane is drawn solid instead, with a firm outline and no blur, when the
/// phone asks for more contrast ([MediaQueryData.highContrast]) or when
/// [GlassQuality] has found this phone too slow for blur.
///
/// Whatever the mode, the widgets inside sit at the same place in the tree,
/// so switching between glass, solid and clear never resets them (typed text,
/// scroll position and focus in a sheet survive).
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.elevated = true,
    this.strength = 1,
    this.blurSigma = defaultBlurSigma,
  });

  final BorderRadius borderRadius;
  final Widget child;

  /// Floating panes cast a soft shadow; panes that sit on an edge do not.
  final bool elevated;

  /// 0 (clear, no glass at all) to 1 (full glass). Fading glass in or out
  /// animates this, never an opacity over the pane: blur inside an opacity
  /// layer would have nothing to blur, then pop on at the end.
  final double strength;

  /// Blur strength at full [strength].
  final double blurSigma;

  /// At 88% tint more blur is invisible, and every extra step costs.
  static const defaultBlurSigma = 12.0;

  /// Whether glass is drawn solid for this context. Only [GlassSurface]
  /// itself rebuilds when [GlassQuality.solid] changes; other callers read a
  /// snapshot.
  static bool solid(BuildContext context) =>
      (MediaQuery.maybeHighContrastOf(context) ?? false) ||
      GlassQuality.solid.value;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  /// Whether this pane is currently counted as visible blur.
  bool _counted = false;

  @override
  void initState() {
    super.initState();
    GlassQuality.ensureWatching();
    GlassQuality.solid.addListener(_onQuality);
  }

  void _onQuality() => setState(() {});

  void _count(bool blurring) {
    if (blurring == _counted) return;
    _counted = blurring;
    GlassQuality._visibleBlur += blurring ? 1 : -1;
  }

  @override
  void dispose() {
    _count(false);
    GlassQuality.solid.removeListener(_onQuality);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final t = widget.strength.clamp(0.0, 1.0);
    final solid = GlassSurface.solid(context);
    final blur = t > 0 && !solid;
    _count(blur && TickerMode.valuesOf(context).enabled);
    final sigma = widget.blurSigma * t;
    final radius = widget.borderRadius;

    final Color fill;
    final Color edge;
    if (t == 0) {
      fill = c.surface.withValues(alpha: 0);
      edge = fill;
    } else if (solid) {
      fill = c.surface.withValues(alpha: t);
      edge = c.outline.withValues(alpha: t);
    } else {
      fill = c.glassFill.withValues(alpha: c.glassFill.a * t);
      edge = c.glassEdge.withValues(alpha: c.glassEdge.a * t);
    }

    // One shape for every mode: only values change, never the tree.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.elevated && blur
            ? [
                for (final s in c.glassShadow)
                  s.copyWith(color: s.color.withValues(alpha: s.color.a * t)),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: t == 0 ? Clip.none : Clip.antiAlias,
        child: BackdropFilter(
          enabled: blur,
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(color: edge),
            ),
            // Rows and buttons inside paint their ink on this clear
            // Material, above the tint, so taps stay visible.
            child: Material(
              type: MaterialType.transparency,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Decides, per phone, whether glass is affordable.
///
/// While glass is actually blurring on screen it watches how long frames take
/// to draw. When this phone keeps missing its frame budget (at its own
/// refresh rate), the decision "solid" is saved and applied from the next
/// launch, so glass never flips under the user's finger mid-session.
///
/// Only in release and profile builds: debug builds are always slow.
abstract final class GlassQuality {
  /// True when glass should be drawn solid on this phone.
  static final solid = ValueNotifier<bool>(false);

  /// Frames per measured window.
  static const window = 60;

  /// Frames ignored after watching starts (first-launch shader warm-up,
  /// splash to Home).
  static const warmUpFrames = 300;

  /// Slow windows in a row before the phone is judged too slow.
  static const slowWindowsToSwitch = 3;

  /// A window is slow when its 90th-percentile raster time is above this
  /// share of one frame at the display's refresh rate.
  static const budgetShare = .85;

  static const _prefsKey = 'glass_quality.solid';

  static bool _watching = false;
  static final _frames = <Duration>[];
  static int _slowWindows = 0;
  static int _seen = 0;
  static int _visibleBlur = 0;
  static double _refreshRate = 60;

  /// Whether this session has already judged the phone too slow (saved for
  /// the next launch).
  @visibleForTesting
  static bool tooSlow = false;

  /// Lets tests run the watcher in a debug build.
  @visibleForTesting
  static bool debugWatchInDebug = false;

  /// Raster budget for one frame on this display.
  static Duration get budget => Duration(
        microseconds: (1e6 / _refreshRate * budgetShare).round(),
      );

  /// Starts watching frame times (once), after applying a decision saved by
  /// an earlier launch.
  static void ensureWatching() {
    if (_watching || (kDebugMode && !debugWatchInDebug)) return;
    _watching = true;
    final rate =
        PlatformDispatcher.instance.views.firstOrNull?.display.refreshRate;
    if (rate != null && rate > 0) _refreshRate = rate;
    unawaited(_loadSaved());
    SchedulerBinding.instance.addTimingsCallback(onTimings);
  }

  static Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsKey) ?? false) {
        tooSlow = true;
        // Applied before Home settles on launch, not mid-use.
        solid.value = true;
      }
    } catch (_) {
      // No storage: keep glass.
    }
  }

  /// The engine's frame timings callback.
  @visibleForTesting
  static void onTimings(List<FrameTiming> timings) =>
      report([for (final t in timings) t.rasterDuration]);

  /// Feeds raster times in. Frames only count while glass is blurring on
  /// screen and after the warm-up.
  @visibleForTesting
  static void report(List<Duration> rasterTimes) {
    if (tooSlow) return;
    for (final d in rasterTimes) {
      _seen++;
      if (_seen <= warmUpFrames || _visibleBlur <= 0) continue;
      _frames.add(d);
      if (_frames.length < window) continue;
      final sorted = [..._frames]..sort();
      _frames.clear();
      final p90 = sorted[(sorted.length * .9).floor().clamp(0, window - 1)];
      _slowWindows = p90 > budget ? _slowWindows + 1 : 0;
      if (_slowWindows >= slowWindowsToSwitch) {
        tooSlow = true;
        unawaited(_save(p90));
        return;
      }
    }
  }

  static Future<void> _save(Duration p90) async {
    unawaited(AnalyticsService.logEvent('glass_solid_fallback', {
      'raster_p90_ms': p90.inMicroseconds / 1000,
      'refresh_rate': _refreshRate,
    }));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (_) {
      // Not saved: the next launch measures again.
    }
  }

  /// Back to the starting state, for tests.
  @visibleForTesting
  static void reset({double refreshRate = 60}) {
    solid.value = false;
    tooSlow = false;
    _frames.clear();
    _slowWindows = 0;
    _seen = 0;
    _refreshRate = refreshRate;
  }

  /// Pretends glass is (or is not) blurring on screen, for tests that feed
  /// [report] without a widget tree.
  @visibleForTesting
  static set debugVisibleBlur(int count) => _visibleBlur = count;

  /// How many glass panes are blurring on screen now, for tests.
  @visibleForTesting
  static int get visibleBlur => _visibleBlur;

  /// Re-reads the saved decision, for tests.
  @visibleForTesting
  static Future<void> debugLoadSaved() => _loadSaved();
}
