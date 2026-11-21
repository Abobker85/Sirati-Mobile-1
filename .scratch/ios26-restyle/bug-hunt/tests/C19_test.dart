// C19: focusing a field (no typing) while the draft restore banner shows
// must not dismiss the offer nor delete the stored draft.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/application/cv_draft_store.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/draft_restore_banner.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Real save() logic (empty form -> clear()); only storage is faked.
class _Store extends CvDraftStore {
  _Store(this.draft) : super(const PreferenceStore());
  SavedCvDraft? draft;
  var clears = 0;
  @override
  Future<SavedCvDraft?> read({required int stepCount}) async => draft;
  @override
  Future<void> clear() async {
    clears++;
    draft = null;
  }
}

class _Api extends CvApiService {}

void main() {
  for (final language in ['ar', 'en']) {
    for (var field = 0; field < 3; field++) {
      testWidgets('$language field $field: tap without typing keeps draft',
          (tester) async {
        AppLocale.languageCode.value = language;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final store = _Store(SavedCvDraft(
          data: CvFormData(
              fullName: 'Sara Ali', email: 'sara@example.com', language: language),
          step: 0,
          savedAt: null,
        ));
        await tester.pumpWidget(ProviderScope(
          overrides: [
            cvApiServiceProvider.overrideWithValue(_Api()),
            cvDraftStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: AppTheme.lightFor(arabic: language == 'ar'),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const CvGeneratorScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(DraftRestoreBanner), findsOneWidget);

        final target = find.byType(TextField).at(field);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(store.clears, 0, reason: 'stored draft deleted by a focus alone');
        // The field may have scrolled the banner away: scroll back to the top.
        await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        expect(find.byType(DraftRestoreBanner, skipOffstage: false),
            findsOneWidget,
            reason: 'restore offer dismissed by a focus alone');
        expect(store.draft, isNotNull);
      });
    }
  }
}
