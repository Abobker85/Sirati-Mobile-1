/// l10n screen capture: renders the app's main screens in `ar` and `en` and
/// records, for every painted label, the l10n key it came from and its rect.
///
/// Run (from the Flutter app root; not part of the normal `flutter test`
/// run because it lives outside `test/`):
///
///   flutter test test_screens/capture_screens_test.dart
///
/// Output (git-ignored): `build/l10n_screens/<id>.<locale>.png` at 390 px
/// wide, pixel ratio 2, light theme, bundled IBM Plex Sans Arabic, plus
/// `build/l10n_screens/manifest.json` (version 1) listing each screen's
/// labels as `{key, x, y, w, h}` in logical px of that image. Scroll views
/// are captured at their full content height (capped at [_maxHeight]); the
/// image height is in the manifest.
///
/// The admin label editor shows these screenshots and highlights the label
/// being edited. Copy the whole `build/l10n_screens/` folder to the Laravel
/// repo at `D:\Sirati\resources\i18n\screens\` (this test does not copy it).
///
/// Keys are recorded at runtime: a test-only [RecordingRemoteStringLookup]
/// feeds the bundled ARB messages through the generated
/// RemoteAppLocalizations, so each getter/method reports key -> final
/// string; painted RenderParagraph/RenderEditable text is then matched to
/// those strings (see `test/support/l10n_label_capture.dart`).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/dashboard/presentation/home_screen.dart';
import 'package:sirati/features/dashboard/presentation/splash/welcome_body.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/presentation/settings/language_picker_sheet.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../test/features/job_match/job_match_test_support.dart' as job_match;
import '../test/support/l10n_label_capture.dart';

const _width = 390.0;
const _height = 844.0;
const _pixelRatio = 2.0;
const _maxHeight = 4000.0;
const _outDir = 'build/l10n_screens';
const _languages = ['ar', 'en'];
const _rootKey = ValueKey('l10n-capture-root');
const _secureStorage =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// One capturable screen. [pump] puts it on screen; [fullHeight] grows the
/// view to the primary scroll view's content height.
class _Screen {
  const _Screen(this.id, this.name, this.pump, {this.fullHeight = true});

  final String id;
  final String name;
  final Future<void> Function(WidgetTester tester, _Harness h) pump;
  final bool fullHeight;
}

class _Harness {
  _Harness(this.language, this.recorder, this.catalogs);

  final String language;
  final L10nLabelRecorder recorder;
  final Map<String, Map<String, String>> catalogs;

  bool get arabic => language == 'ar';

  AppLocalizations get l10n => lookupAppLocalizations(Locale(language));

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: _rootKey,
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
    await _settle(tester);
  }
}

/// Advances frames until idle (or ~4 s of fake time for endless spinners).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
    );

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
  _SettingsAuth(this.arabic);
  final bool arabic;

  @override
  Future<AuthUser?> me() async => AuthUser(
        id: 1,
        name: arabic ? 'سارة العلي' : 'Sara Ali',
        email: 'sara@example.com',
      );
}

Future<void> _pumpSettings(WidgetTester tester, _Harness h) => h.pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        authApiServiceProvider.overrideWithValue(_SettingsAuth(h.arabic)),
        notificationPrefsGatewayProvider.overrideWithValue(_SettingsGateway()),
      ],
    );

CvAnalysis _sampleAnalysis(bool arabic) => CvAnalysis.fromJson({
      'keyword_source': 'category',
      'id': 1,
      'target_job_title': arabic ? 'مطور واجهات خلفية' : 'Backend Developer',
      'score_total': 72,
      'grade': 'B',
      'job_match': 68,
      'ai_status': 'completed',
      'strengths': [arabic ? 'ملخص واضح' : 'Clear summary'],
      'weaknesses': [
        {
          'title': arabic ? 'أرقام قليلة' : 'Few metrics',
          'suggestion':
              arabic ? 'اذكر نتائج قابلة للقياس' : 'Quantify outcomes',
        },
      ],
      'keywords_found': ['PHP', 'Laravel', 'MySQL'],
      'keywords_missing': ['Docker', 'Kubernetes'],
      'quick_wins': [
        arabic ? 'أضف نتائج قابلة للقياس' : 'Add measurable outcomes'
      ],
      'criteria': [
        {'label': 'Structure', 'score': 6, 'max': 10},
        {'label': 'Keywords', 'score': 7, 'max': 10},
        {'label': 'Impact', 'score': 9, 'max': 10},
      ],
    });

final _screens = <_Screen>[
  _Screen('welcome', 'Welcome', (tester, h) {
    return h.pumpApp(
      tester,
      Scaffold(
        body: WelcomeBody(onRegister: () {}, onLogin: () {}, onPrivacy: () {}),
      ),
    );
  }),
  _Screen(
      'login', 'Login', (tester, h) => h.pumpApp(tester, const LoginScreen())),
  _Screen('register', 'Register', (tester, h) {
    return h.pumpApp(tester, const RegisterScreen(), overrides: [
      jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
    ]);
  }),
  _Screen('home', 'Dashboard home',
      (tester, h) => h.pumpApp(tester, const HomeScreen())),
  _Screen('cv_personal', 'CV wizard: personal details',
      (tester, h) => h.pumpApp(tester, const CvGeneratorScreen())),
  _Screen('cv_skills', 'CV wizard: skills', (tester, h) async {
    await h.pumpApp(tester, const CvGeneratorScreen());
    final l10n = h.l10n;
    final name = h.arabic ? 'سارة العلي' : 'Sara Ali';
    final job = h.arabic ? 'مطورة واجهات خلفية' : 'Backend Developer';
    await tester.enterText(_fieldWithHint(l10n.cvPersonalFullNameHint), name);
    await tester.enterText(
        _fieldWithHint('salem@example.com'), 'sara@example.com');
    await tester.enterText(
        _fieldWithHint('+966 5X XXX XXXX'), '+966 59 189 0300');
    await tester.enterText(_fieldWithHint(l10n.cvPersonalTargetJobHint), job);
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.text(l10n.next).last);
    await _settle(tester);
  }),
  _Screen('analysis_input', 'CV analysis',
      (tester, h) => h.pumpApp(tester, const CvAnalysisScreen())),
  _Screen('analysis_result', 'Analysis result', (tester, h) {
    return h.pumpApp(
        tester, AnalysisResultScreen(analysis: _sampleAnalysis(h.arabic)));
  }),
  _Screen('job_match', 'Job match', (tester, h) {
    final api = job_match.FakeJobMatchApi()
      ..cvs = [
        job_match.savedCv(1,
            title: h.arabic ? 'محللة بيانات' : 'Data Analyst',
            name: h.arabic ? 'سارة العلي' : 'Sara Ali'),
      ];
    return h.pumpApp(tester, const JobMatchScreen(), overrides: [
      cvApiServiceProvider.overrideWithValue(api),
      authApiServiceProvider
          .overrideWithValue(job_match.FakeAuth(job_match.subscription())),
    ]);
  }),
  _Screen('jobs', 'Jobs',
      (tester, h) => h.pumpApp(tester, const JobNewsScreen(isActive: true))),
  const _Screen('settings', 'Settings', _pumpSettings),
  _Screen('language_picker', 'Language picker', (tester, h) async {
    await _pumpSettings(tester, h);
    final context = tester.element(find.byType(SettingsScreen));
    // The sheet's future completes when it closes; capture while open.
    unawaited(showLanguagePicker(context));
    await _settle(tester);
  }, fullHeight: false),
];

http.Response _json(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Backend stand-in (data adapted from dark_mode_12_screen_walk_test).
http.Client _mockClient(bool arabic) => MockClient((request) async {
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

/// Loads every bundled font (app + Material icons). Text whose style names
/// no font family (e.g. a button `textStyle`) still renders in the test
/// engine's box font: on a phone it uses the platform font.
Future<void> _loadFonts() async {
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

Future<void> _precacheImages(WidgetTester tester) async {
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in images) {
      final image = element.widget as Image;
      await precacheImage(image.image, element, onError: (_, __) {});
    }
  });
  await tester.pump();
}

/// Content height of a scroll view: its slivers' extents when it is a
/// sliver viewport (exact once the view is tall enough to build them all,
/// and smaller than the viewport when content is short), else the extent
/// reported by its position.
double _contentHeight(ScrollableState scrollable) {
  final position = scrollable.position;
  RenderViewportBase? viewport;
  void find(RenderObject node) {
    if (viewport != null) return;
    if (node is RenderViewportBase) {
      viewport = node;
      return;
    }
    node.visitChildren(find);
  }

  final box = scrollable.context.findRenderObject();
  if (box != null) find(box);
  if (viewport case final v?) {
    var total = 0.0;
    v.visitChildren((child) {
      if (child is RenderSliver) total += child.geometry?.scrollExtent ?? 0;
    });
    return total;
  }
  return position.maxScrollExtent -
      position.minScrollExtent +
      position.viewportDimension;
}

/// Resizes the view so the primary onstage vertical scroll view shows all
/// of its content (between [_height] and [_maxHeight]); returns the height.
Future<double> _fitToContent(WidgetTester tester) async {
  var height = _height;
  for (var i = 0; i < 6; i++) {
    final onstage =
        onstageRenderObjects(tester.renderObject(find.byKey(_rootKey)));
    final scrollables = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) =>
            s.position.axis == Axis.vertical &&
            s.position.hasContentDimensions &&
            onstage.contains(s.context.findRenderObject()))
        .toList();
    if (scrollables.isEmpty) break;
    scrollables.sort((a, b) =>
        b.position.viewportDimension.compareTo(a.position.viewportDimension));
    final primary = scrollables.first;
    final delta = _contentHeight(primary) - primary.position.viewportDimension;
    final next = (height + delta).clamp(_height, _maxHeight).ceilToDouble();
    if ((next - height).abs() < 1) break;
    height = next;
    tester.view.physicalSize = Size(_width, height) * _pixelRatio;
    await _settle(tester);
  }
  return height;
}

Future<void> _writePng(WidgetTester tester, String path) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_rootKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

String? _gitCommit() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    final sha = (result.stdout as String).trim();
    return result.exitCode == 0 && sha.isNotEmpty ? sha : null;
  } catch (_) {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalogs = {for (final l in _languages) l: readArbCatalog(l)};
  final enKeys = catalogs['en']!.keys.toSet();
  // id -> language -> manifest entry for that image.
  final captured = <String, Map<String, Map<String, Object>>>{};

  setUpAll(() async {
    await _loadFonts();
    final dir = Directory(_outDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
  });

  setUp(() {
    MobileContentService.invalidate();
    // Test-only API; the analyzer only knows test/ as a test directory.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, null);
  });

  tearDownAll(() {
    final screens = [
      for (final (index, screen) in _screens.indexed)
        if (captured[screen.id] case final locales?
            when locales.length == _languages.length)
          {
            'id': screen.id,
            'name': screen.name,
            'order': index + 1,
            'locales': {for (final l in _languages) l: locales[l]},
          },
    ];
    final manifest = {
      'version': 1,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'app_commit': _gitCommit(),
      'device': {'width': 390, 'height': 844, 'pixel_ratio': 2},
      'screens': screens,
    };
    File('$_outDir/manifest.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest));
  });

  for (final screen in _screens) {
    for (final language in _languages) {
      testWidgets('capture ${screen.id}.$language', (tester) async {
        AppLocale.languageCode.value = language;
        tester.view.physicalSize = const Size(_width, _height) * _pixelRatio;
        tester.view.devicePixelRatio = _pixelRatio;
        addTearDown(tester.view.reset);
        final recorder = L10nLabelRecorder();
        final h = _Harness(language, recorder, catalogs);

        await http.runWithClient(() async {
          await screen.pump(tester, h);
          final height =
              screen.fullHeight ? await _fitToContent(tester) : _height;
          await _precacheImages(tester);
          await _settle(tester);

          final root = tester.renderObject(find.byKey(_rootKey));
          final hits = findLabelHits(root, recorder.keysByValue);
          expect(hits, isNotEmpty, reason: 'no labels found on ${screen.id}');
          for (final hit in hits) {
            expect(enKeys, contains(hit.key));
            expect(hit.rect.left, greaterThanOrEqualTo(0));
            expect(hit.rect.top, greaterThanOrEqualTo(0));
            expect(hit.rect.right, lessThanOrEqualTo(_width + 0.01));
            expect(hit.rect.bottom, lessThanOrEqualTo(height + 0.01));
          }

          final image = '${screen.id}.$language.png';
          await _writePng(tester, '$_outDir/$image');
          (captured[screen.id] ??= {})[language] = {
            'image': image,
            'width': _width,
            'height': height,
            'labels': [for (final hit in hits) hit.toJson()],
          };

          // Unmount inside the zone so pending timers are cancelled.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        }, () => _mockClient(language == 'ar'));
      });
    }
  }
}
