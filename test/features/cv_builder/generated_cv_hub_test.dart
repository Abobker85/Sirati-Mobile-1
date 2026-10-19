import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/non_text_contrast.dart';
import '../job_match/job_match_test_support.dart';

GeneratedCv _cv(
        {int id = 91,
        int score = 83,
        String status = 'completed',
        String language = 'ar',
        String? markdown}) =>
    GeneratedCv.fromJson({
      'id': id,
      'full_name': 'سارة أحمد Sara Ahmed',
      'target_job_title': 'مهندسة نظم Distributed Systems Engineer',
      'language': language,
      'generated_markdown': markdown ??
          '## Summary\n'
              '${List.generate(12, (i) => 'Experience $i: تحليل البيانات C++ and SQL.').join('\n')}\n'
              '## Skills\n- C++\n- SQL',
      'email': 'sara@example.test',
      'phone': '+966501234567',
      'ai_status': status,
      'ai_error': status == 'failed' ? 'provider_timeout' : null,
      'score_total': score,
      'grade': 'B',
      'pdf_url': 'https://example.test/cvs/$id.pdf?signature=fresh',
    });

class _Api extends FakeJobMatchApi {
  int fetches = 0;
  @override
  Future<GeneratedCv> getGeneratedCv(int id) async {
    fetches++;
    return _cv(id: id);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  int id = 91,
  int score = 83,
  String language = 'ar',
  bool dark = false,
  String status = 'completed',
  _Api? api,
  String? markdown,
}) async {
  AppLocale.languageCode.value = language;
  registerSiratiRouteWidgets();
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      cvApiServiceProvider.overrideWithValue(api ?? _Api()),
      authApiServiceProvider.overrideWithValue(FakeAuth(subscription())),
    ],
    child: MaterialApp(
      builder: (_, child) => RepaintBoundary(key: phonePaintKey, child: child!),
      theme: dark
          ? AppTheme.darkFor(arabic: language == 'ar')
          : AppTheme.lightFor(arabic: language == 'ar'),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: GeneratedCvScreen(
          generatedCv: _cv(
              id: id,
              score: score,
              status: status,
              language: language,
              markdown: markdown)),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await revealPhoneWidget(tester, find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

String? _launched;
String? _shared;

void main() {
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');
  const share = MethodChannel('dev.fluttercommunity.plus/share');
  setUp(() {
    _launched = null;
    _shared = null;
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(launcher, (call) async {
      _launched = (call.arguments as Map)['url'] as String;
      return true;
    });
    messenger.setMockMethodCallHandler(share, (call) async {
      _shared = (call.arguments as Map)['text'] as String;
      return null;
    });
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(launcher, null);
    messenger.setMockMethodCallHandler(share, null);
  });

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final status in [
        'completed',
        'processing',
        'failed',
        'not_configured'
      ]) {
        testWidgets(
            '$language/$dark/$status: phone at 2x and reachable actions',
            (tester) async {
          usePhoneViewAtTextScale(tester);
          final api = _Api();
          await _pump(tester,
              language: language, dark: dark, status: status, api: api);
          expect(
              Directionality.of(tester.element(find.byType(GeneratedCvScreen))),
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          await inspectPhoneScreen(tester, '$language/$dark/$status');
          await _tap(tester, GeneratedCvScreen.downloadKey);
          final ready = ['completed', 'not_configured'].contains(status);
          expect(api.fetches, ready ? 1 : 0);
          expect(_launched, ready ? _cv().pdfUrl : isNull);
          await tester.pump(const Duration(seconds: 5));
          await _tap(tester, GeneratedCvScreen.shareKey);
          for (var i = 0; i < 12; i++) {
            expect(_shared,
                contains('Experience $i: تحليل البيانات C++ and SQL.'));
          }
          expect(_shared, contains(_cv().fullName));
          expect(_shared, isNot(contains('##')));
          await _tap(tester, GeneratedCvScreen.previewToggleKey);
          await inspectPhoneScreen(tester, '$language/$dark/$status expanded');
        });
      }

      for (final (kind, blank) in [
        ('empty', ''),
        ('whitespace', ' \t\n'),
        ('rules', '---\n***')
      ]) {
        testWidgets(
            '$language/$dark: empty content keeps disabled Share legible ($kind)',
            (tester) async {
          usePhoneViewAtTextScale(tester);
          await _pump(tester, language: language, dark: dark, markdown: blank);
          await inspectPhoneScreen(tester, '$language/$dark empty content');
          await revealPhoneWidget(
              tester, find.byKey(GeneratedCvScreen.shareKey));
          expect(
              tester
                  .widget<OutlinedButton>(
                      find.byKey(GeneratedCvScreen.shareKey))
                  .enabled,
              isFalse);
          await tester.tap(find.byKey(GeneratedCvScreen.shareKey));
          await tester.pump();
          expect(_shared, isNull);
        });
      }

      testWidgets(
          '$language/$dark: score text stays scaled inside its growing ring',
          (tester) async {
        usePhoneViewAtTextScale(tester);
        final random = Random(81);
        final scores = {
          -5,
          0,
          1,
          9,
          10,
          99,
          100,
          150,
          for (var i = 0; i < 5; i++) random.nextInt(101)
        };
        for (final score in scores) {
          await _pump(tester, score: score, language: language, dark: dark);
          await revealPhoneWidget(
              tester, find.byKey(GeneratedCvScreen.atsScoreKey));
          final ring = find.byKey(const ValueKey('cv-hub-score-ring'));
          final l = AppLocalizations.of(tester.element(ring));
          final text = find.descendant(
              of: find.byKey(GeneratedCvScreen.atsScoreKey),
              matching: find.text(l.cvHubAtsScore(score.clamp(0, 100))));
          final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: text, matching: find.byType(RichText)));
          expect(paragraph.textScaler.scale(16), 32);
          expect(tester.getSize(ring).width, greaterThanOrEqualTo(128));
          final bounds = tester.getRect(ring);
          final textBounds = tester.getRect(text);
          expect(bounds.contains(textBounds.topLeft), isTrue);
          expect(bounds.contains(textBounds.bottomRight), isTrue);
          expect(find.descendant(of: ring, matching: find.byType(FittedBox)),
              findsNothing);
          expectPaintedControlsAa('$language/$dark score $score');
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  for (final id in [7, 91, 503]) {
    testWidgets('Compare hands CV $id to the real route and the match request',
        (tester) async {
      usePhoneViewAtTextScale(tester);
      final api = _Api()
        ..cvs = [savedCv(id + 1), savedCv(id), savedCv(id + 2)]
        ..createResponses.add(matchJson(cvId: id));
      await _pump(tester, id: id, api: api);
      await _tap(tester, GeneratedCvScreen.jobMatchStepKey);
      expect(
          tester
              .widget<JobMatchScreen>(find.byType(JobMatchScreen))
              .initialCvId,
          id);
      await revealPhoneWidget(
          tester, find.byKey(JobMatchScreen.cvOptionKey(id)));
      final selection = tester.widget<Semantics>(find
          .descendant(
            of: find.byKey(JobMatchScreen.cvOptionKey(id)),
            matching: find.byWidgetPredicate((widget) =>
                widget is Semantics && widget.properties.selected != null),
          )
          .first);
      expect(selection.properties.selected, isTrue);
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      expect(api.createCalls.single['cv'], id);
    });
  }

  for (final id in [-5, 0, 81]) {
    testWidgets(
        'unavailable source CV $id never silently selects a different saved CV',
        (tester) async {
      usePhoneViewAtTextScale(tester);
      final api = _Api()..cvs = [savedCv(22)];
      await _pump(tester, id: id, api: api);
      await _tap(tester, GeneratedCvScreen.jobMatchStepKey);
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      expect(api.createCalls, isEmpty);
      await revealPhoneWidget(
          tester, find.byKey(const ValueKey('jm-pick-error')));
    });
  }

  testWidgets('ATS discloses the empty form and carries the source CV input',
      (tester) async {
    usePhoneViewAtTextScale(tester);
    await _pump(tester);
    final l =
        AppLocalizations.of(tester.element(find.byType(GeneratedCvScreen)));
    await _tap(tester, GeneratedCvScreen.atsStepKey);
    expect(find.text(l.cvHubAtsNewFormNotice), findsOneWidget);
    expect(find.byType(CvAnalysisScreen), findsNothing);
    await tester.tap(find.text(l.cvHubAtsOpenNewForm));
    await tester.pumpAndSettle();
    final args = ModalRoute.of(tester.element(find.byType(CvAnalysisScreen)))!
        .settings
        .arguments as CvHubAtsCheckArguments;
    expect(args.cvId, _cv().id);
    expect(args.markdown, _cv().generatedMarkdown);
  });

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('$language/$dark: Edit remains reachable on a 2x phone',
          (tester) async {
        usePhoneViewAtTextScale(tester);
        await _pump(tester, language: language, dark: dark);
        await _tap(tester, GeneratedCvScreen.editStepKey);
        expect(find.byKey(GeneratedCvScreen.previewKey), findsNothing);
      });
    }
  }
}
