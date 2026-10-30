import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_tab.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_template_picker.dart';
import 'package:sirati/features/dashboard/presentation/splash/splash_boot_body.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/features/settings/domain/notification_item.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../support/contrast_probe.dart';
import 'jobs/featured_job_card_font_weight_test.dart';

/// Surfaces whose constructors can be pumped without providers.
///
/// Welcome, privacy, and onboarding embed [LanguageToggle] (shared, still
/// requesting an unshipped weight on another branch), so they are not here.
void main() {
  setUp(() => AppLocale.languageCode.value = 'en');

  testWidgets('feature texts use only shipped font weights', (tester) async {
    tester.view.physicalSize = const Size(900, 4800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final job = JobNews.fromJson({
      'id': 1,
      'title': 'مهندس Platform Engineering',
      'body': 'Build services for منصة Sirati.',
      'company': 'Sirati',
      'location': 'Riyadh',
      'source_badge': 'Sirati',
      'is_verified': true,
      'is_tamheer': true,
      'apply_method': 'url',
      'apply_url': 'https://careers.sirati.example/jobs/1',
      'source_type': 'gov',
      'skills_required': ['Dart', 'إدارة المشاريع'],
      'salary_range': '15k',
      'published_at': '2026-10-19T08:00:00Z',
    });

    final subjects = <String, Widget>{
      'featured job card': FeaturedJobCard(
        item: job,
        english: true,
        onTap: () {},
      ),
      'job news card': JobNewsCard(
        item: job,
        english: true,
        onTap: () {},
      ),
      'job detail': JobNewsDetailScreen(item: job),
      'filters bar': Column(
        children: [
          PresetChips(
            english: true,
            selectedPreset: 'matched',
            onSelected: (_) {},
          ),
          RegionChips(selectedRegion: 'eastern', onSelected: (_) {}),
        ],
      ),
      'cv document card': Column(
        children: [
          for (final draft in [false, true])
            CvDocumentCard(
              item: CvListItem.fromJson({
                'id': draft ? 2 : 1,
                'title': 'سيرة Backend Developer',
                'badge': draft ? 'Draft' : 'ATS 92',
                'is_draft': draft,
                'can_download': !draft,
                'updated_at': '2026-10-18T08:00:00Z',
              }),
              onOpen: () {},
              onEdit: () {},
              onDelete: () {},
              onDownload: () {},
              onScan: () {},
            ),
        ],
      ),
      'template picker': CvTemplatePicker(
        english: true,
        templates: [
          _template(id: 1, name: 'Classic مهني', isDefault: true),
          _template(id: 2, name: 'Modern Split', isDefault: false),
        ],
      ),
      'score ring': const AnimatedScoreRing(
        score: 86,
        scoreColor: Color(0xFF0E4A42),
      ),
      'score tab': ScoreTab(
        analysis: CvAnalysis.fromJson({
          'keyword_source': 'category',
          'id': 1,
          'target_job_title': 'مهندس Backend',
          'score_total': 86,
          'grade': 'B',
          'job_match': 86,
          'ai_status': 'completed',
          'strengths': ['Clear summary'],
          'weaknesses': [
            {'title': 'Few metrics', 'suggestion': 'Quantify outcomes'},
          ],
          'keywords_found': ['PHP', 'Laravel'],
          'keywords_missing': ['Docker'],
          'quick_wins': ['Add measurable outcomes'],
          'criteria': [
            {'label': 'Structure', 'score': 7, 'max': 10},
            {'label': 'Keywords', 'score': 8, 'max': 10},
          ],
        }),
        english: true,
      ),
      'settings row unread': NotificationCard(
        item: NotificationItem.fromJson({
          'id': 1,
          'title': 'وظيفة جديدة: Platform Engineer',
          'body': 'A role in الرياض matches your CV.',
          'is_read': false,
          'created_at': '2026-10-20T08:00:00Z',
        }),
        onTap: () {},
      ),
      'settings row read': NotificationCard(
        item: NotificationItem.fromJson({
          'id': 2,
          'title': 'Reminder',
          'body': 'Finish your سيرة.',
          'is_read': true,
          'created_label': 'yesterday',
        }),
        onTap: () {},
      ),
      'splash reduced motion': const SplashBootBody(),
      'splash animated': const SplashBootBody(),
    };

    for (final entry in subjects.entries) {
      await tester.pumpWidget(
        _host(
          entry.value,
          reduceMotion: entry.key != 'splash animated',
        ),
      );
      await tester.pumpAndSettle();
      _expectShipped(entry.key);
    }
  });
}

Widget _host(Widget child, {required bool reduceMotion}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightFor(arabic: false),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, navigator) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: navigator!,
      );
    },
    home: Scaffold(body: child),
  );
}

void _expectShipped(String label) {
  final texts = find.byType(Text).evaluate();
  expect(texts, isNotEmpty, reason: label);
  for (final element in texts) {
    final paragraph = paragraphOf(element.renderObject!);
    final style = paragraph.text.style;
    final weight = style?.fontWeight ?? FontWeight.w400;
    expect(
      shippedFontWeights,
      contains(weight),
      reason: '$label rendered $weight',
    );
    // A style that loses the app font (e.g. a bare button textStyle) falls
    // back to the system font, which draws Arabic in another typeface.
    expect(
      style?.fontFamily,
      'IBM Plex Sans Arabic',
      reason: '$label rendered "${paragraph.text.toPlainText()}" '
          'in ${style?.fontFamily ?? 'the system font'}',
    );
  }
}

CvTemplate _template({
  required int id,
  required String name,
  required bool isDefault,
}) {
  return CvTemplate(
    id: id,
    slug: 'template-$id',
    name: name,
    nameAr: name,
    nameEn: name,
    previewImageUrl: null,
    languageDirection: 'rtl',
    supportedLanguages: const ['ar', 'en'],
    supportedSections: const ['summary'],
    isDefault: isDefault,
  );
}
