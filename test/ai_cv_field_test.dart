import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/app_locale.dart';
import 'package:sirati/screens/cv_generator_screen.dart';
import 'package:sirati/services/api_exception.dart';
import 'package:sirati/services/cv_api_service.dart';
import 'package:sirati/theme/app_theme.dart';
import 'package:sirati/widgets/ai_cv_field.dart';
import 'package:sirati/widgets/form_fields.dart';
import 'package:sirati/widgets/submit_button.dart';

void main() {
  testWidgets('enhance action is disabled under ten characters',
      (tester) async {
    final controller = TextEditingController(text: 'short');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_testApp(
      AiCvField(
        field: 'skills',
        controller: controller,
        english: true,
        isLoading: false,
        helperText: 'Example',
        onEnhance: () {},
        onDismissResult: () {},
        child: AppTextFormField(controller: controller),
      ),
    ));

    final button =
        tester.widget<SubmitButton>(find.byKey(const Key('enhance_skills')));
    expect(button.onPressed, isNull);

    controller.text = 'Laravel PHP';
    await tester.pump();
    final enabled =
        tester.widget<SubmitButton>(find.byKey(const Key('enhance_skills')));
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('loading overlay appears and missing facts render prominently',
      (tester) async {
    final controller = TextEditingController(text: 'Laravel and PHP');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_testApp(
      AiCvField(
        field: 'skills',
        controller: controller,
        english: true,
        isLoading: true,
        helperText: 'Example',
        result: const {
          'changes_made': ['Grouped technical skills'],
          'missing_facts': ['Add years of experience'],
          'ats_keywords_added': ['Laravel'],
          'unverified_claims': [
            {'text': 'Acme Corp', 'kind': 'employer'},
          ],
        },
        onEnhance: () {},
        onDismissResult: () {},
        child: AppTextFormField(controller: controller),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byKey(const Key('missing_facts_skills')), findsOneWidget);
    expect(find.text('Add years of experience'), findsOneWidget);
    expect(find.byKey(const Key('unverified_claims_skills')), findsOneWidget);
    expect(find.text('Acme Corp'), findsOneWidget);
  });

  testWidgets('undo restores exact pre-enhance text', (tester) async {
    final api = _FakeCvApiService();
    await _openSkillsStep(tester, api);
    final skills = _fieldWithHint('PHP, Laravel, API, SQL, Git, Agile, Docker');
    const original = 'Laravel PHP APIs';
    await tester.enterText(skills, original);
    await _tapEnhance(tester, 'skills');

    api.complete('skills', {
      'enhanced_text': 'Laravel, PHP, REST APIs',
      'changes_made': ['Improved structure'],
      'missing_facts': ['Add years of experience'],
      'ats_keywords_added': ['REST API'],
    });
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(skills).controller!.text,
        'Laravel, PHP, REST APIs');

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(tester.widget<TextField>(skills).controller!.text, original);
  });

  testWidgets('superseded field requests are discarded', (tester) async {
    final api = _FakeCvApiService();
    await _openSkillsStep(tester, api);
    final skills = _fieldWithHint('PHP, Laravel, API, SQL, Git, Agile, Docker');
    final summary =
        _fieldWithHint('Briefly describe your experience and achievements...');
    await tester.enterText(skills, 'Laravel PHP APIs');
    await tester.enterText(summary, 'Backend developer draft');

    await _tapEnhance(tester, 'skills');
    await _tapEnhance(tester, 'summary');

    api.complete('skills', _result('stale skills response'));
    await tester.pump();
    expect(
        tester.widget<TextField>(skills).controller!.text, 'Laravel PHP APIs');

    api.complete('summary', _result('current summary response'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(summary).controller!.text,
        'current summary response');
  });

  testWidgets('overlay clears when enhancement fails', (tester) async {
    final api = _FakeCvApiService();
    await _openSkillsStep(tester, api);
    final skills = _fieldWithHint('PHP, Laravel, API, SQL, Git, Agile, Docker');
    await tester.enterText(skills, 'Laravel PHP APIs');
    await _tapEnhance(tester, 'skills');
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    api.fail('skills');
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

Widget _testApp(Widget home) => MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.light,
      home: home is CvGeneratorScreen
          ? home
          : Scaffold(body: SingleChildScrollView(child: home)),
    );

Future<void> _tapEnhance(WidgetTester tester, String field) async {
  tester.testTextInput.hide();
  await tester.pump();
  final button = tester.widget<SubmitButton>(find.byKey(Key('enhance_$field')));
  expect(button.onPressed, isNotNull);
  button.onPressed!();
  await tester.pump();
}

Future<void> _openSkillsStep(
  WidgetTester tester,
  _FakeCvApiService api,
) async {
  AppLocale.languageCode.value = 'en';
  await tester.pumpWidget(_testApp(CvGeneratorScreen(apiService: api)));
  await tester.pump();
  await tester.enterText(_fieldWithHint('Salem Sayer'), 'Salem Sayer');
  await tester.enterText(
      _fieldWithHint('Laravel Backend Developer'), 'Backend Developer');
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  expect(find.text('Skills & Summary'), findsOneWidget);
}

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );

Map<String, dynamic> _result(String text) => {
      'enhanced_text': text,
      'changes_made': <String>[],
      'missing_facts': <String>[],
      'ats_keywords_added': <String>[],
      'unverified_claims': <Map<String, String>>[],
    };

class _FakeCvApiService extends CvApiService {
  final Map<String, Completer<Map<String, dynamic>>> _requests = {};

  @override
  Future<Map<String, dynamic>> enhanceCvField({
    required String field,
    required String draft,
    required String jobTitle,
    required String language,
  }) {
    return (_requests[field] = Completer<Map<String, dynamic>>()).future;
  }

  void complete(String field, Map<String, dynamic> result) {
    _requests[field]!.complete(result);
  }

  void fail(String field) {
    _requests[field]!.completeError(
      const ApiException('Request failed', type: ApiErrorType.server),
    );
  }
}
