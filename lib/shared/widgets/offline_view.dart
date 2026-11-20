import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/brand_gradient_button.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Full-screen "no internet" state with retry and automatic recovery.
///
/// While mounted and the app is in the foreground it calls [onRetry] on a
/// backoff ([retryDelays], then the last delay repeats), so the screen heals
/// itself when the connection returns without the user tapping anything.
class OfflineView extends StatefulWidget {
  /// Re-runs the failed load. The view shows a checking state until the
  /// returned future (if any) completes.
  final FutureOr<void> Function()? onRetry;

  /// Opens content saved on the device; the button is hidden when null.
  final VoidCallback? onOpenSaved;

  final List<Duration> retryDelays;

  const OfflineView({
    super.key,
    this.onRetry,
    this.onOpenSaved,
    this.retryDelays = defaultRetryDelays,
  });

  static const defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];

  @override
  State<OfflineView> createState() => _OfflineViewState();
}

class _OfflineViewState extends State<OfflineView> with WidgetsBindingObserver {
  Timer? _timer;
  int _attempt = 0;

  /// Reconnect attempts started while this screen showed; each one makes
  /// the offline badge send out a ping.
  int _pings = 0;
  bool _checking = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void didUpdateWidget(OfflineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.onRetry == null) != (widget.onRetry == null)) {
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      // Coming back is the most likely moment the network is back too.
      _attempt = 0;
      unawaited(_retry());
    } else {
      _timer?.cancel();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.onRetry == null || !_foreground || widget.retryDelays.isEmpty) {
      return;
    }
    final delays = widget.retryDelays;
    final delay = delays[_attempt.clamp(0, delays.length - 1)];
    _timer = Timer(delay, () {
      _attempt++;
      unawaited(_retry());
    });
  }

  Future<void> _retry() async {
    final onRetry = widget.onRetry;
    if (onRetry == null || _checking) return;
    _timer?.cancel();
    setState(() {
      _checking = true;
      _pings++;
    });
    try {
      await onRetry();
    } catch (_) {
      // The parent shows its own result; a failed attempt just reschedules.
    } finally {
      if (mounted) {
        setState(() => _checking = false);
        _schedule();
      }
    }
  }

  void _retryNow() {
    _attempt = 0;
    unawaited(_retry());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: _sidePadding(constraints.maxWidth),
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? constraints.maxHeight - AppSpacing.lg * 2
                : 0,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // The same grey circle as every other state; it pings on each
                // reconnect attempt.
                Center(
                  child: OfflinePing(
                    trigger: _pings,
                    child: const AppStateIcon(Icons.wifi_off_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (widget.onRetry != null) ...[
                  Center(
                    child: _LivePill(
                      label: _checking
                          ? l10n.sharedOfflineChecking
                          : l10n.sharedOfflineWaiting,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    l10n.sharedOfflineTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.of(
                      context,
                      AppTypography.titleLg,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.sharedOfflineBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    AppTypography.bodyMd,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TipsCard(
                  title: l10n.sharedOfflineTipsTitle,
                  tips: [
                    l10n.sharedOfflineTipAirplane,
                    l10n.sharedOfflineTipSignal,
                  ],
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.lg),
                if (widget.onRetry != null)
                  BrandGradientButton(
                    label: l10n.retry,
                    loadingLabel: l10n.sharedOfflineChecking,
                    icon: Icons.refresh_rounded,
                    isLoading: _checking,
                    onPressed: _retryNow,
                  ),
                if (widget.onOpenSaved != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenSaved,
                    icon: Icon(
                      Icons.folder_open_rounded,
                      size: 20,
                      color: c.primaryInk,
                    ),
                    label: Text(
                      l10n.sharedOfflineOpenSaved,
                      textAlign: TextAlign.center,
                      style: AppTypography.of(
                        context,
                        AppTypography.titleSm,
                        color: c.primaryInk,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppTouchTarget.min),
                      side: BorderSide(color: c.borderStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.lgAll,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _sidePadding(double width) {
    final gutter = AppSpacing.pageGutter(width);
    final centered = (width - 440) / 2;
    return centered > gutter ? centered : gutter;
  }
}

/// Status pill with a dot that pulses unless the platform asks for reduced
/// motion. The pulse is a fixed number of cycles so `pumpAndSettle` and
/// battery are never held by an endless animation.
class _LivePill extends StatefulWidget {
  final String label;

  const _LivePill({required this.label});

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  static const _cycles = 6;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _pulse.addStatusListener((status) {
      if (status == AnimationStatus.completed && ++_done < _cycles) {
        _pulse.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MotionSettings.reduce(context);
    if (reduce) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating && _done == 0) {
      _pulse.forward();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Semantics(
      liveRegion: true,
      label: widget.label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: c.tealLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.teal.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: (1 - _pulse.value) * 0.6,
                      child: Container(
                        width: 6 + 8 * _pulse.value,
                        height: 6 + 8 * _pulse.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.teal,
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.onSuccessContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                widget.label,
                style: AppTypography.of(
                  context,
                  AppTypography.labelMd,
                  color: c.onSuccessContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final String title;
  final List<String> tips;

  const _TipsCard({required this.title, required this.tips});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceLow,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 20,
                color: c.primaryInk,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.of(
                    context,
                    AppTypography.titleSm,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Divider(height: 1, color: c.border),
          ),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: c.onSuccessContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTypography.of(
                        context,
                        AppTypography.bodySm,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Each time [trigger] changes (a reconnect attempt starts), a ring goes
/// out from [child] and the child hops once, as if calling out. It moves
/// only on an attempt, never by itself; with reduced motion it is still.
class OfflinePing extends StatefulWidget {
  const OfflinePing({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  /// One ping.
  static const duration = Duration(milliseconds: 900);

  /// Key of the ring, for tests.
  static const ringKey = ValueKey('offline-ping-ring');

  @override
  State<OfflinePing> createState() => _OfflinePingState();
}

class _OfflinePingState extends State<OfflinePing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: OfflinePing.duration);

  @override
  void didUpdateWidget(OfflinePing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        !MotionSettings.reduce(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final moving = _c.isAnimating && t > 0 && t < 1;
        final ring = Curves.easeOut.transform(t);
        // A small hop at the start of the ping.
        final hop = math.sin(math.pi * (t / .4).clamp(0.0, 1.0));
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (moving)
              IgnorePointer(
                child: Container(
                  key: OfflinePing.ringKey,
                  width: AppStateIcon.size + 44 * ring,
                  height: AppStateIcon.size + 44 * ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.brandSurface.withValues(alpha: .5 * (1 - ring)),
                      width: 3 * (1 - ring) + .5,
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(0, moving ? -5 * hop : 0),
              child: child,
            ),
          ],
        );
      },
    );
  }
}
