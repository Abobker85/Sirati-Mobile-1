import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/auth_hero_page.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Shown to a guest ("Continue without account") who opens something that
/// needs an account. Unlike the session-expired screen nobody was signed out:
/// it invites them to sign in, and points back to what stays open (jobs and
/// learning).
class SignInRequiredScreen extends StatelessWidget {
  const SignInRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sirati.background,
      body: SignInRequiredView(
        onBrowseJobs: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// The sign-in invitation as a page body, so the Home shell can show it in
/// place of a tab that needs an account.
class SignInRequiredView extends StatelessWidget {
  /// Takes the guest back to what is open to them.
  final VoidCallback onBrowseJobs;

  /// False when shown in place of a tab, which has nothing to go back to.
  final bool showBack;

  const SignInRequiredView({
    super.key,
    required this.onBrowseJobs,
    this.showBack = true,
  });

  static const cardKey = ValueKey('sign-in-required-card');

  void _open(BuildContext context, Widget screen) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;
    return AuthHeroPage(
      size: AuthHeroSize.regular,
      title: l10n.authSignInRequiredTitle,
      subtitle: l10n.authSignInRequiredSubtitle,
      cardKey: cardKey,
      showBack: showBack ? null : false,
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.lock_outline_rounded,
                  size: 28, color: c.primaryInk),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.authSignInRequiredCardTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.authSignInRequiredBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm(c).copyWith(
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SubmitButton(
            label: l10n.createAccount,
            onPressed: () => _open(context, const RegisterScreen()),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          SubmitButton(
            label: l10n.signIn,
            outlined: true,
            onPressed: () => _open(context, const LoginScreen()),
          ),
        ],
      ),
      below: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: onBrowseJobs,
            icon: const Icon(Icons.work_outline_rounded, size: 18),
            label: Text(l10n.authSignInRequiredBrowseJobs),
          ),
        ),
      ],
    );
  }
}
