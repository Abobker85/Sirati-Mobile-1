import 'package:flutter/material.dart';

import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/screen_header.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  bool _notified = false;

  void _onNotifyMe(bool english) {
    setState(() => _notified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          english
              ? 'Thank you! You will be notified as soon as educational content launches.'
              : 'شكراً لاهتمامك! سنقوم بإشعارك فور إطلاق المحتوى التعليمي.',
        ),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = constraints.maxWidth >= 1100
              ? 920.0
              : constraints.maxWidth >= 780
                  ? 760.0
                  : constraints.maxWidth;
          final horizontalPadding = AppSpacing.pageGutter(constraints.maxWidth);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  // This tab has no FAB and the shell Scaffold already reserves
                  // the bottom nav bar's height, so FAB-sized padding here was
                  // pure dead space at the end of the list.
                  AppSpacing.scrollBottomTab,
                ),
                children: [
                  ScreenHeader(
                    english: english,
                    title: english ? 'Education' : 'التعليم',
                    subtitle: english
                        ? 'Career development & professional courses'
                        : 'تطوير المسار المهني والدورات التدريبية',
                    avatarLabel: english ? 'E' : 'ت',
                    unreadCount: SessionCache.instance.unreadCount,
                    onNotifications: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    onAvatarTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  MotionReveal(
                    order: 0,
                    child: _ComingSoonHero(
                      english: english,
                      notified: _notified,
                      onNotify: () => _onNotifyMe(english),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MotionReveal(
                    order: 1,
                    child: Text(
                      english ? 'What is coming?' : 'ماذا ينتظرك قريباً؟',
                      textAlign: TextAlign.start,
                      style: AppTextStyles.titleMd(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MotionReveal(
                    order: 2,
                    child: _UpcomingFeatureCard(
                      icon: Icons.auto_stories_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                      title: english
                          ? 'Specialized Career Courses'
                          : 'دورات تدريبية متخصصة',
                      description: english
                          ? 'Intensive courses designed for high-demand skills in the Saudi market.'
                          : 'دورات مكثفة لتطوير المهارات الأكثر طلباً في سوق العمل السعودي.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  MotionReveal(
                    order: 3,
                    child: _UpcomingFeatureCard(
                      icon: Icons.record_voice_over_rounded,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFFCCFBF1),
                      title: english
                          ? 'AI Interview Preparation'
                          : 'تحضير المقابلات بالذكاء الاصطناعي',
                      description: english
                          ? 'Simulate job interviews with expected questions and instant feedback.'
                          : 'محاكاة للمقابلات الوظيفية وأسئلة متوقعة ونصائح لتجاوزها بنجاح.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  MotionReveal(
                    order: 4,
                    child: _UpcomingFeatureCard(
                      icon: Icons.verified_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFEDE9FE),
                      title: english
                          ? 'ATS Optimization Guides'
                          : 'أدلة التوافق مع أنظمة ATS',
                      description: english
                          ? 'Practical guidelines on formatting, keywords, and recruiter requirements.'
                          : 'إرشادات عملية لتنسيق السيرة الذاتية واختيار الكلمات المفتاحية الأنسب.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  MotionReveal(
                    order: 5,
                    child: _CvCtaCard(english: english),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComingSoonHero extends StatelessWidget {
  final bool english;
  final bool notified;
  final VoidCallback onNotify;

  const _ComingSoonHero({
    required this.english,
    required this.notified,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.sirati.primaryLight.withValues(alpha: 0.4),
            context.sirati.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.sirati.primary.withValues(alpha: 0.2),
        ),
        boxShadow: context.sirati.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.sirati.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.sirati.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.sirati.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              english ? '✨ COMING SOON' : '✨ قريباً في سيرتي',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.sirati.primaryDark,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            english
                ? 'Educational Hub & Courses'
                : 'القسم التعليمي والدورات المهنية',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLg(),
          ),
          const SizedBox(height: 8),
          Text(
            english
                ? 'We are building interactive courses, interview guides, and certifications to accelerate your career.'
                : 'نعمل حالياً على تجهيز دورات تفاعلية وأدلة لاجتياز المقابلات الوظيفية وتطوير مسارك المهني.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd().copyWith(
              color: context.sirati.textHint,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          PressScale(
            child: ElevatedButton.icon(
              onPressed: notified ? null : onNotify,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.sirati.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                notified
                    ? Icons.check_circle_rounded
                    : Icons.notifications_active_rounded,
                size: 18,
              ),
              label: Text(
                notified
                    ? (english ? 'Interest Registered' : 'تم تسجيل اهتمامك')
                    : (english ? 'Notify Me on Launch' : 'أبلغني عند الإطلاق'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _UpcomingFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sirati.border),
        boxShadow: context.sirati.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.titleSm(),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.bodySm().copyWith(
                    color: context.sirati.textHint,
                    height: 1.45,
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

class _CvCtaCard extends StatelessWidget {
  final bool english;

  const _CvCtaCard({required this.english});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.sirati.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  english
                      ? 'Ready to build your CV now?'
                      : 'جاهز لإنشاء سيرتك الذاتية الآن؟',
                  textAlign: TextAlign.start,
                  style: AppTextStyles.titleSm(),
                ),
                const SizedBox(height: 4),
                Text(
                  english
                      ? 'Create an ATS-optimized CV in simple steps.'
                      : 'أنشئ سيرة احترافية متوافقة مع ATS بخطوات بسيطة.',
                  textAlign: TextAlign.start,
                  style: AppTextStyles.bodySm().copyWith(
                    color: context.sirati.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PressScale(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CvGeneratorScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.sirati.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(english ? 'Create CV' : 'إنشاء سيرة'),
            ),
          ),
        ],
      ),
    );
  }
}
