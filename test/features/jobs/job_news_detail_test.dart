import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

JobNews _job({
  String? method = 'url',
  String? applyUrl = 'https://careers.acme.example/jobs/1',
  String? applyEmail,
  String? instructions,
  String? sourceUrl = 'https://t.me/jobmag/123',
}) =>
    JobNews.fromJson({
      'id': 1,
      'title': 'Backend Developer',
      'body': 'Build APIs with Laravel.',
      'category': 'tech',
      'skills_required': ['PHP', 'Laravel'],
      'company': 'Acme',
      'location': 'Riyadh',
      'source_name': '@jobmag',
      if (method != null) 'apply_method': method,
      'apply_url': applyUrl,
      'apply_email': applyEmail,
      'apply_instructions': instructions,
      'source_url': sourceUrl,
      'url': sourceUrl,
    });

/// Every apply shape the screen can receive, including legacy payloads whose
/// "apply" link is the Telegram post.
final _variants = <String, JobNews>{
  'link': _job(),
  'email': _job(method: 'email', applyUrl: null, applyEmail: 'HR@Acme.example'),
  'none':
      _job(method: 'none', applyUrl: null, instructions: 'WhatsApp 0551234567'),
  'legacy telegram': _job(method: null, applyUrl: 'https://t.me/jobmag/123'),
  'denied link sent as url': _job(applyUrl: 'https://www.instagram.com/acme'),
};

void main() {
  group('CvTargetJob', () {
    test('trims and clips to the generator limits', () {
      final job = CvTargetJob(
        title: '  ${'t' * 300}  ',
        description: '  ${'d' * 5000}  ',
      );
      expect(job.title.length, CvTargetJob.titleMax);
      expect(job.description.length, CvTargetJob.descriptionMax);
      final short = CvTargetJob(title: ' Dev ', description: ' JD ');
      expect((short.title, short.description), ('Dev', 'JD'));
    });

    test('never cuts a surrogate pair in half', () {
      // 😀 is two UTF-16 units; place one across the cut point.
      final title = '${'a' * (CvTargetJob.titleMax - 1)}😀tail';
      final clipped = CvTargetJob(title: title, description: '').title;
      expect(clipped.length, lessThanOrEqualTo(CvTargetJob.titleMax));
      final last = clipped.codeUnitAt(clipped.length - 1);
      expect(last >= 0xD800 && last <= 0xDBFF, isFalse);
    });
  });

  group('JobNewsDetailScreen', () {
    setUp(() => AppLocale.languageCode.value = 'en');

    Widget app(JobNews job, ThemeData theme, {RouteFactory? onRoute}) =>
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: JobNewsDetailScreen(item: job),
          onGenerateRoute: onRoute,
        );

    AppLocalizations l10n(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(JobNewsDetailScreen)));

    for (final MapEntry(key: name, value: job) in _variants.entries) {
      testWidgets(
          '$name: the primary action is a real application or tailoring',
          (tester) async {
        tester.view.physicalSize = const Size(1080, 3600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(job, AppTheme.lightFor(arabic: false)));
        await tester.pumpAndSettle();
        final l = l10n(tester);

        final expectsLink = name == 'link';
        final expectsEmail = name == 'email';
        expect(find.widgetWithText(FilledButton, l.jobsApplyNow),
            expectsLink ? findsOneWidget : findsNothing);
        expect(find.widgetWithText(FilledButton, l.jobsApplyByEmail),
            expectsEmail ? findsOneWidget : findsNothing);
        expect(find.widgetWithText(FilledButton, l.jobsTailorCv),
            expectsLink || expectsEmail ? findsNothing : findsOneWidget);
        if (!expectsLink && !expectsEmail) {
          expect(find.text(l.jobsNoDirectApply), findsOneWidget);
        }

        // Telegram/social never appears as an apply destination…
        for (final host in ['t.me', 'instagram.com']) {
          expect(find.text(l.jobsApplyOpensHost(host)), findsNothing);
        }
        // …only as the labelled original post.
        expect(find.text(l.jobsViewSourcePost), findsOneWidget);

        // No match percentage anywhere.
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
        expect(texts.where((t) => RegExp(r'\d+\s*%').hasMatch(t)), isEmpty);
      });
    }

    testWidgets('the description follows the post language in either app',
        (tester) async {
      const bodies = {
        'en': 'Build APIs with Laravel and Flutter.',
        'ar': 'مطلوب مطور تطبيقات Flutter للعمل في الرياض.',
      };
      for (final appLanguage in ['en', 'ar']) {
        for (final MapEntry(key: postLanguage, value: body)
            in bodies.entries) {
          AppLocale.languageCode.value = appLanguage;
          final job = JobNews.fromJson(
              {'id': 3, 'title': 't', 'body': body, 'language': postLanguage});
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.lightFor(arabic: appLanguage == 'ar'),
            locale: Locale(appLanguage),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: JobNewsDetailScreen(item: job),
          ));
          await tester.pumpAndSettle();
          final text = tester.widget<Text>(find.byWidgetPredicate((w) =>
              w is Text && (w.data ?? '').contains(body.split(' ').last)));
          expect(
              text.textDirection,
              postLanguage == 'en' ? TextDirection.ltr : TextDirection.rtl,
              reason: 'app=$appLanguage post=$postLanguage');
        }
      }
      AppLocale.languageCode.value = 'en';
    });

    testWidgets('an internal retirement date is never shown as a deadline',
        (tester) async {
      for (final (label, shown) in [
        (null, false),
        ('Apply by 30 Nov 2026', true)
      ]) {
        final job = JobNews.fromJson({
          'id': 9,
          'title': 'Backend Developer',
          'body': 'b',
          'valid_until': '2026-11-30',
          'valid_until_label': label,
        });
        await tester.pumpWidget(app(job, AppTheme.lightFor(arabic: false)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.event_rounded),
            shown ? findsOneWidget : findsNothing,
            reason: 'label=$label');
      }
    });

    testWidgets('email applications show the address and can copy it',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(
          app(_variants['email']!, AppTheme.lightFor(arabic: false)));
      await tester.pumpAndSettle();
      expect(find.text('hr@acme.example'), findsOneWidget);
      await tester.tap(find.text(l10n(tester).jobsCopyEmail));
      await tester.pump();
      expect(copied, 'hr@acme.example');
    });

    for (final name in ['link', 'none']) {
      testWidgets('Tailor carries this job into the CV generator ($name)',
          (tester) async {
        RouteSettings? pushed;
        await tester.pumpWidget(app(
          _variants[name]!,
          AppTheme.lightFor(arabic: false),
          onRoute: (settings) {
            pushed = settings;
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n(tester).jobsTailorCv));
        await tester.pumpAndSettle();

        expect(pushed?.name, AppRoutes.createCv);
        final target = pushed!.arguments! as CvTargetJob;
        expect(target.title, 'Backend Developer');
        expect(target.description, 'Build APIs with Laravel.');
      });
    }

    for (final (mode, theme) in [
      ('light', AppTheme.lightFor(arabic: false)),
      ('dark', AppTheme.darkFor(arabic: false)),
    ]) {
      for (final name in _variants.keys) {
        testWidgets('all text is AA in $mode ($name)', (tester) async {
          tester.view.physicalSize = const Size(1080, 3600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(app(_variants[name]!, theme));
          await tester.pumpAndSettle();
          expectAllTextAa('job detail $mode $name');
        });
      }
    }
  });

  testWidgets('create-cv route pre-fills the generator from the job',
      (tester) async {
    AppLocale.languageCode.value = 'en';
    SharedPreferences.setMockInitialValues({});
    const storage =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (_) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null));
    registerSiratiRouteWidgets();

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const Scaffold(),
      ),
    ));
    unawaited(navigatorKey.currentState!.pushNamed(
      AppRoutes.createCv,
      arguments: CvTargetJob(
        title: 'Data Analyst',
        description: 'SQL, dashboards and stakeholder reporting.',
      ),
    ));
    await tester.pumpAndSettle();

    final titleField = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'Data Analyst');
    expect(titleField, findsOneWidget);
  });
}
