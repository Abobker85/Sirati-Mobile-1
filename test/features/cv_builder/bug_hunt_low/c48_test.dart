import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Content extends MobileContentService {
  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {
        'title': 'My CVs',
        'items': [
          {'id': 7, 'title': 'CV 7', 'can_download': true},
        ],
      };
}

class _Api extends CvApiService {
  final gate = Completer<void>();
  Object error = const ApiException('offline', type: ApiErrorType.network);
  @override
  Future<GeneratedCv> getGeneratedCv(int id) async {
    await gate.future;
    throw error;
  }
}

void main() {
  for (final err in <Object>[
    const ApiException('offline', type: ApiErrorType.network),
    StateError('boom'),
  ]) {
    testWidgets(
        'Edit then leave the tab while the CV loads, load fails: '
        'no use of a disposed context ($err)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppLocale.languageCode.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final api = _Api()..error = err;
      final showCvs = ValueNotifier(true);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          mobileContentServiceProvider.overrideWithValue(_Content()),
          cvApiServiceProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showCvs,
              builder: (_, show, __) =>
                  show ? const MyCvsScreen() : const Text('other tab'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('CV options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // The user switches tab: My CVs is disposed while the load runs.
      showCvs.value = false;
      await tester.pumpAndSettle();
      expect(find.text('other tab'), findsOneWidget);

      api.gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
