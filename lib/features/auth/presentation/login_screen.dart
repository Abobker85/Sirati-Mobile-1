import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/utils/root_navigation.dart';
import 'package:sirati/features/auth/application/login_controller.dart';
import 'package:sirati/features/auth/domain/social_sign_in.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Branding collapses below this viewport height so the form can move up.
const _loginCompactHeaderExtent = 520.0;

const _loginMarkSize = 56.0;
const _loginCompactMarkSize = 40.0;

class LoginScreen extends ConsumerStatefulWidget {
  /// When true, shows a one-shot "session expired" snackbar after first frame.
  final bool sessionExpiredNotice;

  const LoginScreen({super.key, this.sessionExpiredNotice = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;
  bool _showFormBanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpiredNotice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackBar.info(
          context,
          AppLocalizations.of(context).authSessionExpired,
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
    if (ref.read(loginControllerProvider)) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
      _showFormBanner = false;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _showFormBanner = true);
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    final outcome = await ref.read(loginControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    switch (outcome) {
      case LoginSucceeded(:final email, :final emailVerified):
        // Lets the platform password manager offer to save the credentials.
        TextInput.finishAutofillContext();
        unawaited(AnalyticsService.logLoginSuccess(method: 'email'));
        unawaited(HapticFeedback.lightImpact());
        // Unverified accounts must complete email OTP before using the app.
        if (!emailVerified) {
          replaceRoot(context, EmailVerificationScreen(email: email));
          return;
        }
        AppRouter.openAfterAuth(context);
      case LoginRejected(:final error):
        AppSnackBar.fromException(
          context,
          error,
          retryLabel: l10n.authRetry,
          onRetry: () => unawaited(_login()),
        );
      case LoginFailedUnexpectedly():
        AppSnackBar.error(
          context,
          l10n.authLoginUnexpectedError,
        );
      case LoginIgnored():
        break;
    }
  }

  Future<void> _loginWithGoogle() async {
    AppSnackBar.info(
      context,
      AppLocalizations.of(context).authSocialSignInSoon('Google'),
    );
  }

  Future<void> _loginWithApple() async {
    AppSnackBar.info(
      context,
      AppLocalizations.of(context).authSocialSignInSoon('Apple'),
    );
  }

  void _goToRegister() {
    final navigator = Navigator.of(context);
    final route =
        MaterialPageRoute<void>(builder: (_) => const RegisterScreen());
    // Replace when stacked (Login <-> Register ping-pong); push when Login is
    // the root so Back from Register returns here.
    unawaited(navigator.canPop()
        ? navigator.pushReplacement(route)
        : navigator.push(route));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = ref.watch(loginControllerProvider);
    return Scaffold(
      backgroundColor: context.sirati.background,
      body: AuthFormConstraint(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Height the body can actually use, including a keyboard that
            // shrinks the scaffold. Full-screen size stays tall while typing.
            final compact = constraints.maxHeight < _loginCompactHeaderExtent;
            final sectionGap = compact ? AppSpacing.sm : AppSpacing.xl;
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  compact ? AppSpacing.xs : AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.sirati.surface,
                        border: Border(
                          bottom: BorderSide(color: context.sirati.outline),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                if (Navigator.of(context).canPop())
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                    tooltip: MaterialLocalizations.of(context)
                                        .backButtonTooltip,
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
                            SizedBox(height: sectionGap),
                            Center(
                              child: SiratiMark(
                                size: compact
                                    ? _loginCompactMarkSize
                                    : _loginMarkSize,
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            Text(
                              l10n.welcomeToSirati,
                              textAlign: TextAlign.center,
                              style: AppTypography.of(
                                context,
                                compact
                                    ? AppTypography.titleLg
                                    : AppTypography.headlineMd,
                                color: context.sirati.primaryInk,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.authLoginSubtitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.of(
                                context,
                                AppTypography.bodyMd,
                                color: context.sirati.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    AutofillGroup(
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
                                message: l10n.authFixHighlightedFields,
                                onDismiss: () =>
                                    setState(() => _showFormBanner = false),
                              ),
                            _AuthLabel(text: l10n.emailLabel),
                            const SizedBox(height: 6),
                            AppTextFormField(
                              controller: _emailController,
                              showSuccessWhenValid: true,
                              successMessage: l10n.authLooksGood,
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.start,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              hintText: 'name@example.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.authEmailRequired;
                                }
                                if (!v.contains('@')) {
                                  return l10n.authEmailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _AuthLabel(text: l10n.authPasswordLabel),
                            const SizedBox(height: 6),
                            AppTextFormField(
                              controller: _passwordController,
                              showSuccessWhenValid: true,
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.start,
                              textInputAction: TextInputAction.send,
                              onFieldSubmitted: (_) => unawaited(_login()),
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? l10n.showPassword
                                    : l10n.hidePassword,
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              // Presence only: the server has no length rule for
                              // sign-in, and a client one can lock out accounts.
                              validator: (v) => loginPasswordError(v) == null
                                  ? null
                                  : l10n.authPasswordRequired,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()),
                                ),
                                child: Text(l10n.authForgotPasswordLink),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SubmitButton(
                              label: l10n.authSignInButton,
                              loadingLabel: l10n.authSigningIn,
                              isLoading: isLoading,
                              onPressed: () => unawaited(_login()),
                            ),
                            if (socialSignInEnabled) ...[
                              const SizedBox(height: AppSpacing.xl),
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: context.sirati.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    child: Text(
                                      l10n.authOrContinueWith,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: context.sirati.textSecondary),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: context.sirati.border)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: 'Google',
                                      onTap: _loginWithGoogle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.apple,
                                      label: 'Apple',
                                      onTap: _loginWithApple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 28),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  l10n.authNoAccount,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: context.sirati.textSecondary),
                                ),
                                TextButton(
                                  onPressed: _goToRegister,
                                  child: Text(l10n.authCreateAccountLink),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
                const SizedBox(width: 8),
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
