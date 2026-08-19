import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../services/auth_token_store.dart';
import '../services/preference_store.dart';
import '../theme/app_theme.dart';
import '../utils/root_navigation.dart';
import '../widgets/language_toggle.dart';
import '../widgets/loading/branded_loader.dart';
import '../widgets/motion.dart';
import '../widgets/submit_button.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_policy_screen.dart';
import 'register_screen.dart';

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
    replaceRoot(context, const HomeScreen());
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

    replaceRoot(context, const LoginScreen());
  }

  void _goToRegister() {
    replaceRoot(context, const RegisterScreen());
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
      body: MotionStateSwitcher(
        stateKey: _phase.name,
        child: switch (_phase) {
          _SplashPhase.boot => const _BootstrapBody(),
          _SplashPhase.onboarding => OnboardingScreen(
              onFinished: _onOnboardingFinished,
            ),
          _SplashPhase.welcome => _WelcomeBody(
              onRegister: _goToRegister,
              onLogin: _goToLogin,
              onPrivacy: _openPrivacyPolicy,
            ),
        },
      ),
    );
  }
}

/// Brief branded hold while we check secure storage for an existing session.
class _BootstrapBody extends StatelessWidget {
  const _BootstrapBody();

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandedLoader(size: 72),
          const SizedBox(height: AppSpacing.md),
          Text(
            en ? 'Sirati' : 'سيرتي',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.sirati.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            en ? 'Preparing your workspace…' : 'جارٍ تجهيز مساحتك…',
            style: AppTextStyles.bodySm().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBody extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onPrivacy;

  const _WelcomeBody({
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
