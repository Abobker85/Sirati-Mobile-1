import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Content extends MobileContentService {
  _Content(this.export);
  final Map<String, dynamic> export;

  @override
  Future<Map<String, dynamic>> myCvs(bool english, {bool force = false}) async =>
      {
        'title': 'My CVs',
        'items': [
          {
            'id': 7,
            'title': 'Salem CV',
            'pdf_url': 'https://example.test/cvs/7.pdf?signature=x',
            'template_pdf_url': 'https://example.test/cvs/7.pdf?signature=x',
            'can_download': true,
            'export': export,
          },
        ],
      };
}

void main() {
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');
  String? launched;
  setUp(() {
    launched = null;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, (call) async {
      launched = (call.arguments as Map)['url'] as String;
      return true;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(launcher, null));

  // Every reason the server refuses an export: the download button explains
  // it in the app and never sends the user to the browser error page.
  for (final language in ['ar', 'en']) {
    for (final reason in [
      'generating',
      'missing_contact',
      'unstructured_experience',
    ]) {
      testWidgets('$language/$reason: blocked CV stays in the app',
          (tester) async {
        AppLocale.languageCode.value = language;
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final message = '$language: fix $reason';
        await tester.pumpWidget(ProviderScope(
          overrides: [
            mobileContentServiceProvider.overrideWithValue(_Content({
              'ready': false,
              'blocked_reason': reason,
              'message_ar': language == 'ar' ? message : 'other language',
              'message_en': language == 'en' ? message : 'other language',
            })),
          ],
          child: MaterialApp(
            theme: AppTheme.lightFor(arabic: language == 'ar'),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: MyCvsScreen()),
          ),
        ));
        await tester.pumpAndSettle();

        final download = find.byIcon(Icons.download_rounded);
        expect(download, findsOneWidget);
        await tester.ensureVisible(download);
        await tester.tap(download);
        await tester.pumpAndSettle();

        expect(launched, isNull);
        expect(find.byType(BottomSheet), findsNothing,
            reason: 'no template picker for a CV that cannot be exported');
        expect(find.text(message), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
}
