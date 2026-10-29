import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/auth_hero_page.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Signed-out landing, as agreed in Salem's review (2026-10-24): logo, name
/// and brand slogan, one value card, then the two account actions and the
/// privacy link — on the same gradient hero as Login and Register.
class WelcomeBody extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onPrivacy;

  const WelcomeBody({
    super.key,
    required this.onRegister,
    required this.onLogin,
    required this.onPrivacy,
  });

  static const logoKey = ValueKey('welcome-logo');
  static const sloganKey = ValueKey('welcome-slogan');
  static const valueCardKey = ValueKey('welcome-value-card');

  /// The brand slogan from the agreed identity banner.
  static String slogan(AppLocalizations l10n) => l10n.dashboardWelcomeSlogan;

  static String valueTitle(AppLocalizations l10n) =>
      l10n.dashboardWelcomeValueTitle;

  static List<String> valuePoints(AppLocalizations l10n) => [
        l10n.dashboardWelcomePointBuild,
        l10n.dashboardWelcomePointAnalyze,
        l10n.dashboardWelcomePointTailor,
        l10n.dashboardWelcomePointLearning,
        l10n.dashboardWelcomePointJobs,
      ];

  /// One icon per value point, in [valuePoints] order.
  static const pointIcons = [
    Icons.description_outlined,
    Icons.task_alt_rounded,
    Icons.edit_note_rounded,
    Icons.school_outlined,
    Icons.apartment_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;

    return AuthHeroPage(
      size: AuthHeroSize.tall,
      title: l10n.welcomeToSirati,
      subtitle: slogan(l10n),
      markKey: logoKey,
      subtitleKey: sloganKey,
      cardKey: valueCardKey,
      card: MotionReveal(
        order: 1,
        child: _ValueCard(
          title: valueTitle(l10n),
          points: valuePoints(l10n),
        ),
      ),
      below: [
        const SizedBox(height: AppSpacing.xl),
        MotionReveal(
          order: 2,
          child: SubmitButton(
            label: l10n.createAccount,
            onPressed: onRegister,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        MotionReveal(
          order: 2,
          child: SubmitButton(
            label: l10n.signIn,
            outlined: true,
            onPressed: onLogin,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MotionReveal(
          order: 3,
          child: Center(
            child: TextButton(
              onPressed: onPrivacy,
              child: Text(
                l10n.dashboardWelcomePrivacyPolicy,
                style: AppTextStyles.labelMd(c).copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.textHint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The selling-point card body: a heading and one icon chip per thing the
/// app does. The surrounding card comes from [AuthHeroPage].
class _ValueCard extends StatelessWidget {
  final String title;
  final List<String> points;

  const _ValueCard({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (i, point) in points.indexed)
          Padding(
            padding: EdgeInsets.only(
                bottom: i == points.length - 1 ? 0 : AppSpacing.sm + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    WelcomeBody.pointIcons[i % WelcomeBody.pointIcons.length],
                    size: 20,
                    color: c.primaryInk,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      point,
                      textAlign: TextAlign.start,
                      style: AppTextStyles.bodySm(c).copyWith(
                        height: 1.6,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
