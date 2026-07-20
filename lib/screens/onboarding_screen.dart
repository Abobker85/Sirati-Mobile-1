import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/analytics_service.dart';
import '../services/preference_store.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';
import '../widgets/motion.dart';
import '../widgets/submit_button.dart';

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
                        style: AppTextStyles.labelMd().copyWith(
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
                  return _OnboardingPageView(page: pages[i]);
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
                    icon: last ? null : Icons.arrow_forward,
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

  const _OnboardingPage({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.body,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: page.accentSoft,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: page.accent.withValues(alpha: 0.14),
              ),
              boxShadow: context.sirati.softShadow,
            ),
            child: Icon(page.icon, size: 52, color: page.accent),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: context.sirati.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd().copyWith(
              height: 1.7,
              color: context.sirati.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
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
