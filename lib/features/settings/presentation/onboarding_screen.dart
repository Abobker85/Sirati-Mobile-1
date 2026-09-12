import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';
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

  List<_OnboardingPage> _pages(bool en) => [
        _OnboardingPage(
          icon: Icons.description_outlined,
          accent: context.sirati.primary,
          accentSoft: context.sirati.primaryLight,
          title: en ? 'Welcome to Sirati' : 'مرحباً بك في سيرتي',
          body: en
              ? 'Analyze your CV for ATS score, or build a professional resume with AI — in Arabic or English.'
              : 'حلل سيرتك الذاتية واحصل على درجة ATS، أو أنشئ سيرة ذاتية احترافية بالذكاء الاصطناعي — بالعربية أو الإنجليزية.',
        ),
        _OnboardingPage(
          icon: Icons.speed_rounded,
          accent: context.sirati.primaryDark,
          accentSoft: context.sirati.tealLight,
          useBrandMark: true,
          title: en ? 'Instant ATS analysis' : 'تحليل ATS فوري',
          body: en
              ? 'Get a clear score, missing keywords, and strengths and gaps — so you know what to improve before you apply.'
              : 'احصل على درجة واضحة، والكلمات المفتاحية الناقصة، ونقاط القوة والضعف — لتعرف ماذا تحسّن قبل التقديم.',
        ),
        _OnboardingPage(
          icon: Icons.auto_awesome_rounded,
          accent: context.sirati.amber,
          accentSoft: context.sirati.amberLight,
          title: en ? 'AI CV in minutes' : 'سيرة بالذكاء في دقائق',
          body: en
              ? 'Enter your details and generate a polished, downloadable CV with templates built for hiring systems.'
              : 'أدخل بياناتك وأنشئ سيرة ذاتية أنيقة قابلة للتنزيل بقوالب مهيأة لأنظمة التوظيف.',
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
      AnalyticsService.logOnboardingSkipped(pageIndex: _index);
    } else {
      AnalyticsService.logOnboardingCompleted();
    }
    if (!mounted) return;
    widget.onFinished();
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      _finish(skipped: false);
      return;
    }
    _pageController.nextPage(
      duration:
          MotionSettings.reduce(context) ? Duration.zero : MotionDurations.slow,
      curve: MotionCurves.enter,
    );
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final pages = _pages(en);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final last = _index >= _pageCount - 1;
    final page = pages[_index];

    // No Scaffold here — host [SplashScreen] already provides one.
    // Overlay style matches global theme (edge-to-edge + icon brightness).
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                  const LanguageToggle(),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed:
                          _finishing ? null : () => _finish(skipped: true),
                      child: Text(
                        en ? 'Skip' : 'تخطي',
                        style: AppTextStyles.labelMd(context.sirati).copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.sirati.textHint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                reverse: isRtl,
                itemCount: _pageCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) {
                  return _OnboardingPageView(
                    page: pages[i],
                    active: i == _index,
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
                  _PageDots(
                    count: _pageCount,
                    index: _index,
                    activeColor: page.accent,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SubmitButton(
                    label: last
                        ? (en ? 'Get started' : 'ابدأ الآن')
                        : (en ? 'Next' : 'التالي'),
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

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final bool active;

  const _OnboardingPageView({
    required this.page,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 280;
        final iconSize = compact ? 92.0 : 112.0;
        final iconRadius = compact ? 24.0 : 28.0;
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
                _OnboardingHero(
                  page: page,
                  active: active,
                  size: iconSize,
                  radius: iconRadius,
                  glyphSize: iconGlyphSize,
                ),
                SizedBox(height: heroGap),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: context.sirati.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(context.sirati).copyWith(
                    height: compact ? 1.55 : 1.7,
                    color: context.sirati.textSecondary,
                    fontSize: bodySize,
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
  final double radius;
  final double glyphSize;

  const _OnboardingHero({
    required this.page,
    required this.active,
    required this.size,
    required this.radius,
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
    if (widget.active && !oldWidget.active) {
      if (MotionSettings.reduce(context)) {
        _controller.value = 1;
        return;
      }
      _controller.forward(from: 0);
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
              color: context.sirati.surface,
              border: Border.all(
                color: widget.page.accent.withValues(alpha: 0.18),
              ),
              boxShadow: context.sirati.softShadow,
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
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: widget.page.accent.withValues(alpha: 0.14),
              ),
              boxShadow: context.sirati.softShadow,
            ),
            child: Icon(
              widget.page.icon,
              size: widget.glyphSize,
              color: widget.page.accent,
            ),
          );

    if (MotionSettings.reduce(context)) return hero;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: hero),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final Color activeColor;

  const _PageDots({
    required this.count,
    required this.index,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: reduce ? Duration.zero : MotionDurations.medium,
          curve: MotionCurves.state,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? activeColor
                : context.sirati.borderStrong.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
