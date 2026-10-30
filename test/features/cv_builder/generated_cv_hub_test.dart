import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/application/pdf_export_controller.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_template.dart';
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
        String? markdown,
        bool templateLink = false,
        Map<String, dynamic>? export}) =>
    GeneratedCv.fromJson({
      'id': id,
      'full_name': 'سارة أحمد Sara Ahmed',
      'target_job_title': 'مهندسة نظم Distributed Systems Engineer',
      'language': language,
      'job_description_input': 'Role $id: SQL, C++ وتحليل البيانات.',
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
      if (templateLink)
        'template_pdf_url': 'https://example.test/cvs/$id.pdf?signature=fresh',
      if (export != null) 'export': export,
    });

final _pdfBody = [...ascii.encode('%PDF-1.7\n'), 0, 255, 37, 80, 10];

class _Api extends FakeJobMatchApi {
  int fetches = 0;
  final templateLanguages = <String>[];
  final pdfRequests = <Uri>[];

  @override
  Future<GeneratedCv> getGeneratedCv(int id) async {
    fetches++;
    return _cv(id: id);
  }

  @override
  Future<List<CvTemplate>> listCvTemplates({required String language}) async {
    templateLanguages.add(language);
    return const [];
  }

  @override
  ApiClient get apiClient => _PdfClient(pdfRequests);
}

/// Serves [_pdfBody] for every download without a transport.
class _PdfClient extends ApiClient {
  _PdfClient(this.requests);
  final List<Uri> requests;

  @override
  Future<List<int>> getBytes(
    String path, {
    Duration receiveTimeout = const Duration(seconds: 45),
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    requests.add(Uri.parse(path));
    return _pdfBody;
  }
}

/// Files handed to the share sheet.
final _sharedFiles = <List<int>>[];

Future<void> _captureShare(List<XFile> files,
    {required List<String> fileNameOverrides,
    String? text,
    String? subject,
    Rect? sharePositionOrigin}) async {
  for (final file in files) {
    _sharedFiles.add(await file.readAsBytes());
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
  String? cvLanguage,
  bool templateLink = false,
  List<SavedAnalysisCv>? analysisCvs,
  Map<String, dynamic>? export,
}) async {
  AppLocale.languageCode.value = language;
  registerSiratiRouteWidgets();
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      cvApiServiceProvider.overrideWithValue(api ?? _Api()),
      pdfShareProvider.overrideWithValue(_captureShare),
      if (analysisCvs != null)
        analysisSavedCvsProvider
            .overrideWith((ref, english) async => analysisCvs),
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
              language: cvLanguage ?? language,
              markdown: markdown,
              templateLink: templateLink,
              export: export)),
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
    _sharedFiles.clear();
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

  // The server's export check decides readiness whatever the AI status says:
  // a blocked CV never opens the PDF link, shows the server's reason instead
  // of "ready", and an allowed one downloads.
  for (final language in ['ar', 'en']) {
    for (final status in [
      'completed',
      'processing',
      'failed',
      'not_configured'
    ]) {
      for (final reason in [
        null,
        'generating',
        'missing_contact',
        'unstructured_experience',
      ]) {
        testWidgets(
            '$language/$status/export=${reason ?? 'ready'}: '
            'server readiness decides', (tester) async {
          usePhoneViewAtTextScale(tester);
          final message = reason == null ? null : '$language message: $reason';
          final api = _Api();
          await _pump(tester,
              language: language,
              status: status,
              api: api,
              export: {
                'ready': reason == null,
                'blocked_reason': reason,
                'message_ar': language == 'ar' ? message : null,
                'message_en': language == 'en' ? message : null,
              });
          final l = AppLocalizations.of(
              tester.element(find.byType(GeneratedCvScreen)));

          if (reason == null) {
            expect(find.byKey(GeneratedCvScreen.notReadyKey), findsNothing);
          } else {
            expect(find.text(l.cvHubReady), findsNothing);
            if (status != 'failed') {
              expect(
                  find.descendant(
                      of: find.byKey(GeneratedCvScreen.notReadyKey),
                      matching: find.text(message!)),
                  findsOneWidget);
            }
          }

          await _tap(tester, GeneratedCvScreen.downloadKey);
          expect(_launched, reason == null ? _cv().pdfUrl : isNull);
          if (reason != null) {
            expect(find.text(message!), findsWidgets,
                reason: 'the tap explains what is missing');
          }
          await tester.pump(const Duration(seconds: 5));

          // Share follows the same rule: the PDF leaves only when Download
          // would have opened it, and the reason shows otherwise.
          await _tap(tester, GeneratedCvScreen.shareKey);
          expect(_sharedFiles, reason == null ? [_pdfBody] : isEmpty);
          expect(api.pdfRequests, hasLength(reason == null ? 1 : 0));
          if (reason != null) {
            expect(find.text(message!), findsWidgets);
          }
          await tester.pump(const Duration(seconds: 5));
        });
      }
    }
  }

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
          expect(_sharedFiles, ready ? [_pdfBody] : isEmpty);
          expect(_shared, isNull, reason: 'the PDF is shared, not text');
          if (ready) {
            expect(
                api.pdfRequests.single.queryParameters['language'], language);
          }
          await tester.pump(const Duration(seconds: 5));
          await _tap(tester, GeneratedCvScreen.previewToggleKey);
          await inspectPhoneScreen(tester, '$language/$dark/$status expanded');
        });
      }

      testWidgets('$language/$dark: Share and Download are enabled together',
          (tester) async {
        usePhoneViewAtTextScale(tester);
        for (final markdown in ['', ' \t\n', '---\n***', null]) {
          await _pump(tester,
              language: language, dark: dark, markdown: markdown);
          await revealPhoneWidget(
              tester, find.byKey(GeneratedCvScreen.downloadKey));
          final download = tester
              .widget<ElevatedButton>(find.byKey(GeneratedCvScreen.downloadKey))
              .enabled;
          await revealPhoneWidget(
              tester, find.byKey(GeneratedCvScreen.shareKey));
          final share = tester
              .widget<OutlinedButton>(find.byKey(GeneratedCvScreen.shareKey))
              .enabled;
          expect(share, download);
        }
      });

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
          expect(
              await expectRenderedControlsAa(
                  tester, '$language/$dark score $score'),
              1,
              reason:
                  'The hub ring must be raster-checked, including 0 and 100.');
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

  const markdowns = {
    'Arabic': '# الخبرات\n\n- تطوير الأنظمة وتحليل البيانات\n- إدارة المشاريع',
    'Latin': '# Experience\n\n- Platform engineering\n- SQL and C++\n',
    'mixed multiline':
        '  ## الخبرات Experience\n\n**مهندسة Systems**\n- C++ / SQL\n\n',
  };
  for (final id in [7, 91, 503]) {
    for (final entry in markdowns.entries) {
      testWidgets(
          'ATS opens prefilled with the source CV (id $id, ${entry.key})',
          (tester) async {
        usePhoneViewAtTextScale(tester);
        final api = _Api();
        await _pump(tester,
            id: id,
            api: api,
            markdown: entry.value,
            analysisCvs: [
              SavedAnalysisCv(id: id + 1, title: 'Another CV'),
              SavedAnalysisCv(id: id, title: 'Selected CV'),
            ]);
        await _tap(tester, GeneratedCvScreen.atsStepKey);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(CvAnalysisScreen), findsOneWidget);
        final screen =
            tester.widget<CvAnalysisScreen>(find.byType(CvAnalysisScreen));
        expect(screen.initialCvId, id);
        // The scan text is the CV's header (name, role, contact) plus its markdown.
        expect(screen.initialMarkdown, endsWith(entry.value));
        expect(screen.initialMarkdown, startsWith('# سارة أحمد Sara Ahmed'));
        expect(screen.initialMarkdown, contains('sara@example.test'));
        // The scanner opens with the CV's own job title and job description.
        expect(
            screen.initialJobTitle, 'مهندسة نظم Distributed Systems Engineer');
        expect(screen.initialJobDescription,
            'Role $id: SQL, C++ وتحليل البيانات.');
        expect(find.text('مهندسة نظم Distributed Systems Engineer'),
            findsOneWidget);
        expect(
            find.text('Role $id: SQL, C++ وتحليل البيانات.'), findsOneWidget);
        final args =
            ModalRoute.of(tester.element(find.byType(CvAnalysisScreen)))!
                .settings
                .arguments as CvHubAtsCheckArguments;
        expect(args.cvId, id);
        expect(args.markdown, screen.initialMarkdown);
        expect(
            tester
                .widget<DropdownButtonFormField<int>>(
                    find.byType(DropdownButtonFormField<int>))
                .initialValue,
            id);
        final savedSource = tester
            .element(find.byKey(const ValueKey(AnalysisCvSource.saved)))
            .findAncestorWidgetOfExactType<Semantics>()!;
        expect(savedSource.properties.selected, isTrue);
        expect(
            find.byKey(const ValueKey('ats-input-resume-text')), findsNothing);
        expect(api.fetches, 0);
      });
    }
  }

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

  // The design list and the preview's direction come from the CV's
  // declared language, whatever the app language or the text's script.
  for (final appLanguage in ['ar', 'en']) {
    for (final cvLanguage in ['ar', 'en', 'fr', 'ur']) {
      testWidgets('$appLanguage app, $cvLanguage CV: designs and direction',
          (tester) async {
        usePhoneViewAtTextScale(tester);
        final api = _Api();
        await _pump(tester,
            language: appLanguage,
            cvLanguage: cvLanguage,
            api: api,
            templateLink: true);
        final preview = find.descendant(
            of: find.byKey(GeneratedCvScreen.previewKey),
            matching: find.text('سارة أحمد Sara Ahmed'));
        expect(Directionality.of(tester.element(preview)),
            AppLocale.directionOf(cvLanguage));
        await _tap(tester, GeneratedCvScreen.downloadKey);
        expect(api.templateLanguages, [cvLanguage]);
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }

  test('reading direction ignores the script of the content', () {
    final random = Random(13);
    String text() => String.fromCharCodes(List.generate(
        random.nextInt(40),
        (_) => random.nextBool()
            ? 0x41 + random.nextInt(26)
            : 0x0621 + random.nextInt(0x3A)));
    for (final language in ['ar', 'en', 'fr', 'he', 'fa', 'ur', 'de']) {
      for (var i = 0; i < 30; i++) {
        final cv = _cv(language: language, markdown: text());
        expect(cvContentDirection(cv), AppLocale.directionOf(language));
      }
    }
  });
}
