import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/application/cv_draft_store.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// In-memory store that behaves like the real one (save keeps the draft,
/// clear removes it) and records the order of operations.
class _MemoryDraftStore extends CvDraftStore {
  _MemoryDraftStore() : super(const PreferenceStore());
  SavedCvDraft? stored;
  final ops = <String>[];

  @override
  Future<SavedCvDraft?> read({required int stepCount}) async => stored;

  @override
  Future<void> save(CvFormData data, {required int step}) async {
    ops.add('save');
    stored = data.hasContent
        ? SavedCvDraft(data: data, step: step, savedAt: DateTime.now())
        : null;
  }

  @override
  Future<void> clear() async {
    ops.add('clear');
    stored = null;
  }
}

class _FakeApi extends CvApiService {}

void main() {
  for (final text in ['Sara Ali', 'x', 'سارة علي']) {
    testWidgets('C05: Discard on exit leaves no draft behind ("$text")',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppLocale.languageCode.value = 'en';
      final store = _MemoryDraftStore();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          cvApiServiceProvider.overrideWithValue(_FakeApi()),
          cvDraftStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const CvGeneratorScreen(),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(CvGeneratorScreen), findsOneWidget);

      // Make the form dirty.
      await tester.enterText(find.byType(EditableText).first, text);
      await tester.pump();

      // Back, then Discard.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(CvGeneratorScreen), findsNothing);

      expect(store.stored, isNull,
          reason: 'discarded draft was saved again (ops: ${store.ops})');
    });
  }
}
