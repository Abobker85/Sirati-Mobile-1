/// Screenshot catalogue: every screen and state of the app, in Arabic and
/// English, light and dark, as phone PNGs (390x844 logical px at 3x).
///
/// Run from the Flutter app root (outside `test/`, so not part of
/// `flutter test`):
///
///   flutter test test_screens/all_screens_capture_test.dart
///
/// Output: `../docs/screenshots/all-screens/NN_<area>_<screen>_<state>_<ar|en>_<light|dark>.png`
/// plus `index.md`. Reuses the screen fixtures in `test/support/app_screens.dart`
/// and adds loading, empty, error, offline, dialog, sheet, overlay and
/// Premium states. Captures after a fixed number of frames because some
/// overlays animate forever.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_loader_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/exit_dialogs.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_loader_screen.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart';
import 'package:sirati/features/dashboard/application/session_bootstrap.dart';
import 'package:sirati/features/dashboard/data/subscription_plans_repository.dart';
import 'package:sirati/features/dashboard/application/premium_gate_controller.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/features/dashboard/presentation/education_detail_screen.dart';
import 'package:sirati/features/dashboard/presentation/gallery_screen.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/dashboard/presentation/home_screen.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/features/dashboard/presentation/splash_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/settings/presentation/avatar_crop_screen.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/premium/premium_feature.dart';
import 'package:sirati/shared/premium/premium_ui.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/offline_view.dart';
import 'package:sirati/shared/widgets/success_beat.dart';

import '../test/features/job_match/job_match_test_support.dart' as job_match;
import '../test/support/app_screens.dart';
import '../test/support/l10n_label_capture.dart';

const _width = 390.0;
const _height = 844.0;
const _ratio = 3.0;
const _outDir = '../docs/screenshots/all-screens';

/// How the stand-in backend answers.
enum Net { ok, empty, loading, error, offline }

class Shot {
  const Shot(this.area, this.screen, this.state, this.description, this.pump,
      {this.net = Net.ok, this.signedIn = true});

  final String area;
  final String screen;
  final String state;
  final String description;
  final Net net;

  /// Whether a session token is stored (guests see a different shell).
  final bool signedIn;
  final Future<void> Function(WidgetTester tester, CaptureHarness h) pump;

  String get id => '${area}_${screen}_$state';
}

/// [ScreenHarness] with a theme choice, the app's own localizations and a
/// backend whose behaviour follows [net].
class CaptureHarness extends ScreenHarness {
  CaptureHarness(String language, this.dark, this.net,
      Map<String, Map<String, String>> catalogs)
      : super(language, L10nLabelRecorder(), catalogs);

  final bool dark;
  final Net net;

  ThemeData get theme => dark
      ? AppTheme.darkFor(arabic: arabic)
      : AppTheme.lightFor(arabic: arabic);

  @override
  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
  }) async {
    AppLocale.updateCatalog(RemoteLanguageList.fromJson(languagesJson));
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: screenRootKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // Tab screens (Jobs, Education) have no Scaffold of their own;
          // in the app the shell provides it.
          home: home is Scaffold ? home : Scaffold(body: home),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(),
          ),
        ),
      ),
    ));
    await settleScreen(tester);
  }

  @override
  http.Client mockClient() {
    final ok = super.mockClient();
    return switch (net) {
      Net.ok => ok,
      Net.loading => MockClient((_) => Completer<http.Response>().future),
      Net.offline =>
        MockClient((_) async => throw http.ClientException('offline')),
      Net.error => MockClient((_) async => http.Response(
            jsonEncode({'message': 'Server error'}),
            500,
            headers: {'content-type': 'application/json'},
          )),
      Net.empty => MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/i18n/languages'))
            return ok.send(request).then(http.Response.fromStream);
          return http.Response(
            jsonEncode({
              'data':
                  path.contains('/mobile/') && !path.contains('notifications')
                      ? {'items': [], 'title': ''}
                      : [],
              'meta': {'current_page': 1, 'last_page': 1},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
    };
  }

  BuildContext contextOf(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first);
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _MyCvsContent extends MobileContentService {
  _MyCvsContent(this.items, {this.wait});
  final List<Map<String, dynamic>> items;
  final Future<void>? wait;

  @override
  Future<Map<String, dynamic>> myCvs(bool english, {bool force = false}) async {
    if (wait != null) await wait;
    return {'title': english ? 'My CVs' : 'سيرتي', 'items': items};
  }
}

List<Map<String, dynamic>> _sampleCvs(bool english) {
  final now = DateTime.now();
  Map<String, dynamic> cv(int id, String title, int? score, int daysAgo) => {
        'id': id,
        'title': title,
        'score_total': score,
        'can_download': true,
        'pdf_url': 'https://example.test/$id.pdf',
        'updated_at':
            now.subtract(Duration(days: daysAgo)).toUtc().toIso8601String(),
      };
  return english
      ? [
          cv(1, 'Senior Software Engineer', 86, 0),
          cv(2, 'Project Manager', 52, 3),
          cv(3, 'Data Analyst', null, 9),
        ]
      : [
          cv(1, 'مهندس برمجيات أول', 86, 0),
          cv(2, 'مدير مشاريع', 52, 3),
          cv(3, 'محلل بيانات', null, 9),
        ];
}

Map<String, dynamic> _plan(String key,
        {int months = 1,
        num price = 19.99,
        num? perMonth,
        bool isDefault = false,
        String? badgeEn,
        String? badgeAr}) =>
    {
      'key': key,
      'product_id': 'sirati_$key',
      'period_months': months,
      'price': price,
      'price_per_month': perMonth,
      'name_ar': switch (key) {
        'monthly' => 'شهري',
        'semiannual' => 'ستة أشهر',
        _ => 'سنوي',
      },
      'name_en': switch (key) {
        'monthly' => 'Monthly',
        'semiannual' => '6 months',
        _ => 'Annual',
      },
      'badge_ar': badgeAr,
      'badge_en': badgeEn,
      'is_default': isDefault,
      'currency': 'SAR',
    };

Map<String, dynamic> _offer({required bool subscribed}) => {
      'data': {
        'plans': [
          _plan('monthly'),
          _plan('semiannual',
              months: 6,
              price: 99,
              perMonth: 16.5,
              isDefault: true,
              badgeEn: 'Most popular',
              badgeAr: 'الأكثر شيوعاً'),
          _plan('annual', months: 12, price: 179, perMonth: 14.92),
        ],
        'currency': 'SAR',
        'trial_days': 3,
        'access': subscribed
            ? {
                'is_subscribed': true,
                'plan_key': 'semiannual',
                'expires_at': '2027-05-16T00:00:00Z',
              }
            : {'is_subscribed': false},
      },
    };

class _Plans extends SubscriptionPlansRepository {
  _Plans(this.subscribed);
  final bool subscribed;

  @override
  Future<void> syncWithStore() async {}

  @override
  Future<SubscriptionOffer> load() async =>
      SubscriptionOffer.fromJson(_offer(subscribed: subscribed));
}

class _Store implements StorePurchases {
  @override
  bool get isAvailable => true;

  @override
  Future<Map<String, StoreOffer>> offersFor({
    required int userId,
    required Map<String, int> planMonths,
  }) async =>
      {
        for (final (key, price) in [
          ('monthly', 'SAR 19.99'),
          ('semiannual', 'SAR 99.00'),
          ('annual', 'SAR 179.00'),
        ])
          key: StoreOffer(
            planKey: key,
            priceString: price,
            trial: const StoreTrial(unit: StoreTrialUnit.day, count: 3),
          ),
      };

  @override
  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
    required bool Function() isCurrent,
  }) async =>
      const StorePurchaseCancelled();

  @override
  Future<StoreRestoreOutcome> restore({
    required int userId,
    required bool Function() isCurrent,
  }) async =>
      StoreRestoreOutcome.none;
}

Map<String, dynamic> _subscription(bool subscribed) => {
      'is_subscribed': subscribed,
      'status': subscribed ? 'active' : 'free',
      'plan_key': subscribed ? 'semiannual' : null,
      'expires_at': subscribed ? '2027-05-16T00:00:00Z' : null,
      'can_job_match': subscribed,
      'trial_days': 0,
    };

class _Auth extends AuthApiService {
  _Auth({this.subscribed = false});
  final bool subscribed;

  @override
  Future<AuthUser?> me() async => AuthUser(
        id: 1,
        name: 'Sara Ali',
        email: 'sara@example.com',
        subscription: _subscription(subscribed),
      );
}

List<Override> _premium(bool subscribed) => [
      subscriptionPlansRepositoryProvider.overrideWithValue(_Plans(subscribed)),
      authApiServiceProvider.overrideWithValue(_Auth(subscribed: subscribed)),
      storePurchasesProvider.overrideWithValue(_Store()),
    ];

AppScreen _base(String id) => appScreens.firstWhere((s) => s.id == id);

Future<void> Function(WidgetTester, CaptureHarness) _fromBase(String id) =>
    (tester, h) => _base(id).pump(tester, h);

/// Pumps [home] in a bare Scaffold, then runs [open] with a context under
/// the app's Navigator (for dialogs, sheets and overlays).
Future<void> Function(WidgetTester, CaptureHarness) _overlay(
  Widget Function(CaptureHarness h) home,
  void Function(BuildContext context, CaptureHarness h) open, {
  List<Override> Function(CaptureHarness h)? overrides,
  Duration wait = const Duration(milliseconds: 1600),
}) =>
    (tester, h) async {
      await h.pumpApp(tester, home(h),
          overrides: overrides?.call(h) ?? const []);
      open(h.contextOf(tester), h);
      await _pumpFor(tester, wait);
    };

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

Future<Uint8List> _sampleImageBytes(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 600.0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size),
        Paint()..color = const Color(0xFF6FB7AE));
    canvas.drawCircle(
        const Offset(300, 240), 120, Paint()..color = const Color(0xFFF1D3B5));
    canvas.drawOval(const Rect.fromLTWH(120, 380, 360, 300),
        Paint()..color = const Color(0xFF2F4858));
    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f, warnIfMissed: false);
  await _pumpFor(tester, const Duration(milliseconds: 1200));
}

// ---------------------------------------------------------------------------
// The catalogue
// ---------------------------------------------------------------------------

final shots = <Shot>[
  // --- Start and auth ------------------------------------------------------
  Shot('start', 'splash', 'loading', 'Splash while the session is resolved',
      (tester, h) async {
    final never = Completer<String?>();
    await h.pumpApp(tester, const SplashScreen(), overrides: [
      sessionBootstrapProvider.overrideWithValue(SessionBootstrap(
        readToken: () => never.future,
        fetchUser: () async => null,
        onboardingCompleted: () async => true,
      )),
    ]);
    await _pumpFor(tester, const Duration(milliseconds: 1500));
  }),
  Shot('start', 'welcome', 'default', 'Welcome screen (signed out)',
      _fromBase('welcome')),
  Shot('start', 'onboarding', 'default', 'Onboarding, first page',
      _fromBase('onboarding')),
  Shot('auth', 'login', 'default', 'Sign in', _fromBase('login')),
  Shot('auth', 'login', 'validation', 'Sign in after submitting empty fields',
      (tester, h) async {
    await h.pumpApp(tester, const LoginScreen());
    final l10n = h.l10nOf(tester);
    await _tapText(tester, l10n.authSignInButton);
  }),
  Shot('auth', 'register', 'default', 'Create account', _fromBase('register')),
  Shot('auth', 'forgot_password', 'default', 'Forgot password',
      _fromBase('forgot_password')),
  Shot('auth', 'email_verification', 'default', 'Verify your email',
      _fromBase('email_verification')),
  Shot(
      'auth',
      'sign_in_required',
      'default',
      'Sign-in required (guest opened a member feature)',
      _fromBase('sign_in_required')),
  Shot('auth', 'session_expired', 'default', 'Session expired',
      _fromBase('session_expired')),

  // --- Home shell (glass nav bar) -----------------------------------------
  Shot('home', 'dashboard', 'default', 'Home tab with profile, stats and jobs',
      _fromBase('home')),
  Shot(
      'home',
      'dashboard',
      'guest',
      'Shell for a guest (lands on Jobs, account tabs locked)',
      _fromBase('home'),
      signedIn: false),
  Shot('home', 'dashboard', 'loading', 'Home tab while data loads',
      _fromBase('home'),
      net: Net.loading),
  Shot('home', 'dashboard', 'error', 'Home tab when the server fails',
      _fromBase('home'),
      net: Net.error),
  Shot('home', 'dashboard', 'offline', 'Home tab with no connection',
      _fromBase('home'),
      net: Net.offline),
  Shot(
      'home',
      'tab_my_cvs',
      'default',
      'Shell on the My CVs tab',
      (tester, h) =>
          h.pumpApp(tester, const HomeScreen(initialIndex: 1), overrides: [
            mobileContentServiceProvider
                .overrideWithValue(_MyCvsContent(_sampleCvs(!h.arabic))),
          ])),
  Shot('home', 'tab_education', 'default', 'Shell on the Education tab',
      (tester, h) => h.pumpApp(tester, const HomeScreen(initialIndex: 2))),
  Shot('home', 'tab_jobs', 'default', 'Shell on the Jobs tab',
      (tester, h) => h.pumpApp(tester, const HomeScreen(initialIndex: 3))),
  Shot(
      'home',
      'latest_jobs',
      'offline',
      'Home latest-jobs section with no connection',
      _fromBase('home_jobs_offline')),

  // --- My CVs and CV builder ------------------------------------------------
  Shot(
      'cv',
      'my_cvs',
      'default',
      'My CVs with three saved CVs',
      (tester, h) =>
          h.pumpApp(tester, const Scaffold(body: MyCvsScreen()), overrides: [
            mobileContentServiceProvider
                .overrideWithValue(_MyCvsContent(_sampleCvs(!h.arabic))),
          ])),
  Shot(
      'cv',
      'my_cvs',
      'empty',
      'My CVs with no CVs yet',
      (tester, h) =>
          h.pumpApp(tester, const Scaffold(body: MyCvsScreen()), overrides: [
            mobileContentServiceProvider
                .overrideWithValue(_MyCvsContent(const [])),
          ])),
  Shot(
      'cv',
      'my_cvs',
      'loading',
      'My CVs skeleton while loading',
      (tester, h) =>
          h.pumpApp(tester, const Scaffold(body: MyCvsScreen()), overrides: [
            mobileContentServiceProvider.overrideWithValue(
                _MyCvsContent(const [], wait: Completer<void>().future)),
          ])),
  Shot('cv', 'my_cvs', 'offline', 'My CVs with no connection',
      (tester, h) => h.pumpApp(tester, const Scaffold(body: MyCvsScreen())),
      net: Net.offline),
  Shot('cv', 'my_cvs', 'delete_dialog', 'Delete-CV confirmation dialog',
      (tester, h) async {
    await h.pumpApp(tester, const Scaffold(body: MyCvsScreen()), overrides: [
      mobileContentServiceProvider
          .overrideWithValue(_MyCvsContent(_sampleCvs(!h.arabic))),
    ]);
    final l10n = h.l10nOf(tester);
    final more = find.byIcon(Icons.more_horiz_rounded);
    if (more.evaluate().isNotEmpty) {
      await tester.tap(more.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 600));
    }
    await _tapText(tester, l10n.deleteItem);
  }),
  Shot('cv', 'generator', 'personal', 'CV wizard step 1: personal details',
      _fromBase('cv_personal')),
  Shot('cv', 'generator', 'skills', 'CV wizard step 2: skills',
      _fromBase('cv_skills')),
  Shot(
      'cv',
      'generator',
      'discard_dialog',
      'Discard-edits dialog',
      _overlay((_) => const CvGeneratorScreen(),
          (context, _) => unawaited(confirmDiscardEdits(context)))),
  Shot(
      'cv',
      'generator',
      'save_draft_dialog',
      'Leave wizard: save draft?',
      _overlay((_) => const CvGeneratorScreen(),
          (context, _) => unawaited(askSaveDraft(context)))),
  Shot(
      'cv',
      'generator',
      'achievement_sheet',
      'Achievement builder bottom sheet (XYZ formula)',
      _overlay(
          (_) => const CvGeneratorScreen(),
          (context, h) => unawaited(AchievementBuilderSheet.show(
              context: context, english: !h.arabic, onInsert: (_) {})))),
  Shot(
      'cv',
      'generator',
      'ai_overlay',
      'AI waiting overlay while drafting a CV',
      _overlay(
          (_) => const CvGeneratorScreen(),
          (context, h) => unawaited(AiProgressOverlay.show(context,
              kind: AiProgressKind.generation, english: !h.arabic)),
          wait: const Duration(seconds: 3))),
  Shot(
      'cv',
      'generator',
      'success_scene',
      'CV created celebration scene',
      (tester, h) => h.pumpApp(
          tester,
          Scaffold(
              body: Stack(children: [
            const Positioned.fill(child: CvGeneratorScreen()),
            Positioned.fill(
                child: ColoredBox(
                    color: Colors.black.withValues(alpha: .35),
                    child: const CvCreatedScene(progress: .8))),
          ])))),
  Shot('cv', 'builder', 'default', 'CV editor', _fromBase('cv_builder')),
  Shot('cv', 'generated_cv', 'default', 'Generated CV preview',
      _fromBase('generated_cv')),
  Shot('cv', 'generated_cv', 'loading', 'Opening a CV by link: loading',
      (tester, h) => h.pumpApp(tester, const GeneratedCvLoaderScreen(cvId: 7)),
      net: Net.loading),
  Shot('cv', 'generated_cv', 'error', 'Opening a CV by link: server error',
      (tester, h) => h.pumpApp(tester, const GeneratedCvLoaderScreen(cvId: 7)),
      net: Net.error),
  Shot('cv', 'generated_cv', 'offline', 'Opening a CV by link: offline',
      (tester, h) => h.pumpApp(tester, const GeneratedCvLoaderScreen(cvId: 7)),
      net: Net.offline),

  // --- ATS scan --------------------------------------------------------------
  Shot('ats', 'scan', 'default', 'Scan a CV (upload or pick a saved CV)',
      _fromBase('analysis_input')),
  Shot(
      'ats',
      'scan',
      'ai_overlay',
      'AI waiting overlay while scanning',
      _overlay(
          (_) => const CvAnalysisScreen(),
          (context, h) => unawaited(AiProgressOverlay.show(context,
              kind: AiProgressKind.analysis, english: !h.arabic)),
          wait: const Duration(seconds: 3))),
  Shot('ats', 'result', 'default', 'Analysis result (Premium, all items)',
      _fromBase('analysis_result')),
  Shot('ats', 'result', 'locked', 'Analysis result, free plan (items locked)',
      _fromBase('analysis_result_locked')),
  Shot(
      'ats',
      'result',
      'locked_tips',
      'Recommendations tab, free plan (items locked)',
      _fromBase('analysis_result_locked_tips')),
  Shot(
      'ats',
      'result',
      'premium_sheet',
      'Premium prompt sheet from a locked item',
      _overlay(
          (h) => const Scaffold(body: SizedBox.expand()),
          (context, _) => unawaited(
              PremiumPromptSheet.show(context, PremiumFeature.values.first)))),
  Shot(
      'ats',
      'result_by_link',
      'loading',
      'Opening an analysis by link: loading',
      (tester, h) =>
          h.pumpApp(tester, const CvAnalysisLoaderScreen(analysisId: 3)),
      net: Net.loading),
  Shot(
      'ats',
      'result_by_link',
      'error',
      'Opening an analysis by link: error',
      (tester, h) =>
          h.pumpApp(tester, const CvAnalysisLoaderScreen(analysisId: 3)),
      net: Net.error),

  // --- Job match ------------------------------------------------------------
  Shot('job_match', 'form', 'default', 'Job match: paste a job, pick a CV',
      _fromBase('job_match')),
  for (final status in ['processing', 'completed', 'failed'])
    Shot('job_match', 'result', status, 'Job match result, AI advice $status',
        (tester, h) async {
      final api = job_match.FakeJobMatchApi()
        ..createResponses.add(job_match.matchJson(
            aiStatus: status, applied: status == 'completed' ? ['s3'] : []))
        ..retryResponses.add(job_match.matchJson(aiStatus: 'processing'));
      final retry = Completer<Map<String, dynamic>>();
      if (status == 'failed') api.retryOverride = (_) => retry.future;
      await h.pumpApp(tester, const JobMatchScreen(), overrides: [
        cvApiServiceProvider.overrideWithValue(api),
        authApiServiceProvider
            .overrideWithValue(job_match.FakeAuth(job_match.subscription())),
        jobMatchPollScheduleProvider
            .overrideWithValue(const [Duration(minutes: 5)]),
      ]);
      await job_match.enterJob(tester);
      await job_match.tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await _pumpFor(tester, const Duration(milliseconds: 1500));
    }),

  // --- Jobs -----------------------------------------------------------------
  Shot('jobs', 'list', 'default', 'Job news list', _fromBase('jobs')),
  Shot('jobs', 'list', 'loading', 'Job news skeleton while loading',
      (tester, h) => h.pumpApp(tester, const JobNewsScreen(isActive: true)),
      net: Net.loading),
  Shot('jobs', 'list', 'empty', 'Job news with no results',
      (tester, h) => h.pumpApp(tester, const JobNewsScreen(isActive: true)),
      net: Net.empty),
  Shot('jobs', 'list', 'error', 'Job news: server error',
      _fromBase('jobs_error')),
  Shot('jobs', 'list', 'offline', 'Job news: offline',
      _fromBase('jobs_offline')),
  Shot(
      'jobs',
      'list',
      'matched_no_title',
      '"In my field" filter without a job title',
      _fromBase('jobs_matched_no_title')),
  Shot('jobs', 'detail', 'default', 'Job detail', _fromBase('job_detail')),

  // --- Education --------------------------------------------------------------
  Shot(
      'education', 'list', 'default', 'Education list', _fromBase('education')),
  Shot(
      'education',
      'detail',
      'default',
      'Education article',
      (tester, h) => h.pumpApp(
          tester,
          EducationDetailScreen(fallback: {
            'title': h.arabic
                ? 'كيف تكتب سيرة ذاتية تتجاوز أنظمة ATS'
                : 'How to write a CV that passes ATS',
            'body': h.arabic
                ? 'استخدم عناوين واضحة، واذكر الكلمات المفتاحية من الإعلان، واجعل إنجازاتك قابلة للقياس.\n\nتجنب الجداول والصور داخل الملف.'
                : 'Use clear headings, mirror keywords from the posting and make achievements measurable.\n\nAvoid tables and images inside the file.',
            'duration': h.arabic ? '5 دقائق' : '5 min',
            'target_role': h.arabic ? 'كل الوظائف' : 'All roles',
            'badge': h.arabic ? 'دليل' : 'Guide',
          }))),

  // --- History -----------------------------------------------------------------
  Shot('history', 'list', 'empty', 'History with no scans or CVs',
      _fromBase('history')),
  Shot('history', 'list', 'loading', 'History while loading',
      (tester, h) => h.pumpApp(tester, const HistoryScreen()),
      net: Net.loading),
  Shot('history', 'list', 'error', 'History: server error',
      (tester, h) => h.pumpApp(tester, const HistoryScreen()),
      net: Net.error),

  // --- Premium ---------------------------------------------------------------
  Shot('premium', 'plans', 'store_unavailable',
      'Premium plans when the store cannot sell', _fromBase('premium_gate')),
  Shot(
      'premium',
      'plans',
      'locked',
      'Premium plans for a free user',
      (tester, h) => h.pumpApp(tester, const PremiumGateScreen(),
          overrides: _premium(false))),
  Shot(
      'premium',
      'plans',
      'active',
      'Premium page for a subscriber',
      (tester, h) => h.pumpApp(tester, const PremiumGateScreen(),
          overrides: _premium(true))),

  // --- Settings and account -------------------------------------------------------
  Shot('settings', 'main', 'default', 'Settings', _fromBase('settings')),
  Shot('settings', 'main', 'logout_dialog', 'Sign-out confirmation',
      (tester, h) async {
    await _base('settings').pump(tester, h);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(SettingsScreen)));
    await tester.scrollUntilVisible(find.text(l10n.logOut), 300,
        scrollable: find.byType(Scrollable).first);
    await _tapText(tester, l10n.logOut);
  }),
  Shot('settings', 'language_sheet', 'default', 'Language picker sheet',
      _fromBase('language_picker')),
  Shot('settings', 'profile', 'default', 'Profile', _fromBase('profile')),
  Shot('settings', 'profile', 'photo_sheet', 'Change-photo sheet',
      (tester, h) async {
    await _base('profile').pump(tester, h);
    final button = find.byKey(const ValueKey('profile-photo-button'));
    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 1200));
  }),
  Shot('settings', 'avatar_crop', 'default', 'Crop profile photo',
      (tester, h) async {
    final bytes = await _sampleImageBytes(tester);
    await h.pumpApp(tester, AvatarCropScreen(bytes: bytes));
    // The screen decodes the photo with a real codec.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }
    await _pumpFor(tester, const Duration(milliseconds: 600));
  }),
  Shot('settings', 'change_password', 'default', 'Change password',
      _fromBase('change_password')),
  Shot('settings', 'delete_account', 'default', 'Delete account',
      _fromBase('delete_account')),
  Shot(
      'settings',
      'deleted_cleanup',
      'default',
      'Account deleted, local cleanup pending',
      _fromBase('deleted_account_cleanup')),
  Shot('settings', 'notifications', 'empty', 'Notifications, none yet',
      _fromBase('notifications')),
  Shot('settings', 'notifications', 'loading', 'Notifications while loading',
      (tester, h) => h.pumpApp(tester, const NotificationsScreen()),
      net: Net.loading),
  Shot('settings', 'notifications', 'error', 'Notifications: server error',
      (tester, h) => h.pumpApp(tester, const NotificationsScreen()),
      net: Net.error),
  Shot('settings', 'privacy', 'default', 'Privacy policy',
      _fromBase('privacy_policy')),

  // --- Shared states --------------------------------------------------------------
  Shot(
      'shared',
      'offline',
      'default',
      'Full-screen offline view',
      (tester, h) => h.pumpApp(
          tester,
          Scaffold(
              body: OfflineView(onRetry: () async {}, onOpenSaved: () {})))),
  Shot('shared', 'error', 'default', 'Something went wrong (recoverable crash)',
      _fromBase('error')),
  Shot('shared', 'not_found', 'default', '404: page not found',
      _fromBase('not_found')),
  Shot('shared', 'gallery', 'default', 'Component gallery (debug route)',
      (tester, h) => h.pumpApp(tester, const ComponentGalleryScreen())),
];

const _themes = ['light', 'dark'];
const _secureStorage =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalogs = {for (final l in screenLanguages) l: readArbCatalog(l)};
  final written = <String>{};
  final failed = <String, String>{};

  setUpAll(() async {
    AmbientMotion.enabled.value = false;
    await loadAppFonts();
    final dir = Directory(_outDir);
    if (dir.existsSync()) {
      for (final f in dir.listSync().whereType<File>()) {
        if (f.path.endsWith('.png')) f.deleteSync();
      }
    }
    dir.createSync(recursive: true);
  });

  setUp(setUpScreenTest);
  tearDown(tearDownScreenTest);

  final only = Platform.environment['SHOTS'];

  tearDownAll(() {
    final buffer = StringBuffer()
      ..writeln('# Sirati: every screen and state')
      ..writeln()
      ..writeln(
          'Generated by `flutter_app/test_screens/all_screens_capture_test.dart` '
          'on ${DateTime.now().toUtc().toIso8601String().substring(0, 10)}. '
          'Phone size 390x844 logical px at 3x (1170x2532 PNG), fake backend data, '
          'bundled app fonts, ambient motion off.')
      ..writeln()
      ..writeln('Name: `NN_<area>_<screen>_<state>_<ar|en>_<light|dark>.png`.')
      ..writeln();
    var count = 0;
    for (final (i, shot) in shots.indexed) {
      final nn = (i + 1).toString().padLeft(2, '0');
      buffer
        ..writeln('## $nn ${shot.area} / ${shot.screen} / ${shot.state}')
        ..writeln()
        ..writeln(shot.description)
        ..writeln();
      for (final lang in screenLanguages) {
        for (final theme in _themes) {
          final name = '${nn}_${shot.id}_${lang}_$theme.png';
          if (written.contains(name) || File('$_outDir/$name').existsSync()) {
            count++;
            buffer.writeln('- [$name]($name): ${shot.description}, '
                '${lang == 'ar' ? 'Arabic (RTL)' : 'English'}, $theme');
          } else {
            buffer.writeln('- $name: not captured'
                '${failed[name] != null ? ' (${failed[name]})' : ''}');
          }
        }
      }
      buffer.writeln();
    }
    if (only == null) {
      File('$_outDir/index.md').writeAsStringSync(buffer.toString());
      File('$_outDir/.failures.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(failed));
    }
    // ignore: avoid_print
    print('captured $count files, failed ${failed.length}');
  });

  for (final (i, shot) in shots.indexed) {
    final nn = (i + 1).toString().padLeft(2, '0');
    if (only != null && !only.split(',').any(shot.id.contains)) continue;
    for (final language in screenLanguages) {
      for (final theme in _themes) {
        final name = '${nn}_${shot.id}_${language}_$theme.png';
        testWidgets('capture $name', (tester) async {
          AppLocale.languageCode.value = language;
          tester.view.physicalSize = const Size(_width, _height) * _ratio;
          tester.view.devicePixelRatio = _ratio;
          tester.view.padding =
              const FakeViewPadding(top: 47 * _ratio, bottom: 34 * _ratio);
          tester.view.viewPadding =
              const FakeViewPadding(top: 47 * _ratio, bottom: 34 * _ratio);
          tester.platformDispatcher.platformBrightnessTestValue =
              theme == 'dark' ? Brightness.dark : Brightness.light;
          addTearDown(tester.view.reset);
          addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue);
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(_secureStorage, (call) async {
            final args = call.arguments;
            if (call.method == 'read' &&
                args is Map &&
                args['key'] == 'sirati_auth_token') {
              return shot.signedIn ? 'capture-token' : null;
            }
            return null;
          });
          final h =
              CaptureHarness(language, theme == 'dark', shot.net, catalogs);
          try {
            await http.runWithClient(() async {
              await shot.pump(tester, h);
              await _precacheImages(tester);
              await _writePng(tester, '$_outDir/$name');
              written.add(name);
            }, h.mockClient);
          } catch (e) {
            failed[name] = e.toString().split('\n').first;
            rethrow;
          } finally {
            // Let endless spinners, retries and timeouts run out so the
            // next test starts clean.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(minutes: 2));
          }
        });
      }
    }
  }
}

Future<void> _precacheImages(WidgetTester tester) async {
  final images = find.byType(Image).evaluate().toList();
  if (images.isEmpty) return;
  await tester.runAsync(() async {
    for (final element in images) {
      final image = element.widget as Image;
      await precacheImage(image.image, element, onError: (_, __) {});
    }
  });
  await tester.pump();
}

Future<void> _writePng(WidgetTester tester, String path) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(screenRootKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
