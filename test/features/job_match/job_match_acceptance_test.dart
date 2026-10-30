import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/bidi_text_utils.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/cv_builder/application/pdf_export_controller.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/routing/app_router.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import 'job_match_test_support.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
        '$language: entry -> API -> apply -> preview -> shared artifact',
        (tester) async {
      useTallView(tester);
      AppLocale.languageCode.value = language;
      SharedPreferences.setMockInitialValues({});
      MobileContentService.invalidate();
      addTearDown(MobileContentService.invalidate);
      addTearDown(SessionCache.instance.clear);
      registerSiratiRouteWidgets();
      final arabic = language == 'ar';
      final title = arabic ? 'مهندس أنظمة C++' : 'Distributed Systems Engineer';
      final before = arabic ? 'ملخص سابق' : 'Previous summary';
      final after = arabic
          ? 'مهندس أنظمة يستخدم C++ وSQL في تحليل البيانات'
          : 'Systems engineer using C++ and SQL for distributed analytics';
      final jd = '  $title: SQL, C++, تحليل البيانات  ';
      final document = <String, dynamic>{
        'version': 1,
        'export_language': language,
        'summary': {language: after},
        'skills': [
          {
            'id': 'skill-1',
            'name': {'en': 'C++', 'ar': 'C++'}
          },
        ],
      };
      final source = <String, dynamic>{
        'id': 17,
        'full_name': 'Samira',
        'target_job_title': title,
        'language': language,
        'ai_status': 'completed',
        'generated_markdown': '## Summary\n$before',
      };
      final copy = {
        ...source,
        'id': 83,
        'generated_markdown': '## Summary\n$after',
        'document': document,
      };
      final suggestion = {
        ...suggestionJson('rewrite',
            before: before, after: after, needsUserFact: true),
        'target': {'section': 'summary', 'field': 'text'},
      };
      final completed = matchJson(
        id: 39,
        cvId: 17,
        suggestions: [suggestion],
      );
      var applied = false;
      var myCvsLoads = 0;
      var dashboardLoads = 0;
      final requests = <String>[];
      // The server renders the applied copy; its PDF carries the new text.
      final pdf = [...utf8.encode('%PDF-1.7\n$after C++ SQL\n'), 0, 255];
      final apiClient = ApiClient(httpClient: MockClient((request) async {
        final path = request.url.path;
        requests.add('${request.method} $path');
        if (path == '/api/generated-cvs/83/download') {
          expect(request.url.queryParameters['language'], language);
          return http.Response.bytes(pdf, 200,
              headers: {'content-type': 'application/pdf'});
        }
        Object data;
        if (path == '/api/auth/me') {
          data = {
            'id': 1,
            'name': 'Samira',
            'email': 'samira@example.test',
            'subscription': subscription(),
          };
        } else if (path == '/api/mobile/my-cvs') {
          myCvsLoads++;
          data = {
            'items': [
              {'id': 17, 'title': title},
              if (applied) {'id': 83, 'title': '$title — tailored'},
            ],
          };
        } else if (path == '/api/mobile/dashboard') {
          dashboardLoads++;
          data = {
            'stats': {'generated_cvs': applied ? 2 : 1}
          };
        } else if (path == '/api/generated-cvs') {
          data = [source, if (applied) copy];
        } else if (path == '/api/job-matches') {
          expect(request.method, 'POST');
          expect(request.headers['Idempotency-Key'], isNotEmpty);
          expect(jsonDecode(request.body), {
            'generated_cv_id': 17,
            'job_description_input': jd.trim(),
            'target_job_title': title,
          });
          data = matchJson(id: 39, cvId: 17, aiStatus: 'queued');
        } else if (path == '/api/job-matches/39') {
          expect(request.method, 'GET');
          data = completed;
        } else if (path == '/api/job-matches/39/apply-suggestions') {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'suggestion_keys': ['rewrite'],
            'confirmed_fact_keys': ['rewrite']
          });
          applied = true;
          data = {
            'generated_cv': copy,
            'job_match': {
              ...completed,
              'applied_suggestion_ids': ['rewrite'],
              'applied_generated_cv_id': 83,
            },
          };
        } else {
          fail('Unexpected request: ${request.method} $path');
        }
        return http.Response(
          jsonEncode({'data': data}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }));
      final content = MobileContentService(apiClient: apiClient);
      // Warm both caches to prove apply invalidates them within their TTL.
      await content.myCvs(!arabic);
      await content.dashboard(!arabic);
      final shared = <List<int>>[];

      await tester.pumpWidget(ProviderScope(
        overrides: [
          cvApiServiceProvider
              .overrideWithValue(CvApiService(apiClient: apiClient)),
          authApiServiceProvider
              .overrideWithValue(AuthApiService(apiClient: apiClient)),
          mobileContentServiceProvider.overrideWithValue(content),
          pdfShareProvider.overrideWithValue((files,
              {required fileNameOverrides,
              text,
              subject,
              sharePositionOrigin}) async {
            for (final file in files) {
              shared.add(await file.readAsBytes());
            }
          }),
          jobMatchPollScheduleProvider.overrideWithValue(
            const [Duration(milliseconds: 100)],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: arabic),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const Scaffold(body: MyCvsScreen()),
        ),
      ));
      await settle(tester);
      await tapVisible(tester, find.byKey(MyCvsToolsCard.targetKey));
      await settle(tester);
      await enterJob(tester, title: title, description: jd);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester, frames: 20);
      await tapVisible(
        tester,
        find.byKey(JobMatchSuggestionCard.confirmationKey('rewrite')),
      );
      await tapVisible(
        tester,
        find.byKey(JobMatchSuggestionCard.checkboxKey('rewrite')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('jm-apply')));
      await settle(tester);

      final preview =
          tester.widget<GeneratedCvScreen>(find.byType(GeneratedCvScreen));
      expect(preview.generatedCv.id, 83);
      expect(preview.generatedCv.document, document);
      expect(find.text(after), findsOneWidget);
      expect(source['generated_markdown'], contains(before));
      // The success snackbar briefly covers the preview's bottom actions.
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      await tapVisible(tester, find.text(arabic ? 'مشاركة' : 'Share'));
      // The PDF stream completes on the real event loop.
      for (var i = 0; i < 100 && shared.isEmpty; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
      await settle(tester);
      // The shared artifact is the applied copy's PDF, byte for byte.
      expect(shared, [pdf]);
      final text = utf8.decode(shared.single, allowMalformed: true);
      expect(text, contains(after));
      expect(text, isNot(contains(before)));
      expect(
          requests,
          containsAllInOrder([
            'GET /api/auth/me',
            'POST /api/job-matches',
            'GET /api/job-matches/39',
            'POST /api/job-matches/39/apply-suggestions',
            'GET /api/generated-cvs/83/download',
          ]));

      await content.myCvs(!arabic);
      await content.dashboard(!arabic);
      expect(myCvsLoads, 2);
      expect(dashboardLoads, 2);
      // Return through the real navigation stack. The mounted list refreshes.
      await tapVisible(tester, find.byType(BackButton));
      await settle(tester);
      await tapVisible(tester, find.byType(BackButton));
      await settle(tester);
      await tapVisible(tester, find.byType(BackButton));
      await settle(tester);
      final tailoredCard = find.byWidgetPredicate(
        (widget) => widget is CvDocumentCard && widget.item.id == 83,
      );
      expect(tailoredCard, findsOneWidget);
      expect(
        find.descendant(
          of: tailoredCard,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                BidiTextUtils.sanitizeBidiControls(widget.data ?? '') ==
                    '$title — tailored',
          ),
        ),
        findsOneWidget,
      );
      expect(myCvsLoads, 3);
    });
  }

  testWidgets('dashboard card reaches the server gate and refreshes on return',
      (tester) async {
    useTallView(tester);
    AppLocale.languageCode.value = 'en';
    SharedPreferences.setMockInitialValues({});
    registerSiratiRouteWidgets();
    final content = _DashboardContent();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mobileContentServiceProvider.overrideWithValue(content),
        cvApiServiceProvider.overrideWithValue(_HomeCvApi()),
        authApiServiceProvider
            .overrideWithValue(FakeAuth(subscription(subscribed: false))),
      ],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
      ),
    ));
    await settle(tester);
    // Home's "Target a job" (returning user) is the way into job match.
    await tapVisible(tester, find.text(l10n(tester).homeHeroTargetJob));
    await settle(tester);
    expect(find.byType(JobMatchScreen), findsOneWidget);
    expect(find.text(l10n(tester).jobMatchPaywallTitle), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(content.loads, 2);
    expect(content.forced, isTrue);
  });
}

/// Home loads the user's latest CV through the CV API.
class _HomeCvApi extends FakeJobMatchApi {
  @override
  Future<GeneratedCv> getGeneratedCv(int id) async => cvs.first;
}

class _DashboardContent extends MobileContentService {
  int loads = 0;
  bool forced = false;

  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {
        'items': [
          {'id': 1, 'title': 'Saved CV', 'updated_at': '2026-10-19T12:00:00Z'},
        ],
      };

  @override
  Future<Map<String, dynamic>> jobNews(
    bool english, {
    String? category,
    String? preset,
    String? city,
    String? region,
    int? jobTitleId,
    bool? isRemote,
    bool? isVerified,
    String? sourceType,
    String? employmentType,
    String? query,
    bool force = false,
  }) async =>
      {'items': const []};

  @override
  Future<Map<String, dynamic>> dashboard(bool english,
      {bool force = false}) async {
    loads++;
    forced = force;
    return {
      'stats': {'generated_cvs': loads}
    };
  }
}
