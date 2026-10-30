import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/latin_digits.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/password_strength_meter.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Two-step forgot password: request OTP → enter code + new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmKey = GlobalKey<FormFieldState<String>>();

  bool _isLoading = false;
  bool _isResending = false;
  bool _submitted = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _sendCode({bool isResend = false}) async {
    // One request at a time: keyboard Done, the button, Resend and the
    // snackbar Retry can all fire while one is running.
    if (_isLoading || _isResending) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
    });

    if (!_codeSent) {
      if (!_formKey.currentState!.validate()) {
        unawaited(HapticFeedback.selectionClick());
        return;
      }
    } else if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      AppSnackBar.error(
        context,
        l10n.authForgotEmailInvalidNotice,
      );
      return;
    }

    setState(() {
      if (isResend) {
        _isResending = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      await ref.read(authApiServiceProvider).forgotPassword(
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _submitted = false;
      });
      _startCooldown(60);
      unawaited(HapticFeedback.lightImpact());
      AppSnackBar.success(context, l10n.authForgotCodeSent);
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: l10n.authRetry,
          onRetry: () => _sendCode(isResend: isResend),
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          l10n.authForgotSendFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isResending = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authApiServiceProvider).resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
          );
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact());
      AppSnackBar.success(context, l10n.authForgotPasswordReset);
      Navigator.of(context).pop();
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: l10n.authRetry,
          onRetry: _resetPassword,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          l10n.authForgotResetFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authForgotTitle),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: AuthFormConstraint(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            children: [
              Text(
                _codeSent
                    ? l10n.authForgotCodeIntro
                    : l10n.authForgotEmailIntro,
                textAlign: TextAlign.start,
                style: AppTextStyles.titleMd(context.sirati)
                    .copyWith(fontSize: 17, height: 1.55),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.authEmailAddressLabel,
                textAlign: TextAlign.start,
                style: AppTextStyles.labelMd(context.sirati)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _emailController,
                enabled: !_codeSent,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                textInputAction:
                    _codeSent ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_codeSent) unawaited(_sendCode());
                },
                hintText: l10n.authEmailHint,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  if (_codeSent) return null;
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return l10n.authEmailRequired;
                  }
                  if (!email.contains('@')) {
                    return l10n.authForgotEmailInvalid;
                  }
                  return null;
                },
              ),
              if (!_codeSent) ...[
                const SizedBox(height: AppSpacing.md),
                SubmitButton(
                  label: l10n.authForgotSendCode,
                  loadingLabel: l10n.authSending,
                  isLoading: _isLoading,
                  icon: Icons.send_outlined,
                  onPressed: _sendCode,
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.authVerificationCodeLabel,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.labelMd(context.sirati)
                      .copyWith(fontWeight: FontWeight.w700),
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
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  hintText: '••••••',
                  autofillHints: const [AutofillHints.oneTimeCode],
                  // Accepts codes typed on Arabic keyboards (٠-٩), unlike digitsOnly.
                  inputFormatters: const [
                    LatinDigitsInputFormatter(maxLength: 6)
                  ],
                  prefixIcon: const Icon(Icons.pin_outlined),
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (code.length != 6) {
                      return l10n.authCodeRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.authNewPasswordLabel,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.labelMd(context.sirati)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _passwordController,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.next,
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    if (_submitted) _confirmKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.authForgotNewPasswordRequired;
                    }
                    if (value.length < 8) {
                      return l10n.authPasswordTooShort(8);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                PasswordStrengthMeter(
                  password: _passwordController.text,
                  english: english,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.authForgotConfirmPasswordLabel,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.labelMd(context.sirati)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                AppTextFormField(
                  key: _confirmKey,
                  controller: _confirmController,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  obscureText: _obscureConfirm,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => unawaited(_resetPassword()),
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip:
                        _obscureConfirm ? l10n.showPassword : l10n.hidePassword,
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.authForgotConfirmPasswordRequired;
                    }
                    if (value != _passwordController.text) {
                      return l10n.authPasswordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SubmitButton(
                  label: l10n.authForgotResetButton,
                  loadingLabel: l10n.authSaving,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline,
                  onPressed: _resetPassword,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    // The countdown is information, not a dead control: keep it readable
                    // while the button is disabled.
                    style: TextButton.styleFrom(
                      disabledForegroundColor: context.sirati.textSecondary,
                    ),
                    onPressed: (_resendCooldown > 0 || _isResending)
                        ? null
                        : () => _sendCode(isResend: true),
                    child: Text(
                      _isResending
                          ? l10n.authSending
                          : _resendCooldown > 0
                              ? l10n.authResendCodeIn(_resendCooldown)
                              : l10n.authResendCode,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _codeSent = false;
                            _submitted = false;
                            _codeController.clear();
                            _passwordController.clear();
                            _confirmController.clear();
                          });
                        },
                  child: Text(
                    l10n.authForgotUseDifferentEmail,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
