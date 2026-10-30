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
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/theme/auth_hero_palette.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Shared by every sign-in method so they route and report alike.
void handleLoginOutcome(
  BuildContext context,
  LoginOutcome outcome, {
  required String method,
  required Future<void> Function() retry,
}) {
  final l10n = AppLocalizations.of(context);
  switch (outcome) {
    case LoginSucceeded(:final email, :final emailVerified):
      unawaited(AnalyticsService.logLoginSuccess(method: method));
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
        onRetry: () => unawaited(retry()),
      );
    case LoginFailedUnexpectedly():
      AppSnackBar.error(
        context,
        l10n.authLoginUnexpectedError,
      );
    case LoginProviderNotConfigured():
      AppSnackBar.error(
        context,
        l10n.authSocialSignInNotConfigured(
            method == 'google' ? l10n.authSocialGoogle : l10n.authSocialApple),
      );
    case LoginIgnored():
      break;
  }
}

/// "Or continue with" and the Google / Apple buttons, on Login and Register.
/// Renders nothing when the build offers neither provider.
class SocialSignInSection extends ConsumerWidget {
  const SocialSignInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialSignInOptionsProvider);
    if (!social.any) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    Future<void> google() async {
      final outcome =
          await ref.read(loginControllerProvider.notifier).signInWithGoogle();
      if (!context.mounted) return;
      handleLoginOutcome(context, outcome, method: 'google', retry: google);
    }

    Future<void> apple() async {
      final outcome =
          await ref.read(loginControllerProvider.notifier).signInWithApple();
      if (!context.mounted) return;
      handleLoginOutcome(context, outcome, method: 'apple', retry: apple);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        // The label wraps at large text sizes instead of overflowing, and the
        // two rules stay equal so it stays centred.
        LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(child: Divider(color: context.sirati.border)),
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    l10n.authOrContinueWith,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: context.sirati.textSecondary),
                  ),
                ),
              ),
              Expanded(child: Divider(color: context.sirati.border)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (social.google)
              Expanded(
                child: _SocialButton(
                  mark: const _GoogleMark(size: 20),
                  label: l10n.authSocialGoogle,
                  onTap: () => unawaited(google()),
                ),
              ),
            if (social.google && social.apple) const SizedBox(width: 12),
            if (social.apple)
              Expanded(
                child: _SocialButton(
                  mark: Icon(Icons.apple,
                      size: 22, color: context.sirati.textPrimary),
                  label: l10n.authSocialApple,
                  onTap: () => unawaited(apple()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget mark;
  final String label;
  final VoidCallback onTap;

  const _SocialButton(
      {required this.mark, required this.label, required this.onTap});

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
                mark,
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

/// Google's four-colour "G", drawn so the button needs no image asset.
class _GoogleMark extends StatelessWidget {
  final double size;

  const _GoogleMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    // Radians clockwise from 3 o'clock; the opening faces right.
    canvas
      ..drawArc(rect, -0.80, -1.55, false, arc(AuthHeroPalette.googleRed))
      ..drawArc(rect, -2.35, -1.60, false, arc(AuthHeroPalette.googleYellow))
      ..drawArc(rect, 2.33, -1.60, false, arc(AuthHeroPalette.googleGreen))
      ..drawArc(rect, 0.73, -0.73, false, arc(AuthHeroPalette.googleBlue))
      ..drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width - stroke / 2, size.height / 2),
        arc(AuthHeroPalette.googleBlue),
      );
  }

  @override
  bool shouldRepaint(_GoogleMarkPainter oldDelegate) => false;
}
