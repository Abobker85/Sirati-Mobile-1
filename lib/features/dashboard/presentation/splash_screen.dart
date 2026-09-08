import 'package:flutter/material.dart';

import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/utils/root_navigation.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/loading/branded_loader.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/settings/presentation/onboarding_screen.dart';
import 'package:sirati/features/settings/presentation/privacy_policy_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';

enum _SplashPhase { boot, onboarding, welcome }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _tokenStore = const AuthTokenStore();
  final _auth = AuthApiService();
  final _prefs = const PreferenceStore();

  _SplashPhase _phase = _SplashPhase.boot;

  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  /// Token → check verification then home. Else onboarding (once) or welcome.
  Future<void> _bootstrapSession() async {
    try {
      final token = await _tokenStore.readToken();
      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        await _enterAuthenticatedSession();
        return;
      }
    } catch (_) {
      // Storage failure → treat as logged out.
    }

    var showOnboarding = true;
    try {
      showOnboarding = !(await _prefs.readOnboardingCompleted());
    } catch (_) {
      showOnboarding = true;
    }

    if (!mounted) return;
    setState(() {
      _phase = showOnboarding ? _SplashPhase.onboarding : _SplashPhase.welcome;
    });
  }

  /// Validate session; gate unverified users on the OTP screen.
  /// Offline: allow Home when we cannot reach the API (token still present).
  Future<void> _enterAuthenticatedSession() async {
    if (!mounted) return;

    try {
      final user = await _auth.me();
      if (!mounted) return;

      if (user != null && !user.emailVerified) {
        replaceRoot(context, EmailVerificationScreen(email: user.email));
        return;
      }
    } on ApiException catch (e) {
      // 401 already fired AuthSessionGuard from ApiClient.
      if (e.type == ApiErrorType.auth) return;
      // Network / timeout / server — continue to Home offline-friendly.
    } catch (_) {
      // Offline or unexpected — continue to Home.
    }

    if (!mounted) return;
    AppRouter.openAfterAuth(context);
  }

  void _onOnboardingFinished() {
    if (!mounted) return;
    setState(() => _phase = _SplashPhase.welcome);
  }

  Future<void> _goToLogin() async {
    final token = await _tokenStore.readToken();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      await _enterAuthenticatedSession();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sirati.background,
      body: AnimatedSwitcher(
        duration: MotionDurations.medium,
        reverseDuration: MotionDurations.fast,
        switchInCurve: MotionCurves.enter,
        switchOutCurve: MotionCurves.exit,
        transitionBuilder: (child, animation) {
          if (MediaQuery.disableAnimationsOf(context)) {
            return child;
          }
          final isBoot = (child.key as ValueKey?)?.value == 'boot';
          if (isBoot) {
            // Exiting boot circle scales down as it fades
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          }
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: switch (_phase) {
          _SplashPhase.boot => const _BootstrapBody(key: ValueKey('boot')),
          _SplashPhase.onboarding => OnboardingScreen(
              key: const ValueKey('onboarding'),
              onFinished: _onOnboardingFinished,
            ),
          _SplashPhase.welcome => _WelcomeBody(
              key: const ValueKey('welcome'),
              onRegister: _goToRegister,
              onLogin: _goToLogin,
              onPrivacy: _openPrivacyPolicy,
            ),
        },
      ),
    );
  }
}

/// Centered circular element displaying the branded splash intro with scale/fade reveal.
class _BootstrapBody extends StatefulWidget {
  const _BootstrapBody({super.key});

  @override
  State<_BootstrapBody> createState() => _BootstrapBodyState();
}

class _BootstrapBodyState extends State<_BootstrapBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.medium,
    );
    _scaleAnimation = Tween<double>(begin: 1.12, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.enter),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget circle = Container(
      key: const ValueKey('splash_circle'),
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.sirati.surface,
        border: Border.all(
          color: context.sirati.primaryLight,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.sirati.primary.withValues(alpha: 0.15),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandedLoader(size: 52),
            const SizedBox(height: AppSpacing.sm),
            Text(
              en ? 'Sirati' : 'سيرتي',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.sirati.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              en ? 'Preparing workspace…' : 'جارٍ تجهيز مساحتك…',
              style: AppTextStyles.bodySm().copyWith(
                color: context.sirati.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) {
      return Center(child: circle);
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: circle,
      ),
    );
  }
}

class _WelcomeBody extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onPrivacy;

  const _WelcomeBody({
    super.key,
    required this.onRegister,
    required this.onLogin,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final cardTitle =
        en ? 'Build your CV professionally' : 'اصنع سيرتك الذاتية باحترافية';
    final cardBody = en
        ? 'Create an ATS-ready CV that reaches employers with world-class design, in minutes.'
        : 'أنشئ سيرة ذاتية متوافقة مع أنظمة ATS وتصل لأصحاب العمل خلال دقائق.';

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl + 4,
                  AppSpacing.lg - 2,
                  AppSpacing.xl + 4,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MotionReveal(
                      order: 0,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: LanguageToggle(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl + 4),
                    const MotionReveal(
                      order: 1,
                      child: Center(child: _SplashLogo()),
                    ),
                    const SizedBox(height: AppSpacing.lg - 2),
                    MotionReveal(
                      order: 2,
                      child: Text(
                        en ? 'Sirati' : 'سيرتي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.sirati.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm - 2),
                    MotionReveal(
                      order: 2,
                      child: Text(
                        en
                            ? 'Your first step towards a better professional future'
                            : 'خطوتك الأولى نحو مستقبل مهني أفضل',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd().copyWith(
                          height: 1.7,
                          color: context.sirati.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl + 4),
                    MotionReveal(
                      order: 3,
                      child: _ValueCard(
                        title: cardTitle,
                        body: cardBody,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl + 4),
                    MotionReveal(
                      order: 4,
                      child: SubmitButton(
                        label: en ? 'Create New Account' : 'إنشاء حساب جديد',
                        icon: Icons.arrow_forward,
                        onPressed: onRegister,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MotionReveal(
                      order: 4,
                      child: SubmitButton(
                        label: en ? 'Sign In' : 'تسجيل الدخول',
                        outlined: true,
                        onPressed: onLogin,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg - 2),
                    MotionReveal(
                      order: 5,
                      child: TextButton(
                        onPressed: onPrivacy,
                        child: Text(
                          en ? 'Privacy Policy' : 'سياسة الخصوصية',
                          style: AppTextStyles.labelMd().copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.sirati.textHint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Elevated hero card — surface + border + soft shadow so it reads as content.
class _ValueCard extends StatelessWidget {
  final String title;
  final String body;

  const _ValueCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl - 2),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sirati.border),
        boxShadow: context.sirati.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.sirati.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          Text(
            body,
            textAlign: TextAlign.start,
            style: AppTextStyles.bodySm().copyWith(
              height: 1.75,
              color: context.sirati.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return const SiratiMark(size: 88, elevated: true);
  }
}
