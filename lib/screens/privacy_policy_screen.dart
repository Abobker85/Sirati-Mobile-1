import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'Privacy Policy' : 'سياسة الخصوصية'),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _Section(
            title: english ? 'What We Collect' : 'ما البيانات التي نجمعها؟',
            body: english
                ? 'We collect account details (name, email, optional phone and location), the CV content you enter or upload, analysis results, and a device push-notification token (FCM) so Sirati can analyze, improve, save, and notify you about your CVs.'
                : 'نجمع بيانات الحساب (الاسم، البريد، والجوال والموقع اختياريًا)، ومحتوى السيرة الذي تدخله أو ترفعه، ونتائج التحليل، ورمز إشعارات الجهاز (FCM) حتى نتمكن من تحليل سيرتك وتحسينها وحفظها وإرسال الإشعارات.',
          ),
          _Section(
            title: english ? 'How We Use It' : 'كيف نستخدم البيانات؟',
            body: english
                ? 'Your data is used to calculate ATS scores, generate improved CVs, show your history, personalize the dashboard, and deliver optional push notifications. We do not use your data for advertising tracking.'
                : 'نستخدم بياناتك لحساب درجة ATS، وإنشاء سير محسنة، وعرض السجل، وتخصيص لوحة التحكم، وإرسال إشعارات اختيارية. لا نستخدم بياناتك لتتبع الإعلانات.',
          ),
          _Section(
            title: english ? 'Sharing' : 'مشاركة البيانات',
            body: english
                ? 'We do not sell your data. AI processing only happens when the backend AI provider is configured.'
                : 'لا نبيع بياناتك. تتم معالجة الذكاء الاصطناعي فقط عند تفعيل مزود الذكاء الاصطناعي في الخادم.',
          ),
          _Section(
            title: english ? 'Deleting Data' : 'حذف البيانات',
            body: english
                ? 'You can delete individual generated CVs from My CVs. You can permanently delete your entire account from Settings → Delete account. That removes your profile, CVs, analyses, notifications, and push tokens from our systems. This cannot be undone.'
                : 'يمكنك حذف السير الفردية من شاشة سيراتي. ويمكنك حذف حسابك بالكامل من الإعدادات ← حذف الحساب. يزيل ذلك ملفك والسير والتحليلات والإشعارات ورموز الدفع من أنظمتنا. لا يمكن التراجع عن هذا الإجراء.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.sirati.border.withValues(alpha: .7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: context.sirati.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: context.sirati.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
