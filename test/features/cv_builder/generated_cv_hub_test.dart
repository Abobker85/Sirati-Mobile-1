import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';
import '../../support/non_text_contrast.dart';

GeneratedCv _cv({String status = 'completed', String language = 'ar'}) =>
    GeneratedCv.fromJson({
      'id': 91,
      'full_name': 'سارة أحمد Sara Ahmed',
      'target_job_title': 'مهندسة نظم Distributed Systems Engineer',
      'language': language,
      'generated_markdown': '## Summary\n'
          '${List.generate(12, (i) => 'Experience $i: تحليل البيانات C++ and SQL.').join('\n')}\n'
          '## Skills\n- C++\n- SQL',
      'email': 'sara@example.test',
      'phone': '+966501234567',
      'ai_status': status,
      'ai_error': status == 'failed' ? 'provider_timeout' : null,
      'score_total': 83,
      'grade': 'B',
      'pdf_url': 'https://example.test/cvs/91.pdf?signature=fresh',
    });

class _Api extends CvApiService {
  int fetches = 0;

  @override
  Future<GeneratedCv> getGeneratedCv(int id) async {
    expect(id, 91);
    fetches++;
    return _cv();
  }
}

Future<void> _pump(WidgetTester tester, {
  String language = 'ar',
  bool dark = false,
  String status = 'completed',
  _Api? api,
  RouteFactory? onGenerateRoute,
}) async {
  AppLocale.languageCode.value = language;
  registerSiratiRouteWidgets();
  await tester.pumpWidget(ProviderScope(
    overrides: [cvApiServiceProvider.overrideWithValue(api ?? _Api())],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: language == 'ar')
          : AppTheme.lightFor(arabic: language == 'ar'),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateRoute: onGenerateRoute,
      home: GeneratedCvScreen(generatedCv: _cv(status: status, language: language)),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final status in ['completed', 'processing', 'failed', 'not_configured']) {
        testWidgets('$language/$dark/$status: hub at 2x, readable and responsive',
            (tester) async {
          usePhoneViewAtTextScale(tester);
          await _pump(tester, language: language, dark: dark, status: status);
          final context = tester.element(find.byType(GeneratedCvScreen));
          expect(Directionality.of(context),
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          final download = find.byKey(GeneratedCvScreen.downloadKey);
          final share = find.byKey(GeneratedCvScreen.shareKey);
          expect(tester.getTopLeft(download).dy, lessThan(tester.getTopLeft(share).dy));
          expect(tester.widget<ElevatedButton>(download).enabled, isTrue);
          for (final key in [GeneratedCvScreen.atsStepKey,
              GeneratedCvScreen.jobMatchStepKey, GeneratedCvScreen.editStepKey]) {
            expect(find.byKey(key), findsOneWidget);
            expect(tester.getTopLeft(download).dy,
                lessThan(tester.getTopLeft(find.byKey(key)).dy));
          }
          expect(find.byKey(GeneratedCvScreen.atsScoreKey),
              ['completed', 'not_configured'].contains(status) ? findsOneWidget : findsNothing);
          final label = '$language/$dark/$status at 2x';
          expectAllTextAa(label);
          expectAllIconsNonTextAa(label);
          for (final element in find.byType(CircularProgressIndicator).evaluate()) {
            final progress = element.widget as CircularProgressIndicator;
            for (final bg in paintedBackgroundsOf(element)) {
              expect(AppContrast.ratio(progress.color!, bg), greaterThanOrEqualTo(3));
            }
          }
          expect(tester.takeException(), isNull);
          expect(find.byKey(GeneratedCvScreen.previewToggleKey), findsOneWidget);
          await _tap(tester, GeneratedCvScreen.previewToggleKey);
          expectAllTextAa('$label full preview');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('hub cards reach ATS, Job Match and the existing editor', (tester) async {
    usePhoneViewAtTextScale(tester, scale: 1);
    SharedPreferences.setMockInitialValues({});
    String? destination;
    await _pump(tester, onGenerateRoute: (settings) {
      destination = settings.name;
      return MaterialPageRoute<void>(builder: (_) => const Scaffold());
    });
    await _tap(tester, GeneratedCvScreen.atsStepKey);
    expect(find.byType(CvAnalysisScreen), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await _tap(tester, GeneratedCvScreen.jobMatchStepKey);
    expect(destination, AppRoutes.jobMatch);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await _tap(tester, GeneratedCvScreen.editStepKey);
    expect(find.byKey(GeneratedCvScreen.previewKey), findsNothing);
  });

  testWidgets('Download opens the fresh server PDF link; Share contains the CV',
      (tester) async {
    usePhoneViewAtTextScale(tester, scale: 1);
    final api = _Api();
    String? launched;
    String? shared;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    messenger.setMockMethodCallHandler(launcher, (call) async {
      launched = (call.arguments as Map)['url'] as String;
      return true;
    });
    messenger.setMockMethodCallHandler(share, (call) async {
      shared = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(launcher, null);
      messenger.setMockMethodCallHandler(share, null);
    });
    await _pump(tester, api: api);
    await _tap(tester, GeneratedCvScreen.downloadKey);
    expect(api.fetches, 1);
    expect(launched, _cv().pdfUrl);
    // Dismiss the transient download notice before tapping the next action.
    await tester.pump(const Duration(seconds: 5));
    await _tap(tester, GeneratedCvScreen.shareKey);
    for (var i = 0; i < 12; i++) {
      expect(shared, contains('Experience $i: تحليل البيانات C++ and SQL.'));
    }
    expect(shared, contains(_cv().fullName));
    expect(shared, isNot(contains('##')));
  });
}
