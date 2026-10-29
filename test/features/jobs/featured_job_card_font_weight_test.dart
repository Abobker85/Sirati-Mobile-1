import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// IBM Plex Sans Arabic files declared in pubspec.yaml.
const shippedFontWeights = <FontWeight>[
  FontWeight.w400,
  FontWeight.w600,
  FontWeight.w700,
];

void main() {
  testWidgets('FeaturedJobCard text uses only shipped font weights',
      (tester) async {
    AppLocale.languageCode.value = 'en';
    final job = JobNews.fromJson({
      'id': 1,
      'title': 'مهندس Platform Engineering',
      'body': 'Build services',
      'company': 'Sirati',
      'location': 'Riyadh',
      'source_badge': 'Sirati',
      'is_verified': true,
      'is_tamheer': true,
      'apply_method': 'url',
      'apply_url': 'https://careers.sirati.example/jobs/1',
      'source_type': 'gov',
      'skills_required': ['Dart'],
      'salary_range': '15k',
      'published_at': '2026-10-19T08:00:00Z',
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: FeaturedJobCard(item: job, english: true, onTap: () {}),
      ),
    ));
    await tester.pumpAndSettle();

    final texts = find.byType(Text).evaluate();
    expect(texts, isNotEmpty);
    for (final element in texts) {
      final style = (element.renderObject! as RenderParagraph).text.style!;
      final weight = style.fontWeight ?? FontWeight.w400;
      expect(shippedFontWeights, contains(weight));
    }
  });
}
