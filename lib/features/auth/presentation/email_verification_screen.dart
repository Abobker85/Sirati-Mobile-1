import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/utils/latin_digits.dart';
import 'package:sirati/core/utils/root_navigation.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/form_reveal.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';
import 'package:sirati/shared/widgets/success_beat.dart';

/// 6-digit OTP email verification after register / unverified login.
///
/// Always shown as the root route: leaving (on-screen or system Back) signs
/// out and returns to Login, so an unverified session never lingers.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _leaving = false;

  bool _isLoading = false;
  bool _isResending = false;
  bool _submitted = false;
  bool _verified = false;
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
    // One request at a time: auto-submit, keyboard Done, the button and the
    // snackbar Retry can all fire.
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (!validateAndReveal(_formKey)) {
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authApiServiceProvider)
          .verifyEmail(code: _codeController.text.trim());
      if (!mounted) return;
      setState(() => _verified = true);
      unawaited(SuccessBeat.celebrate(context));
      AppSnackBar.success(
        context,
        l10n.authVerifySuccess,
      );
      AppRouter.openAfterAuth(context);
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: l10n.authRetry,
          onRetry: () => unawaited(_verify()),
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          l10n.authVerifyUnexpectedError,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isResending = true);
    try {
      await ref.read(authApiServiceProvider).resendVerification();
      if (!mounted) return;
      _startCooldown(60);
      AppSnackBar.success(context, l10n.authVerifyCodeResent);
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(context, exception);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          l10n.authVerifyResendFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      await ref.read(authApiServiceProvider).logout();
    } catch (error) {
      if (!mounted) return;
      if (error is LocalSessionCleanupException && error.tokenCleared) {
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).logOutPartial,
        );
      } else {
        // Keep a session whose token could not be removed on this screen.
        _leaving = false;
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).logOutFailed,
        );
        return;
      }
    }
    if (!mounted) return;
    replaceRoot(context, const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = widget.email;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: context.sirati.background,
        body: SafeArea(
          child: AuthFormConstraint(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => unawaited(_leave()),
                        tooltip: l10n.authVerifyBackToSignIn,
                        icon: DirectionalIcon(
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
                          MotionReveal(
                            order: 0,
                            child: Center(
                              child: AnimatedContainer(
                                duration: MotionSettings.reduce(context)
                                    ? Duration.zero
                                    : MotionDurations.medium,
                                curve: MotionCurves.state,
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _verified
                                      ? context.sirati.successLight
                                      : context.sirati.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: MotionMorph(
                                  morphKey: _verified,
                                  child: LivelyIcon(
                                    _verified
                                        ? Icons.verified_rounded
                                        : Icons.mark_email_unread_outlined,
                                    size: 36,
                                    color: _verified
                                        ? context.sirati.onSuccessContainer
                                        : context.sirati.primaryInk,
                                    life: _verified
                                        ? IconLife.none
                                        : IconLife.float,
                                    plays: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.authVerifyTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: context.sirati.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.authVerifyCodeSentTo,
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
                              color: context.sirati.primaryInk,
                            ),
                          ),
                          const SizedBox(height: 28),
                          MotionReveal(
                            order: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.authVerificationCodeLabel,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.sirati.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _codeController,
                                  builder: (context, value, _) =>
                                      _OtpProgressDots(
                                    filledCount: value.text.trim().length,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AppTextFormField(
                                  controller: _codeController,
                                  autovalidateMode: _submitted
                                      ? AutovalidateMode.onUserInteraction
                                      : AutovalidateMode.disabled,
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.center,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => unawaited(_verify()),
                                  // Submit as soon as the full code is in (typed,
                                  // pasted, or autofilled).
                                  onChanged: (value) {
                                    if (value.length == 6) {
                                      unawaited(_verify());
                                    }
                                  },
                                  maxLength: 6,
                                  hintText: '••••••',
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode
                                  ],
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
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          MotionReveal(
                            order: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SubmitButton(
                                  label: l10n.authVerifyButton,
                                  loadingLabel: l10n.authVerifying,
                                  isLoading: _isLoading,
                                  icon: Icons.verified_outlined,
                                  onPressed: () => unawaited(_verify()),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Center(
                                  child: TextButton(
                                    // The countdown is information, not a dead control: keep it readable
                                    // while the button is disabled.
                                    style: TextButton.styleFrom(
                                      disabledForegroundColor:
                                          context.sirati.textSecondary,
                                    ),
                                    onPressed:
                                        (_resendCooldown > 0 || _isResending)
                                            ? null
                                            : () => unawaited(_resend()),
                                    child: Text(
                                      _isResending
                                          ? l10n.authSending
                                          : _resendCooldown > 0
                                              ? l10n.authResendCodeIn(
                                                  _resendCooldown)
                                              : l10n.authResendCode,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.authVerifyCheckSpam,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: context.sirati.textHint,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}

/// 6-dot progress indicator tied to the OTP input length.
class _OtpProgressDots extends StatelessWidget {
  const _OtpProgressDots({required this.filledCount});

  static const keyIndicator = ValueKey('otp-progress-dots');
  final int filledCount;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    final duration = reduce ? Duration.zero : MotionDurations.fast;
    final count = filledCount.clamp(0, 6);

    return ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          key: keyIndicator,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < count;
            final active = i == count && count < 6;
            return AnimatedContainer(
              duration: duration,
              curve: MotionCurves.state,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: filled ? 12 : (active ? 10 : 8),
              height: 8,
              decoration: BoxDecoration(
                color: filled
                    ? c.primary
                    : (active ? c.primaryLight : c.borderStrong),
                borderRadius: BorderRadius.circular(999),
                border: active
                    ? Border.all(color: c.primaryInk, width: 1.2)
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}
