import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/analytics_service.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/form_fields.dart';
import '../widgets/language_toggle.dart';
import '../widgets/motion.dart';
import '../widgets/submit_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  /// When true, shows a one-shot "session expired" snackbar after first frame.
  final bool sessionExpiredNotice;

  const LoginScreen({super.key, this.sessionExpiredNotice = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthApiService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _submitted = false;
  bool _showFormBanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpiredNotice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final english = AppLocale.isEnglish(context);
        AppSnackBar.info(
          context,
          english
              ? 'Session expired, please log in again.'
              : 'انتهت الجلسة، سجّل الدخول مجدداً.',
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final english = AppLocale.isEnglish(context);
    setState(() {
      _submitted = true;
      _showFormBanner = false;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _showFormBanner = true);
      HapticFeedback.selectionClick();
      return;
    }
    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      AnalyticsService.logLoginSuccess(method: 'email');
      HapticFeedback.lightImpact();
      // Use pushAndRemoveUntil so HomeScreen becomes the root route.
      // This prevents the back button from popping back to the SplashScreen
      // (welcome/login UI) after the user is already authenticated.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: english ? 'Retry' : 'إعادة',
          onRetry: _login,
        );
      }
    } catch (_) {
      if (mounted) {
        _showError(english
            ? 'An unexpected error occurred while signing in.'
            : 'حدث خطأ غير متوقع أثناء تسجيل الدخول.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    final english = AppLocale.isEnglish(context);
    _showError(english
        ? 'Google sign-in is not enabled yet.'
        : 'تسجيل الدخول عبر Google غير مفعّل حالياً.');
  }

  Future<void> _loginWithApple() async {
    final english = AppLocale.isEnglish(context);
    _showError(english
        ? 'Apple sign-in is not enabled yet.'
        : 'تسجيل الدخول عبر Apple غير مفعّل حالياً.');
  }

  void _showError(String message) {
    AppSnackBar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      backgroundColor: context.sirati.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.sirati.surface,
              border: Border(
                bottom: BorderSide(
                    color: context.sirati.border.withValues(alpha: .5)),
              ),
            ),
            padding: EdgeInsetsDirectional.only(
              top: MediaQuery.of(context).padding.top + 16,
              start: 20,
              end: 12,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Spacer(),
                    LanguageToggle(),
                  ],
                ),
                SizedBox(height: 8),
                const SiratiMark(size: 56, elevated: true),
                SizedBox(height: 14),
                Text(
                  english ? 'Welcome to Sirati' : 'مرحباً بك في سيرتي',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.sirati.primary),
                ),
                SizedBox(height: 6),
                Text(
                  english ? 'Sign in to continue' : 'سجّل دخولك للمتابعة',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 14, color: context.sirati.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: AutofillGroup(
                child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showFormBanner)
                      AppFormErrorBanner(
                        message: english
                            ? 'Please fix the highlighted fields to continue.'
                            : 'يرجى تصحيح الحقول المحددة للمتابعة.',
                        onDismiss: () =>
                            setState(() => _showFormBanner = false),
                      ),
                    _AuthLabel(text: english ? 'Email' : 'البريد الإلكتروني'),
                    SizedBox(height: 6),
                    AppTextFormField(
                      controller: _emailController,
                      showSuccessWhenValid: true,
                      successMessage: english ? 'Looks good' : 'يبدو جيداً',
                      autovalidateMode: _submitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return english
                              ? 'Please enter your email'
                              : 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!v.contains('@')) {
                          return english
                              ? 'Email address is invalid'
                              : 'البريد الإلكتروني غير صحيح';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md),
                    _AuthLabel(text: english ? 'Password' : 'كلمة المرور'),
                    SizedBox(height: 6),
                    AppTextFormField(
                      controller: _passwordController,
                      showSuccessWhenValid: true,
                      autovalidateMode: _submitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (_) => _login(),
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return english
                              ? 'Please enter your password'
                              : 'يرجى إدخال كلمة المرور';
                        }
                        if (v.length < 6) {
                          return english
                              ? 'Password must be at least 6 characters'
                              : 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: Text(
                            english ? 'Forgot password?' : 'نسيت كلمة المرور؟'),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    SubmitButton(
                      label: english ? 'Sign in' : 'تسجيل الدخول',
                      loadingLabel:
                          english ? 'Signing in...' : 'جارٍ تسجيل الدخول...',
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(child: Divider(color: context.sirati.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            english ? 'Or continue with' : 'أو تابع بـ',
                            style: TextStyle(
                                fontSize: 13,
                                color: context.sirati.textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: context.sirati.border)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.g_mobiledata_rounded,
                            label: 'Google',
                            onTap: _loginWithGoogle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.apple,
                            label: 'Apple',
                            onTap: _loginWithApple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          english ? "Don't have an account?" : 'ليس لديك حساب؟',
                          style: TextStyle(
                              fontSize: 14,
                              color: context.sirati.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child:
                              Text(english ? 'Create account' : 'أنشئ حساباً'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLabel extends StatelessWidget {
  final String text;

  const _AuthLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.sirati.textSecondary,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.sirati.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.sirati.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: context.sirati.textPrimary),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.sirati.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
