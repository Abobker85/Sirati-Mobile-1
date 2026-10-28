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
const _loginHeroRadius = 32.0;
const _loginCardRadius = 24.0;
const _loginCardOverlap = 28.0;

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
    _handleOutcome(outcome, method: 'email', retry: _login);
  }

  /// Shared by every sign-in method so they route and report alike.
  void _handleOutcome(
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
          l10n.authSocialSignInNotConfigured(_providerLabel(method)),
        );
      case LoginIgnored():
        break;
    }
  }

  static String _providerLabel(String method) =>
      method == 'google' ? 'Google' : 'Apple';

  Future<void> _loginWithGoogle() async {
    final outcome =
        await ref.read(loginControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    _handleOutcome(outcome, method: 'google', retry: _loginWithGoogle);
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
    final social = ref.watch(socialSignInOptionsProvider);
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the dark hero.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.sirati.background,
        body: AuthFormConstraint(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Height the body can actually use, including a keyboard that
              // shrinks the scaffold. Full-screen size stays tall while typing.
              final compact = constraints.maxHeight < _loginCompactHeaderExtent;
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: insets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LoginHero(
                      compact: compact,
                      topInset: insets.top,
                      title: l10n.welcomeToSirati,
                      subtitle: l10n.authLoginSubtitle,
                    ),
                    // The form card rides up over the hero's rounded edge.
                    Transform.translate(
                      offset: const Offset(0, -_loginCardOverlap),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.sirati.surface,
                            borderRadius:
                                BorderRadius.circular(_loginCardRadius),
                            border: Border.all(color: context.sirati.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                                compact ? AppSpacing.md : AppSpacing.xl),
                            child: _buildForm(context, l10n, isLoading, social),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n, bool isLoading,
      SocialSignInOptions social) {
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
            if (social.any) ...[
              const SizedBox(height: AppSpacing.xl),
              // The label wraps at large text sizes instead of overflowing,
              // and the two rules stay equal so it stays centred.
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
                              fontSize: 13,
                              color: context.sirati.textSecondary),
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
                        label: 'Google',
                        onTap: _loginWithGoogle,
                      ),
                    ),
                  if (social.google && social.apple) const SizedBox(width: 12),
                  if (social.apple)
                    Expanded(
                      child: _SocialButton(
                        mark: Icon(Icons.apple,
                            size: 22, color: context.sirati.textPrimary),
                        label: 'Apple',
                        onTap: _loginWithApple,
                      ),
                    ),
                ],
              ),
            ],
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

/// Full-bleed brand band: the logo's gradient under a fading grid, with the
/// mark and the welcome copy in white.
class _LoginHero extends StatelessWidget {
  final bool compact;
  final double topInset;
  final String title;
  final String subtitle;

  const _LoginHero({
    required this.compact,
    required this.topInset,
    required this.title,
    required this.subtitle,
  });

  /// The logo's gradient with the teal end deepened so white copy keeps AA
  /// against every stop.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12384F), Color(0xFF0B7A72)],
  );

  @override
  Widget build(BuildContext context) {
    final gap = compact ? AppSpacing.xs : AppSpacing.md;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_loginHeroRadius),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_loginHeroRadius),
        ),
        child: CustomPaint(
          painter: const _HeroGridPainter(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              topInset + (compact ? AppSpacing.xxs : AppSpacing.xs),
              AppSpacing.md,
              _loginCardOverlap + (compact ? AppSpacing.md : AppSpacing.xxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const DirectionalIcon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    const Spacer(),
                    const LanguageToggle(
                      backgroundColor: Color(0x24000000),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Color(0x4DFFFFFF)),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 0 : AppSpacing.xs),
                Center(
                  child: SiratiMark(
                    size: compact ? _loginCompactMarkSize : _loginMarkSize,
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    compact ? AppTypography.titleLg : AppTypography.headlineMd,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    AppTypography.bodyMd,
                    color: Colors.white,
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

/// Thin white grid that fades out toward the bottom of the hero.
class _HeroGridPainter extends CustomPainter {
  static const cell = 24.0;

  const _HeroGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);
    for (var x = cell; x < size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = cell; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HeroGridPainter oldDelegate) => false;
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
      ..drawArc(rect, -0.80, -1.55, false, arc(const Color(0xFFEA4335)))
      ..drawArc(rect, -2.35, -1.60, false, arc(const Color(0xFFFBBC05)))
      ..drawArc(rect, 2.33, -1.60, false, arc(const Color(0xFF34A853)))
      ..drawArc(rect, 0.73, -0.73, false, arc(const Color(0xFF4285F4)))
      ..drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width - stroke / 2, size.height / 2),
        arc(const Color(0xFF4285F4)),
      );
  }

  @override
  bool shouldRepaint(_GoogleMarkPainter oldDelegate) => false;
}
