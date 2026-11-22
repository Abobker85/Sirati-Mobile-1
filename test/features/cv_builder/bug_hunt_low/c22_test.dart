import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'typing in the narrow builder leaves no undisposed CurvedAnimation '
      'after the screen closes', (tester) async {
    expect(tester.view.physicalSize.width / tester.view.devicePixelRatio,
        lessThan(900));
    final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
    await repo.saveCv(CvDocument.createEmpty(id: 'cv1', title: 'My CV'));
    await tester.pumpWidget(ProviderScope(
      overrides: [cvRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CvBuilderScreen(cvId: 'cv1'))),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final live = <Object>{};
    void onEvent(ObjectEvent e) {
      if (e is ObjectCreated && e.object is CurvedAnimation) live.add(e.object);
      if (e is ObjectDisposed) live.remove(e.object);
    }

    expect(kFlutterMemoryAllocationsEnabled, isTrue);
    FlutterMemoryAllocations.instance.addListener(onEvent);
    addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(onEvent));

    for (final text in ['S', 'Sa', 'Sar', 'Sara', 'سارة']) {
      await tester.enterText(find.byType(TextField).first, text);
      await tester.pump();
    }
    final createdWhileTyping = live.length;

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(find.byType(CvBuilderScreen), findsNothing);

    expect(live, isEmpty,
        reason: '$createdWhileTyping CurvedAnimations were made while typing; '
            '${live.length} were never disposed and stay subscribed to the '
            'preview controller');
  });
}
