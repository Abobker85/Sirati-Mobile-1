import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Content extends MobileContentService {
  @override
  Future<Map<String, dynamic>> myCvs(bool english, {bool force = false}) async =>
      {
        'title': english ? 'My CVs' : 'سيرتي',
        'items': [
          for (var i = 1; i <= 12; i++)
            {'id': i, 'title': 'CV $i', 'score_total': 50, 'can_download': true},
        ],
      };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('C49: a fresh list at offset 0 after a language switch shows one header',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final locale = ValueNotifier(const Locale('ar'));
    AppLocale.languageCode.value = 'ar';
    addTearDown(() => AppLocale.languageCode.value = 'ar');
    await tester.pumpWidget(ProviderScope(
      overrides: [mobileContentServiceProvider.overrideWithValue(_Content())],
      child: ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (_, l, __) => MaterialApp(
          theme: AppTheme.lightFor(arabic: l.languageCode == 'ar'),
          locale: l,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: MyCvsScreen()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MyCvsSlimHeader), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(MyCvsSlimHeader), findsOneWidget);

    AppLocale.languageCode.value = 'en';
    locale.value = const Locale('en');
    await tester.pumpAndSettle();

    final offset = Scrollable.of(tester.element(find.byType(MyCvsHeader)))
        .position
        .pixels;
    expect(offset, 0, reason: 'the new English list starts at the top');
    expect(find.byType(MyCvsHeader), findsOneWidget);
    expect(find.byType(MyCvsSlimHeader), findsNothing,
        reason: 'list is at the top, so only the large title should show');
  });
}
