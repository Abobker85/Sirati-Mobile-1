import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/root_navigation.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/auth_form_constraint.dart';
import '../widgets/form_fields.dart';
import '../widgets/language_toggle.dart';
import '../widgets/submit_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// 6-digit OTP email verification after register / unverified login.
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  /// When true, clears session and returns to login instead of popping.
  final bool isGate;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.isGate = true,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _auth = AuthApiService();

  bool _isLoading = false;
  bool _isResending = false;
  bool _submitted = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final english = AppLocale.isEnglish(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.verifyEmail(code: _codeController.text.trim());
      if (!mounted) return;
      HapticFeedback.lightImpact();
      AppSnackBar.success(
        context,
        english ? 'Email verified successfully.' : 'تم تأكيد البريد بنجاح.',
      );
      replaceRoot(context, const HomeScreen());
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: english ? 'Retry' : 'إعادة',
          onRetry: _verify,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          english
              ? 'An unexpected error occurred while verifying.'
              : 'حدث خطأ غير متوقع أثناء التحقق.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    final english = AppLocale.isEnglish(context);
    setState(() => _isResending = true);
    try {
      final message = await _auth.resendVerification();
      if (!mounted) return;
      _startCooldown(60);
      AppSnackBar.success(context, message);
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(context, exception);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          english
              ? 'Could not resend the code. Try again later.'
              : 'تعذر إعادة إرسال الرمز. حاول لاحقاً.',
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _leave() async {
    await _auth.logout();
    if (!mounted) return;
    replaceRoot(context, const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final email = widget.email;

    return Scaffold(
      backgroundColor: context.sirati.background,
      body: SafeArea(
        child: AuthFormConstraint(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _leave,
                    tooltip:
                        english ? 'Back to sign in' : 'العودة لتسجيل الدخول',
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.sirati.textPrimary,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  const LanguageToggle(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: context.sirati.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 36,
                            color: context.sirati.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        english ? 'Verify your email' : 'أكد بريدك الإلكتروني',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.sirati.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        english
                            ? 'We sent a 6-digit code to'
                            : 'أرسلنا رمزاً من 6 أرقام إلى',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: context.sirati.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.sirati.primary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        english ? 'Verification code' : 'رمز التحقق',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.sirati.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextFormField(
                        controller: _codeController,
                        autovalidateMode: _submitted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _verify(),
                        maxLength: 6,
                        hintText: '••••••',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        prefixIcon: const Icon(Icons.pin_outlined),
                        validator: (value) {
                          final code = value?.trim() ?? '';
                          if (code.length != 6) {
                            return english
                                ? 'Enter the 6-digit code'
                                : 'أدخل الرمز المكون من 6 أرقام';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SubmitButton(
                        label: english ? 'Verify email' : 'تأكيد البريد',
                        loadingLabel:
                            english ? 'Verifying...' : 'جارٍ التحقق...',
                        isLoading: _isLoading,
                        icon: Icons.verified_outlined,
                        onPressed: _verify,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: TextButton(
                          onPressed: (_resendCooldown > 0 || _isResending)
                              ? null
                              : _resend,
                          child: Text(
                            _isResending
                                ? (english ? 'Sending...' : 'جارٍ الإرسال...')
                                : _resendCooldown > 0
                                    ? (english
                                        ? 'Resend code in $_resendCooldown s'
                                        : 'إعادة الإرسال بعد $_resendCooldown ث')
                                    : (english
                                        ? 'Resend code'
                                        : 'إعادة إرسال الرمز'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        english
                            ? 'Check spam if you do not see the email.'
                            : 'تحقق من البريد المزعج إن لم تجد الرسالة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.sirati.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
