import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/auth/application/login_controller.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/features/auth/presentation/social_sign_in_section.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/auth_hero_page.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

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
    if (outcome is LoginSucceeded) {
      // Lets the platform password manager offer to save the credentials.
      TextInput.finishAutofillContext();
    }
    handleLoginOutcome(context, outcome, method: 'email', retry: _login);
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
      body: AuthHeroPage(
        size: AuthHeroSize.regular,
        title: l10n.welcomeToSirati,
        subtitle: l10n.authLoginSubtitle,
        card: _buildForm(context, l10n, isLoading),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context, AppLocalizations l10n, bool isLoading) {
    return AutofillGroup(
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
                onDismiss: () => setState(() => _showFormBanner = false),
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
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              hintText: l10n.authEmailHint,
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
                tooltip:
                    _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              // Presence only: the server has no length rule for
              // sign-in, and a client one can lock out accounts.
              validator: (v) => loginPasswordError(v) == null
                  ? null
                  : l10n.authPasswordRequired,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen()),
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
            const SocialSignInSection(),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.authNoAccount,
                  style: TextStyle(
                      fontSize: 14, color: context.sirati.textSecondary),
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
