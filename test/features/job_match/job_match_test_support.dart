import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/non_text_contrast.dart';

GeneratedCv savedCv(
  int id, {
  String title = 'Data Analyst',
  String name = 'Sara Ali',
  String aiStatus = 'completed',
}) =>
    GeneratedCv.fromJson({
      'id': id,
      'full_name': name,
      'target_job_title': title,
      'language': 'en',
      'ai_status': aiStatus,
    });

Map<String, dynamic> suggestionJson(
  String key, {
  String section = 'skills',
  String? before = 'Excel',
  String after = 'Excel, Power BI, SQL',
  String rationale = 'The ad asks for Power BI.',
  List<String> jdTerms = const ['Power BI'],
  bool needsUserFact = false,
}) =>
    {
      'key': key,
      'target': {'section': section},
      'before': before,
      'after': after,
      'rationale': rationale,
      'jd_terms': jdTerms,
      'needs_user_fact': needsUserFact,
    };

Map<String, dynamic> matchJson({
  int id = 7,
  int cvId = 1,
  String aiStatus = 'completed',
  int score = 72,
  List<String> found = const ['SQL', 'Excel'],
  List<String> missing = const ['Power BI', 'C++'],
  List<Map<String, dynamic>>? suggestions,
  List<String> applied = const [],
  int? appliedCvId,
  String summary = 'Strong analytics base.',
}) =>
    {
      'id': id,
      'generated_cv_id': cvId,
      'applied_generated_cv_id': appliedCvId,
      'target_job_title': 'Data Analyst',
      'language': 'en',
      'score_total': score,
      'grade': 'B',
      'job_match': 64,
      'keywords_found': found,
      'keywords_missing': missing,
      'strengths': ['Clear summary'],
      'weaknesses': [
        {'priority': 'high', 'issue': 'No BI tools', 'fix': 'Add Power BI'},
      ],
      'ai_status': aiStatus,
      'ai_feedback': aiStatus == 'completed'
          ? {
              'executive_summary': summary,
              'strengths': ['SQL depth'],
              'gaps': ['Power BI'],
              'suggestions': suggestions ??
                  [
                    suggestionJson('s1'),
                    suggestionJson(
                      's2',
                      section: 'summary',
                      before: null,
                      after: 'Analyst with 5 years of SQL.',
                      needsUserFact: true,
                    ),
                    suggestionJson(
                      's3',
                      section: 'experience',
                      before: 'Made reports',
                      after: 'Built Power BI dashboards',
                    ),
                  ],
            }
          : null,
      'ai_error': null,
      'applied_suggestion_ids': applied,
    };

/// Scriptable Job Match backend. Every response is a queue entry: a JSON map
/// to return or an error to throw.
class FakeJobMatchApi extends CvApiService {
  List<GeneratedCv> cvs = [savedCv(1)];
  Object? cvsError;

  final createCalls = <Map<String, Object?>>[];
  final createResponses = <Object>[];

  final fetchCalls = <int>[];
  final fetchResponses = <Object>[];
  Future<Map<String, dynamic>> Function(int)? fetchOverride;

  final retryCalls = <int>[];
  final retryResponses = <Object>[];
  Future<Map<String, dynamic>> Function(int)? retryOverride;

  @override
  Future<Map<String, dynamic>> retryJobMatchAdvice(int id) async {
    retryCalls.add(id);
    if (retryOverride != null) return retryOverride!(id);
    final next = _next(retryResponses, 'retry');
    if (next is Map<String, dynamic>) return next;
    throw next;
  }

  final applyCalls = <List<String>>[];
  final confirmedFactCalls = <List<String>>[];
  final applyResponses = <Object>[];
  Future<({GeneratedCv generatedCv, Map<String, dynamic> jobMatch})> Function()?
      applyOverride;

  static Object _next(List<Object> queue, String what) {
    if (queue.isEmpty) fail('unexpected $what call');
    return queue.length == 1 ? queue.first : queue.removeAt(0);
  }

  @override
  Future<List<GeneratedCv>> listGeneratedCvs() async {
    if (cvsError != null) throw cvsError!;
    return cvs;
  }

  @override
  Future<Map<String, dynamic>> createJobMatch({
    required int generatedCvId,
    required String jobDescription,
    String? targetJobTitle,
    String? language,
    String? idempotencyKey,
  }) async {
    createCalls.add({
      'cv': generatedCvId,
      'jd': jobDescription,
      'title': targetJobTitle,
      'key': idempotencyKey,
    });
    final next = _next(createResponses, 'create');
    if (next is Map<String, dynamic>) return next;
    throw next;
  }

  @override
  Future<Map<String, dynamic>> getJobMatch(int id) async {
    fetchCalls.add(id);
    if (fetchOverride != null) return fetchOverride!(id);
    final next = _next(fetchResponses, 'fetch');
    if (next is Map<String, dynamic>) return next;
    throw next;
  }

  @override
  Future<({GeneratedCv generatedCv, Map<String, dynamic> jobMatch})>
      applyJobMatchSuggestions(
    int id,
    List<String> suggestionKeys, {
    List<String> confirmedFactKeys = const [],
  }) async {
    confirmedFactCalls.add(List.of(confirmedFactKeys));
    applyCalls.add(List.of(suggestionKeys));
    if (applyOverride != null) return applyOverride!();
    final next = _next(applyResponses, 'apply');
    if (next is ({GeneratedCv generatedCv, Map<String, dynamic> jobMatch})) {
      return next;
    }
    throw next;
  }
}

Map<String, dynamic> subscription({
  bool subscribed = true,
  bool canJobMatch = true,
  int limit = 5,
  int used = 1,
  int trialDays = 0,
}) =>
    {
      'is_subscribed': subscribed,
      'can_job_match': canJobMatch,
      'trial_days': trialDays,
      'quota': {
        'job_match': {'limit': limit, 'used': used, 'resets_at': null},
      },
    };

class FakeAuth extends AuthApiService {
  FakeAuth([this.subscriptionState]);

  Map<String, dynamic>? subscriptionState;
  Object? error;
  int calls = 0;

  @override
  Future<AuthUser?> me() async {
    calls++;
    if (error != null) throw error!;
    return AuthUser(
      id: 1,
      name: 'Sara',
      email: 'sara@x.io',
      subscription: subscriptionState,
    );
  }
}

/// Stand-in for the CV generator route: records what it was opened with and
/// hands back [result] when its button is tapped.
class FakeGeneratorRoute {
  final opened = <CvTargetJob?>[];
  GeneratedCv? result;
  final openedCvPages = <String>[];

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    if (name == AppRoutes.createCv) {
      final args = settings.arguments;
      opened.add(args is CvTargetJob ? args : null);
      return MaterialPageRoute<Object?>(
        settings: settings,
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const ValueKey('fake-generator-done'),
              onPressed: () => Navigator.of(context).pop<Object?>(result),
              child: const Text('done'),
            ),
          ),
        ),
      );
    }
    if (name.startsWith(AppRoutes.cvPrefix)) {
      openedCvPages.add(name);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('cv page $name')),
      );
    }
    return null;
  }
}

/// Large logical viewport so every section is built (no lazy culling).
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpJobMatch(
  WidgetTester tester, {
  required FakeJobMatchApi api,
  required FakeAuth auth,
  String language = 'en',
  ThemeData? theme,
  FakeGeneratorRoute? routes,
  List<Duration>? schedule = const [
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
  ],
}) async {
  AppLocale.languageCode.value = language;
  final arabic = language == 'ar';
  await tester.pumpWidget(ProviderScope(
    overrides: [
      cvApiServiceProvider.overrideWithValue(api),
      authApiServiceProvider.overrideWithValue(auth),
      if (schedule != null)
        jobMatchPollScheduleProvider.overrideWithValue(schedule),
    ],
    child: MaterialApp(
      builder: (_, child) => RepaintBoundary(key: phonePaintKey, child: child!),
      theme: theme ?? AppTheme.lightFor(arabic: arabic),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateRoute: (routes ?? FakeGeneratorRoute()).onGenerateRoute,
      home: const JobMatchScreen(),
    ),
  ));
  await settle(tester);
}

/// Advances frames and timers without waiting for indefinite spinners.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> enterJob(
  WidgetTester tester, {
  String title = 'Data Analyst',
  String description = 'We need SQL, Power BI and C++ skills.',
}) async {
  await revealPhoneWidget(tester, find.byKey(JobMatchScreen.titleFieldKey));
  await tester.enterText(find.byKey(JobMatchScreen.titleFieldKey), title);
  await revealPhoneWidget(
      tester, find.byKey(JobMatchScreen.descriptionFieldKey));
  await tester.enterText(
    find.byKey(JobMatchScreen.descriptionFieldKey),
    description,
  );
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await revealPhoneWidget(tester, finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

AppLocalizations l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).last));
