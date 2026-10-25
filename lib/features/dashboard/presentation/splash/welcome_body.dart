import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Signed-out landing, as agreed in Salem's review (2026-10-24): LinkedIn-style
/// hierarchy — logo, name and brand slogan, one value card, then the two
/// account actions and the privacy link.
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
  static String slogan({required bool english}) => english
      ? 'Every career path\npasses through our station'
      : 'عندما تسعى لتطوير مسارك المهني،\nلا بد أن تمر على محطتنا';

  static String valueTitle({required bool english}) =>
      english ? 'Your career starts with your CV' : 'مسارك المهني يبدأ من سيرتك';

  static List<String> valuePoints({required bool english}) => english
      ? const [
          'Build a CV that passes automated screening (ATS)',
          'Analyze your CV with an ATS check',
          'Tailor your CV to a job description',
          'Learning and career development',
          'Job openings in the government and private sectors',
        ]
      : const [
          'إنشاء سيرة ذاتية متوافقة مع أنظمة الفرز الآلي',
          'تحليل سيرتك بنظام ATS',
          'تعديل السيرة الذاتية لتلائم الوصف الوظيفي',
          'تعليم وتطوير مهني',
          'إعلانات لفرص وظيفية في القطاع الحكومي والقطاع الخاص',
        ];

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final c = context.sirati;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl + 4,
                  AppSpacing.lg - 2,
                  AppSpacing.xl + 4,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MotionReveal(
                      order: 0,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: LanguageToggle(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const MotionReveal(
                      order: 1,
                      offset: Offset(0, 0.04),
                      duration: MotionDurations.slow,
                      child: Center(
                        child: SiratiMark(key: logoKey, size: 96),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MotionReveal(
                      order: 2,
                      child: Text(
                        en ? 'Siratie' : 'سيرتي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: c.primaryInk,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MotionReveal(
                      order: 2,
                      child: Text(
                        slogan(english: en),
                        key: sloganKey,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd(c).copyWith(
                          height: 1.7,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    MotionReveal(
                      order: 3,
                      child: _ValueCard(
                        key: valueCardKey,
                        title: valueTitle(english: en),
                        points: valuePoints(english: en),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    MotionReveal(
                      order: 4,
                      child: SubmitButton(
                        label: en ? 'Create New Account' : 'إنشاء حساب جديد',
                        onPressed: onRegister,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    MotionReveal(
                      order: 4,
                      child: SubmitButton(
                        label: en ? 'Sign In' : 'تسجيل الدخول',
                        outlined: true,
                        onPressed: onLogin,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg - 2),
                    MotionReveal(
                      order: 5,
                      child: TextButton(
                        onPressed: onPrivacy,
                        child: Text(
                          en ? 'Privacy Policy' : 'سياسة الخصوصية',
                          style: AppTextStyles.labelMd(c).copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.textHint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The selling-point card: a heading and one check per thing the app does.
class _ValueCard extends StatelessWidget {
  final String title;
  final List<String> points;

  const _ValueCard({super.key, required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Column(
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
          const SizedBox(height: AppSpacing.sm + 2),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: c.primaryInk,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      point,
                      textAlign: TextAlign.start,
                      style: AppTextStyles.bodySm(c).copyWith(
                        height: 1.6,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
