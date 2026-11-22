import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

class _Api extends CvApiService {
  int submits = 0;
  @override
  Future<CvAnalysis> submitAnalysis({
    required String targetJobTitle,
    required String resumeText,
    String? jobDescription,
    http.MultipartFile? resumeFile,
    String? idempotencyKey,
  }) async {
    submits++;
    return _analysis(AiStatus.queued);
  }

  @override
  Future<AiPollResult<CvAnalysis>> pollAnalysis(
    CvAnalysis initial, {
    bool Function()? isCancelled,
    bool Function()? isPaused,
    void Function(CvAnalysis value)? onProgress,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return AiPollResult(value: _analysis(AiStatus.failed));
  }
}

CvAnalysis _analysis(String status) => CvAnalysis.fromJson({
      'id': 42,
      'target_job_title': 'Laravel Developer',
      'original_filename': null,
      'input_method': 'paste',
      'score_total': 82,
      'grade': 'A',
      'job_match': 78,
      'criteria': [
        {'label': 'Keywords', 'score': 25, 'max': 30},
      ],
      'strengths': ['Strong keyword coverage'],
      'weaknesses': const [],
      'keywords_found': ['Laravel'],
      'keywords_missing': ['Docker'],
      'quick_wins': ['Add Docker'],
      'ai_status': status,
      'ai_feedback': null,
      'ai_error': status == AiStatus.failed ? 'Provider unavailable' : null,
      'created_at': '2026-07-29T00:00:00Z',
    });

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );

void main() {
  testWidgets(
      '(a) Retry after backing out of the result and the form '
      'does not touch the disposed form', (tester) async {
    AppLocale.languageCode.value = 'en';
    final api = _Api();
    await tester.pumpWidget(ProviderScope(
      overrides: [cvApiServiceProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CvAnalysisScreen(
                      savedCvs: AsyncData(
                          [SavedAnalysisCv(id: 1, title: 'Laravel CV')]),
                      initialCvId: 1,
                      initialMarkdown: 'Laravel developer resume with API, '
                          'SQL, Git, and measurable results.',
                    ),
                  ),
                ),
                child: const Text('home'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      _fieldWithHint('e.g. Laravel Backend Developer'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
        _fieldWithHint('e.g. Laravel Backend Developer'), 'Laravel Developer');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1000));
    await tester.pump();
    tester.widget<SubmitButton>(find.byType(SubmitButton)).onPressed!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AnalysisResultScreen), findsOneWidget);
    expect(api.submits, 1);
    expect(find.text('Retry'), findsOneWidget);

    // Back out of the result and the form.
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((r) => r.isFirst);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CvAnalysisScreen), findsNothing);
    expect(find.text('Retry'), findsOneWidget,
        reason: 'the snackbar outlives the form');

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
