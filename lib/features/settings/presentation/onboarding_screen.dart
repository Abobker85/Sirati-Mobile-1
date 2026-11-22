import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/rolling_number.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// First-run product tour (3 pages). Shown once for logged-out users.
///
/// Completing or skipping persists [PreferenceStore.onboardingKey] and calls
/// [onFinished] so the host can open the welcome / auth gate.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _prefs = const PreferenceStore();
  final _pageController = PageController();
  int _index = 0;
  bool _finishing = false;

  static const _pageCount = 3;

  /// "1 / 3" — small numeric marker under the dots. Latin digits in every
  /// locale by product decision: numbers stay 0-9 across the app even in
  /// Arabic UI, so counters, scores, and dates all read the same way.
  static String _stepCounterLabel({
    required int index,
    required int count,
  }) {
    return '${index + 1} / $count';
  }

  List<_OnboardingPage> _pages(AppLocalizations l10n) => [
        _OnboardingPage(
          icon: Icons.description_outlined,
          accent: context.sirati.primaryInk,
          accentSoft: context.sirati.primaryLight,
          title: l10n.welcomeToSirati,
          body: l10n.settingsOnboardingWelcomeBody,
        ),
        _OnboardingPage(
          icon: Icons.speed_rounded,
          accent: context.sirati.primaryDark,
          accentSoft: context.sirati.tealLight,
          useBrandMark: true,
          title: l10n.settingsOnboardingAtsTitle,
          body: l10n.settingsOnboardingAtsBody,
        ),
        _OnboardingPage(
          icon: Icons.auto_awesome_rounded,
          accent: context.sirati.onWarningContainer,
          accentSoft: context.sirati.warningLight,
          title: l10n.settingsOnboardingAiTitle,
          body: l10n.settingsOnboardingAiBody,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool skipped}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await _prefs.saveOnboardingCompleted(true);
    } catch (_) {
      // Still advance — don't trap the user if storage fails.
    }
    if (skipped) {
      unawaited(AnalyticsService.logOnboardingSkipped(pageIndex: _index));
    } else {
      unawaited(AnalyticsService.logOnboardingCompleted());
    }
    if (!mounted) return;
    widget.onFinished();
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      unawaited(_finish(skipped: false));
      return;
    }
    if (MotionSettings.reduce(context)) {
      _pageController.jumpToPage(_index + 1);
      return;
    }
    unawaited(_pageController.nextPage(
      duration: MotionDurations.slow,
      curve: MotionCurves.enter,
    ));
  }

  void _previous() {
    if (_index <= 0) return;
    if (MotionSettings.reduce(context)) {
      _pageController.jumpToPage(_index - 1);
      return;
    }
    unawaited(_pageController.previousPage(
      duration: MotionDurations.slow,
      curve: MotionCurves.enter,
    ));
  }

  void _jumpTo(int i) {
    if (i == _index || i < 0 || i >= _pageCount) return;
    HapticFeedback.selectionClick();
    if (MotionSettings.reduce(context)) {
      _pageController.jumpToPage(i);
      return;
    }
    unawaited(_pageController.animateToPage(
      i,
      duration: MotionDurations.slow,
      curve: MotionCurves.enter,
    ));
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    HapticFeedback.selectionClick();
  }

  /// Current fractional page position from [_pageController], falling back to
  /// [_index] before the controller attaches.
  double get _currentPage {
    if (!_pageController.hasClients ||
        !_pageController.position.hasContentDimensions) {
      return _index.toDouble();
    }
    return _pageController.page ?? _index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final last = _index >= _pageCount - 1;
    final reduce = MotionSettings.reduce(context);
    final switchDuration = reduce ? Duration.zero : MotionDurations.fast;

    // No Scaffold here — host [SplashScreen] already provides one.
    // Overlay style matches global theme (edge-to-edge + icon brightness).
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previous();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle(
          context.sirati,
          Theme.of(context).brightness,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    LanguageToggle(
                      backgroundColor: PageSurface.fillOf(context),
                    ),
                    // Back to the previous page (SIRATI-100). Hidden on page 1
                    // so it never appears when there is nowhere to go.
                    AnimatedSwitcher(
                      duration: switchDuration,
                      switchInCurve: MotionCurves.enter,
                      switchOutCurve: MotionCurves.exit,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.85, end: 1)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                      child: _index > 0
                          ? Padding(
                              key: const ValueKey('onboarding-back'),
                              padding: const EdgeInsetsDirectional.only(
                                  start: AppSpacing.xs),
                              child: IconButton(
                                onPressed: _finishing ? null : _previous,
                                // matchTextDirection mirrors this in RTL automatically.
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: context.sirati.textSecondary,
                                ),
                                tooltip: l10n.settingsOnboardingPrevious,
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('onboarding-back-empty'),
                            ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: switchDuration,
                      switchInCurve: MotionCurves.enter,
                      switchOutCurve: MotionCurves.exit,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                      child: !last
                          // Skip: the theme's grey filled capsule; the label
                          // is textSecondary (textHint failed AA at 12sp).
                          ? OutlinedButton(
                              key: const ValueKey('onboarding-skip'),
                              onPressed: _finishing
                                  ? null
                                  : () => unawaited(_finish(skipped: true)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.sirati.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                minimumSize: const Size(48, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              child: Text(
                                l10n.settingsOnboardingSkip,
                                style: AppTextStyles.labelMd(context.sirati)
                                    .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.sirati.textSecondary,
                                ),
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('onboarding-skip-empty'),
                              height: 48,
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    final pageOffset = _currentPage;
                    return PageView.builder(
                      // No `reverse`: PageView already follows Directionality, so
                      // in Arabic the next page enters from the left, matching the
                      // mirrored Back arrow.
                      controller: _pageController,
                      itemCount: _pageCount,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) {
                        return _OnboardingPageView(
                          page: pages[i],
                          active: i == _index,
                          delta:
                              reduce ? 0.0 : (pageOffset - i).clamp(-1.0, 1.0),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _OnboardingStepCounter(
                      index: _index,
                      count: _pageCount,
                      style: AppTextStyles.labelMd(context.sirati).copyWith(
                        color: context.sirati.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) => _PageDots(
                        count: _pageCount,
                        index: _index,
                        page: reduce ? _index.toDouble() : _currentPage,
                        // One ink tone for the active dot: >= 3:1 on the page
                        // background in both themes (WCAG 1.4.11).
                        activeColor: context.sirati.primaryInk,
                        onTap: _finishing ? null : _jumpTo,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SubmitButton(
                      label: last ? l10n.getStarted : l10n.next,
                      icon: last ? null : Icons.arrow_forward_rounded,
                      onPressed: _finishing ? null : _next,
                      isLoading: _finishing && last,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String body;
  final bool useBrandMark;

  const _OnboardingPage({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.body,
    this.useBrandMark = false,
  });
}

class _OnboardingStepCounter extends StatelessWidget {
  const _OnboardingStepCounter({
    required this.index,
    required this.count,
    required this.style,
  });

  final int index;
  final int count;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _OnboardingScreenState._stepCounterLabel(
        index: index,
        count: count,
      ),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RollingNumber(value: index + 1, style: style),
            Text(' / $count', style: style),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final bool active;
  final double delta;

  const _OnboardingPageView({
    required this.page,
    required this.active,
    this.delta = 0,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    final end = MotionAxis.endSign(context);
    final parallax = reduce ? 0.0 : delta * end;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 280;
        final iconSize = compact ? 92.0 : 112.0;
        final iconGlyphSize = compact ? 44.0 : 52.0;
        final titleSize = compact ? 23.0 : 26.0;
        final bodySize = compact ? 14.0 : 15.0;
        final heroGap = compact ? AppSpacing.md : AppSpacing.xxl;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(parallax * 24, 0),
                  child: Transform.scale(
                    scale: reduce ? 1.0 : (1 - 0.08 * delta.abs()),
                    child: _OnboardingHero(
                      page: page,
                      active: active,
                      size: iconSize,
                      glyphSize: iconGlyphSize,
                    ),
                  ),
                ),
                SizedBox(height: heroGap),
                Transform.translate(
                  offset: Offset(parallax * -10, 0),
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: context.sirati.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Transform.translate(
                  offset: Offset(parallax * -18, 0),
                  child: Text(
                    page.body,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd(context.sirati).copyWith(
                      height: compact ? 1.55 : 1.7,
                      color: context.sirati.textSecondary,
                      fontSize: bodySize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingHero extends StatefulWidget {
  final _OnboardingPage page;
  final bool active;
  final double size;
  final double glyphSize;

  const _OnboardingHero({
    required this.page,
    required this.active,
    required this.size,
    required this.glyphSize,
  });

  @override
  State<_OnboardingHero> createState() => _OnboardingHeroState();
}

class _OnboardingHeroState extends State<_OnboardingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: MotionCurves.enter,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.86, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: MotionCurves.enter));
  bool _playedInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionSettings.reduce(context)) {
      _controller.value = 1;
      _playedInitial = true;
      return;
    }
    if (widget.active && !_playedInitial) {
      _playedInitial = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A page becomes active at the swipe midpoint, while its hero is already
    // on screen; replaying the entrance there would blank it mid-drag. The
    // page view's own parallax/scale carries the transition, so only make
    // sure the hero ends fully shown.
    if (widget.active && !oldWidget.active && !_controller.isAnimating) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.page.useBrandMark
        ? Container(
            key: const ValueKey('onboarding_brand_mark'),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.sirati.cardFill,
            ),
            child: const Center(
              child: SiratiMark(size: 56, elevated: true),
            ),
          )
        : Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.page.accentSoft,
              // Circular like the SiratiMark on page 2 so all three heroes
              // share one geometry (SIRATI-99/100).
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.page.icon,
              size: widget.glyphSize,
              color: widget.page.accent,
            ),
          );

    final framed = widget.active
        ? AmbientMove(
            kind: AmbientKind.float,
            delay: const Duration(seconds: 2),
            rest: const Duration(seconds: 12),
            child: hero,
          )
        : hero;

    if (MotionSettings.reduce(context)) return hero;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: framed),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final double? page;
  final Color activeColor;

  /// Optional handler that fires when a dot is tapped. When null the dots
  /// remain visual only (kept optional so callers that don't wire a
  /// controller can keep using the widget). (SIRATI-100)
  final ValueChanged<int>? onTap;

  const _PageDots({
    required this.count,
    required this.index,
    required this.activeColor,
    this.page,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    final l10n = AppLocalizations.of(context);
    final currentPage = page ?? index.toDouble();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        final proximity = reduce
            ? (active ? 1.0 : 0.0)
            : (1.0 - (currentPage - i).abs()).clamp(0.0, 1.0);
        final width = lerpDouble(8, 22, proximity)!;
        final label = l10n.settingsOnboardingPageOf(i + 1, count);
        final dot = AnimatedContainer(
          duration:
              reduce || page != null ? Duration.zero : MotionDurations.medium,
          curve: MotionCurves.state,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? activeColor
                : context.sirati.borderStrong.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
        );
        if (onTap == null) {
          return Semantics(
            label: label,
            selected: active,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: dot),
            ),
          );
        }
        return Semantics(
          button: true,
          label: label,
          selected: active,
          child: InkWell(
            onTap: () => onTap!(i),
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: dot),
            ),
          ),
        );
      }),
    );
  }
}
