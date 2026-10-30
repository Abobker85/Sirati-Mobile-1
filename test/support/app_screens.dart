/// The app's screens as pumpable test fixtures, shared by the server-label
/// audit (`test/localization/server_labels_audit_test.dart`) and the admin
/// label-preview capture (`test_screens/capture_screens_test.dart`), so a
/// screen added here is both audited and given an admin preview.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/errors/app_crash_view.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/features/auth/presentation/sign_in_required_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_jobs_section.dart';
import 'package:sirati/features/dashboard/presentation/home_screen.dart';
import 'package:sirati/features/dashboard/presentation/not_found_screen.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/features/dashboard/presentation/splash/welcome_body.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/features/settings/presentation/delete_account_screen.dart';
import 'package:sirati/features/settings/presentation/deleted_account_cleanup_screen.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/onboarding_screen.dart';
import 'package:sirati/features/settings/presentation/privacy_policy_screen.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';
import 'package:sirati/features/settings/presentation/settings/language_picker_sheet.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../features/job_match/job_match_test_support.dart' as job_match;
import 'l10n_label_capture.dart';

const screenLanguages = ['ar', 'en'];
const screenRootKey = ValueKey('l10n-screen-root');
const _secureStorage =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// One app screen (or one state of it). [pump] puts it on screen;
/// [fullHeight] lets the capture grow the view to the primary scroll view's
/// content height.
class AppScreen {
  const AppScreen(this.id, this.name, this.pump, {this.fullHeight = true});

  final String id;
  final String name;
  final Future<void> Function(WidgetTester tester, ScreenHarness h) pump;
  final bool fullHeight;
}

/// Pumps a screen with labels served from [catalogs] through the recording
/// remote lookup, and collects every piece of sample data (backend JSON,
/// fake users, typed input) into [samples]: text that is data, not a label.
class ScreenHarness {
  ScreenHarness(this.language, this.recorder, this.catalogs);

  final String language;
  final L10nLabelRecorder recorder;
  final Map<String, Map<String, String>> catalogs;

  /// Starts with configuration the app shows as-is (not translatable).
  final Set<String> samples = {ApiConfig.supportEmail};

  bool get arabic => language == 'ar';

  /// [ar] or [en] by language, recorded as sample data.
  String sample(String ar, String en) {
    final value = arabic ? ar : en;
    samples.add(value);
    return value;
  }

  /// The labels the pumped app is using (served from [catalogs]).
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  /// `GET /i18n/languages` as the server sends it; [pumpApp] applies it the
  /// way the app does at start, so language names are server data.
  Map<String, Object?> get languagesJson => {
        'data': [
          {
            'code': 'ar',
            'name': 'Arabic',
            'native_name': 'العربية',
            'direction': 'rtl',
            'fallback': 'en',
            'version': 1,
          },
          {
            'code': 'en',
            'name': 'English',
            'native_name': 'English',
            'direction': 'ltr',
            'fallback': 'en',
            'version': 1,
          },
        ],
      };

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
  }) async {
    _collect(languagesJson);
    AppLocale.updateCatalog(RemoteLanguageList.fromJson(languagesJson));
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: screenRootKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightFor(arabic: arabic),
          locale: Locale(language),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: [
            RecordingLocalizationsDelegate(
                recorder: recorder, catalogs: catalogs),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(),
          ),
        ),
      ),
    ));
    await settleScreen(tester);
  }

  /// Backend stand-in (data adapted from dark_mode_12_screen_walk_test).
  /// Every string it returns is recorded as sample data.
  http.Client mockClient() => MockClient((request) async {
        final path = request.url.path;
        final lang = arabic ? 'ar' : 'en';
        if (path.contains('/mobile/dashboard')) {
          return _json({
            'data': {
              'profile': {
                'name': arabic ? 'سارة' : 'Sarah',
                'status': arabic ? 'باحثة عن عمل' : 'Job Seeker',
              },
              'stats': {'generated_cvs': 3, 'analyses': 5},
              'latest_news': {},
            },
          });
        }
        if (path.contains('/mobile/job-news')) {
          Map<String, Object?> item(
                  int id, String title, String company, String city) =>
              {
                'id': id,
                'language': lang,
                'title': title,
                'company': company,
                'location': city,
                'body': arabic
                    ? 'تصميم تطبيقات جوال عالية الأداء.'
                    : 'Design high scale mobile applications.',
                'category': 'engineering',
                'url': 'https://example.com/$id',
                'apply_url': 'https://example.com/$id/apply',
                'valid_from': '2026-10-01T00:00:00Z',
                'valid_until': '2026-11-30T00:00:00Z',
                'published_at': '2026-10-20T00:00:00Z',
              };
          return _json({
            'data': {
              'title': arabic ? 'الوظائف' : 'Jobs',
              'items': [
                item(
                    101,
                    arabic ? 'مهندس تطبيقات فلاتر' : 'Flutter Engineer',
                    arabic ? 'شركة التقنية' : 'Tech Corp',
                    arabic ? 'الرياض' : 'Riyadh'),
                item(
                    102,
                    arabic ? 'مطور تطبيقات جوال' : 'Mobile Developer',
                    arabic ? 'حلول المستقبل' : 'Future Solutions',
                    arabic ? 'جدة' : 'Jeddah'),
                item(
                    103,
                    arabic ? 'محلل بيانات' : 'Data Analyst',
                    arabic ? 'بيانات العرب' : 'Arab Data',
                    arabic ? 'الدمام' : 'Dammam'),
              ],
            },
          });
        }
        if (path.endsWith('/i18n/languages')) return _json(languagesJson);
        if (path.contains('/cv-analyses') ||
            path.contains('/generated-cvs') ||
            path.contains('/notifications')) {
          return _json({
            'data': [],
            'meta': {'current_page': 1, 'last_page': 1},
          });
        }
        return _json({'data': {}});
      });

  void _collect(Object? node) {
    switch (node) {
      case final String s:
        samples.add(s);
      case final Map m:
        m.values.forEach(_collect);
      case final List l:
        l.forEach(_collect);
    }
  }

  http.Response _json(Object body) {
    _collect(body);
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

/// Loads every bundled font (app + Material icons). Text whose style names
/// no font family (e.g. a button `textStyle`) still renders in the test
/// engine's box font: on a phone it uses the platform font.
Future<void> loadAppFonts() async {
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json'))
      as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Advances frames until idle (or ~4 s of fake time for endless spinners).
Future<void> settleScreen(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

/// Per-test platform stand-ins every screen needs; call from `setUp`.
void setUpScreenTest() {
  MobileContentService.invalidate();
  SharedPreferences.setMockInitialValues({});
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorage, (call) async => null);
}

void tearDownScreenTest() {
  AppLocale.catalog.value = const RemoteLanguageList(languages: []);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorage, null);
}

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
    );

/// Job news that always fails with [error].
Override _failingJobs(ApiException error) =>
    mobileContentServiceProvider.overrideWithValue(_FailingJobsContent(error));

class _FailingJobsContent extends MobileContentService {
  _FailingJobsContent(this.error);
  final ApiException error;

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
      throw error;
}

class _SettingsGateway extends NotificationPrefsGateway {
  @override
  Future<bool?> fetchServer() async => true;
  @override
  Future<bool> readLocal() async => true;
  @override
  Future<void> saveLocal(bool enabled) async {}
  @override
  Future<void> syncServer(bool enabled) async {}
  @override
  Future<void> enableDevicePush() async {}
  @override
  Future<void> disableDevicePush() async {}
}

class _SettingsAuth extends AuthApiService {
  _SettingsAuth(this.name, this.email);
  final String name;
  final String email;

  @override
  Future<AuthUser?> me() async => AuthUser(id: 1, name: name, email: email);
}

Future<void> _pumpSettings(WidgetTester tester, ScreenHarness h) => h.pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        authApiServiceProvider.overrideWithValue(_SettingsAuth(
          h.sample('سارة العلي', 'Sara Ali'),
          h.sample('sara@example.com', 'sara@example.com'),
        )),
        notificationPrefsGatewayProvider.overrideWithValue(_SettingsGateway()),
      ],
    );

CvAnalysis _sampleAnalysis(ScreenHarness h, {bool locked = false}) =>
    CvAnalysis.fromJson({
      'keyword_source': 'job_description',
      'id': 1,
      'target_job_title': h.sample('مطور واجهات خلفية', 'Backend Developer'),
      'score_total': 72,
      'grade': 'B',
      'job_match': 68,
      'ai_status': 'completed',
      'strengths': [h.sample('ملخص واضح', 'Clear summary')],
      'weaknesses': [
        {
          'title': h.sample('أرقام قليلة', 'Few metrics'),
          'suggestion':
              h.sample('اذكر نتائج قابلة للقياس', 'Quantify outcomes'),
        },
      ],
      'keywords_found': [
        for (final k in ['PHP', 'Laravel', 'MySQL']) h.sample(k, k),
      ],
      'keywords_missing': [
        for (final k in ['Docker', 'Kubernetes']) h.sample(k, k),
      ],
      'quick_wins': [
        h.sample('أضف نتائج قابلة للقياس', 'Add measurable outcomes'),
      ],
      'criteria': [
        {'label': h.sample('Structure', 'Structure'), 'score': 6, 'max': 10},
        {'label': h.sample('Keywords', 'Keywords'), 'score': 7, 'max': 10},
        {'label': h.sample('Impact', 'Impact'), 'score': 9, 'max': 10},
      ],
      if (locked)
        'access': {
          'is_locked': true,
          'hidden_total': 10,
          'hidden': {
            'strengths': 2,
            'weaknesses': 3,
            'keywords_missing': 4,
            'quick_wins': 1,
          },
        },
    });

final appScreens = <AppScreen>[
  AppScreen('welcome', 'Welcome', (tester, h) {
    return h.pumpApp(
      tester,
      Scaffold(
        body: WelcomeBody(onRegister: () {}, onLogin: () {}, onPrivacy: () {}),
      ),
    );
  }),
  AppScreen(
      'login', 'Login', (tester, h) => h.pumpApp(tester, const LoginScreen())),
  AppScreen('register', 'Register', (tester, h) {
    return h.pumpApp(tester, const RegisterScreen(), overrides: [
      jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
    ]);
  }),
  AppScreen('home', 'Dashboard home',
      (tester, h) => h.pumpApp(tester, const HomeScreen())),
  AppScreen('cv_personal', 'CV wizard: personal details',
      (tester, h) => h.pumpApp(tester, const CvGeneratorScreen())),
  AppScreen('cv_skills', 'CV wizard: skills', (tester, h) async {
    await h.pumpApp(tester, const CvGeneratorScreen());
    final l10n = h.l10nOf(tester);
    await tester.enterText(_fieldWithHint(l10n.cvPersonalFullNameHint),
        h.sample('سارة العلي', 'Sara Ali'));
    await tester.enterText(_fieldWithHint(l10n.cvPersonalEmailHint),
        h.sample('sara@example.com', 'sara@example.com'));
    await tester.enterText(_fieldWithHint(l10n.cvPersonalPhoneHint),
        h.sample('+966 59 189 0300', '+966 59 189 0300'));
    await tester.enterText(_fieldWithHint(l10n.cvPersonalTargetJobHint),
        h.sample('مطورة واجهات خلفية', 'Backend Developer'));
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.text(l10n.next).last);
    await settleScreen(tester);
  }),
  AppScreen('analysis_input', 'CV analysis',
      (tester, h) => h.pumpApp(tester, const CvAnalysisScreen())),
  AppScreen('analysis_result', 'Analysis result', (tester, h) {
    return h.pumpApp(
        tester, AnalysisResultScreen(analysis: _sampleAnalysis(h)));
  }),
  AppScreen('analysis_result_locked', 'Analysis result (hidden items)',
      (tester, h) {
    return h.pumpApp(tester,
        AnalysisResultScreen(analysis: _sampleAnalysis(h, locked: true)));
  }),
  AppScreen('analysis_result_locked_tips',
      'Analysis result recommendations (hidden items)', (tester, h) async {
    await h.pumpApp(tester,
        AnalysisResultScreen(analysis: _sampleAnalysis(h, locked: true)));
    await tester.tap(find.byType(Tab).at(1));
    await settleScreen(tester);
  }),
  AppScreen('job_match', 'Job match', (tester, h) {
    final api = job_match.FakeJobMatchApi()
      ..cvs = [
        job_match.savedCv(1,
            title: h.sample('محللة بيانات', 'Data Analyst'),
            name: h.sample('سارة العلي', 'Sara Ali')),
      ];
    return h.pumpApp(tester, const JobMatchScreen(), overrides: [
      cvApiServiceProvider.overrideWithValue(api),
      authApiServiceProvider
          .overrideWithValue(job_match.FakeAuth(job_match.subscription())),
    ]);
  }),
  AppScreen('jobs', 'Jobs',
      (tester, h) => h.pumpApp(tester, const JobNewsScreen(isActive: true))),
  AppScreen('jobs_error', 'Jobs: load error', (tester, h) {
    return h.pumpApp(tester, const JobNewsScreen(), overrides: [
      _failingJobs(ApiException(
          h.sample('تعذّر تحميل الوظائف من الخادم',
              'The server could not load jobs'),
          type: ApiErrorType.server)),
    ]);
  }),
  AppScreen('jobs_offline', 'Jobs: offline', (tester, h) {
    return h.pumpApp(tester, const JobNewsScreen(), overrides: [
      _failingJobs(const ApiException('offline', type: ApiErrorType.network)),
    ]);
  }, fullHeight: false),
  AppScreen('jobs_matched_no_title', 'Jobs: in my field, no job title',
      (tester, h) async {
    await h.pumpApp(tester, const JobNewsScreen());
    // The tab has no Scaffold of its own.
    final l10n =
        AppLocalizations.of(tester.element(find.byType(JobNewsScreen)));
    final matched = find.text(l10n.jobsPresetMatched);
    await tester.ensureVisible(matched);
    await tester.pump();
    await tester.tap(matched);
    await settleScreen(tester);
  }),
  AppScreen('home_jobs_offline', 'Home: latest jobs offline', (tester, h) {
    return h.pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DashboardJobsSection(onViewAll: () {}, onOpenSaved: () {}),
          ),
        ),
        overrides: [
          _failingJobs(
              const ApiException('offline', type: ApiErrorType.network)),
        ]);
  }, fullHeight: false),
  const AppScreen('settings', 'Settings', _pumpSettings),
  AppScreen('language_picker', 'Language picker', (tester, h) async {
    await _pumpSettings(tester, h);
    final context = tester.element(find.byType(SettingsScreen));
    // The sheet's future completes when it closes; capture while open.
    unawaited(showLanguagePicker(context));
    await settleScreen(tester);
  }, fullHeight: false),
  AppScreen('forgot_password', 'Forgot password',
      (tester, h) => h.pumpApp(tester, const ForgotPasswordScreen())),
  AppScreen('email_verification', 'Email verification', (tester, h) {
    return h.pumpApp(
        tester,
        EmailVerificationScreen(
            email: h.sample('sara@example.com', 'sara@example.com')));
  }),
  AppScreen('sign_in_required', 'Sign-in required',
      (tester, h) => h.pumpApp(tester, const SignInRequiredScreen())),
  AppScreen('session_expired', 'Session expired',
      (tester, h) => h.pumpApp(tester, const SessionExpiredScreen())),
  AppScreen(
      'onboarding',
      'Onboarding',
      (tester, h) => h.pumpApp(
          tester, Scaffold(body: OnboardingScreen(onFinished: () {})))),
  AppScreen('my_cvs', 'My CVs',
      (tester, h) => h.pumpApp(tester, const MyCvsScreen())),
  AppScreen('cv_builder', 'CV editor',
      (tester, h) => h.pumpApp(tester, const CvBuilderScreen())),
  AppScreen('generated_cv', 'Generated CV', (tester, h) {
    return h.pumpApp(
        tester,
        GeneratedCvScreen(
            generatedCv: job_match.savedCv(1,
                title: h.sample('محللة بيانات', 'Data Analyst'),
                name: h.sample('سارة العلي', 'Sara Ali'))));
  }),
  AppScreen('history', 'History',
      (tester, h) => h.pumpApp(tester, const HistoryScreen())),
  AppScreen('job_detail', 'Job detail', (tester, h) {
    return h.pumpApp(
        tester,
        JobNewsDetailScreen(
            item: JobNews.fromJson({
          'id': 101,
          'language': h.language,
          'title': h.sample('مهندس تطبيقات فلاتر', 'Flutter Engineer'),
          'company': h.sample('شركة التقنية', 'Tech Corp'),
          'location': h.sample('الرياض', 'Riyadh'),
          'body': h.sample('تصميم تطبيقات جوال عالية الأداء.',
              'Design high scale mobile applications.'),
          'category': 'engineering',
          'source_url': 'https://example.com/101',
          'apply_method': 'url',
          'apply_url': 'https://example.com/101/apply',
          'valid_from': '2026-10-01T00:00:00Z',
          'valid_until': '2026-11-30T00:00:00Z',
          'published_at': '2026-10-20T00:00:00Z',
        })));
  }),
  AppScreen('education', 'Education',
      (tester, h) => h.pumpApp(tester, const EducationScreen())),
  AppScreen('premium_gate', 'Premium plans',
      (tester, h) => h.pumpApp(tester, const PremiumGateScreen())),
  AppScreen('notifications', 'Notifications',
      (tester, h) => h.pumpApp(tester, const NotificationsScreen())),
  AppScreen('profile', 'Profile', (tester, h) {
    return h.pumpApp(tester, const ProfileScreen(), overrides: [
      authApiServiceProvider.overrideWithValue(_SettingsAuth(
        h.sample('سارة العلي', 'Sara Ali'),
        h.sample('sara@example.com', 'sara@example.com'),
      )),
    ]);
  }),
  AppScreen('change_password', 'Change password',
      (tester, h) => h.pumpApp(tester, const ChangePasswordScreen())),
  AppScreen('delete_account', 'Delete account',
      (tester, h) => h.pumpApp(tester, const DeleteAccountScreen())),
  AppScreen('deleted_account_cleanup', 'Deleted account cleanup', (tester, h) {
    return h.pumpApp(
        tester, DeletedAccountCleanupScreen(retryCleanup: () async {}));
  }),
  AppScreen('privacy_policy', 'Privacy policy',
      (tester, h) => h.pumpApp(tester, const PrivacyPolicyScreen())),
  AppScreen('error', 'Something went wrong',
      (tester, h) => h.pumpApp(tester, const AppRecoverableError())),
  AppScreen('not_found', 'Not found',
      (tester, h) => h.pumpApp(tester, const NotFoundScreen())),
];
