import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/controllers/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder/save_status_badge.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder/section_order_tab.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_footer.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_header.dart';
import 'package:sirati/features/cv_builder/presentation/section_editor_framework.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

class _MemRepo extends LocalCvRepository {
  _MemRepo() : super(engine: MemoryCvStorageEngine());
}

Widget _wrap(
  Widget child, {
  bool english = true,
  bool reduce = false,
}) {
  return MaterialApp(
    theme: AppTheme.lightFor(arabic: !english),
    locale: Locale(english ? 'en' : 'ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: Directionality(
        textDirection: english ? TextDirection.ltr : TextDirection.rtl,
        child: inner!,
      ),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('CV Suite Phase 3 motion', () {
    for (final english in [true, false]) {
      testWidgets(
          'MotionStepSwitcher slides bidirectionally in ${english ? 'LTR' : 'RTL'}',
          (tester) async {
        var step = 0;
        var direction = 1;
        late StateSetter setLocalState;

        await tester.pumpWidget(_wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setLocalState = setState;
              return Column(
                children: [
                  WizardHeader(
                    step: step,
                    english: english,
                    onStepTap: (target) => setState(() {
                      direction = target < step ? -1 : 1;
                      step = target;
                    }),
                  ),
                  Expanded(
                    child: MotionStepSwitcher(
                      stepKey: step,
                      direction: direction,
                      child: Center(
                        key: ValueKey('step-body-$step'),
                        child: Text('Step $step'),
                      ),
                    ),
                  ),
                  WizardFooter(
                    english: english,
                    step: step,
                    stepCount: 4,
                    isEditMode: false,
                    isLoading: false,
                    onBack: () => setState(() {
                      direction = -1;
                      step--;
                    }),
                    onPrimary: () => setState(() {
                      direction = 1;
                      if (step < 3) step++;
                    }),
                  ),
                ],
              );
            },
          ),
          english: english,
        ));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
            tester.element(find.byType(WizardHeader)));

        // Step 0 hides Back button.
        expect(find.text(l10n.back), findsNothing);
        expect(find.text('Step 0'), findsOneWidget);

        // Advance forward to step 1: incoming enters from reading end.
        setLocalState(() {
          direction = 1;
          step = 1;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));

        final incomingX = tester.getTopLeft(find.text('Step 1')).dx;
        final outgoingX = tester.getTopLeft(find.text('Step 0')).dx;
        if (english) {
          expect(incomingX, greaterThan(outgoingX));
        } else {
          expect(incomingX, lessThan(outgoingX));
        }

        await tester.pumpAndSettle();
        expect(find.text(l10n.back), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Navigate back to step 0: incoming enters from reading start.
        setLocalState(() {
          direction = -1;
          step = 0;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));

        final backInX = tester.getTopLeft(find.text('Step 0')).dx;
        final backOutX = tester.getTopLeft(find.text('Step 1')).dx;
        if (english) {
          expect(backInX, lessThan(backOutX));
        } else {
          expect(backInX, greaterThan(backOutX));
        }
        await tester.pumpAndSettle();
        expect(find.text(l10n.back), findsNothing);
      });
    }

    testWidgets('SaveStatusBadge morphs states and skips tickers under reduce',
        (tester) async {
      var isSaving = true;
      var isDirty = false;
      late StateSetter setLocalState;

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) {
            setLocalState = setState;
            return Center(
              child: SaveStatusBadge(isSaving: isSaving, isDirty: isDirty),
            );
          },
        ),
      ));
      await tester.pump();

      final l10n = AppLocalizations.of(
          tester.element(find.byType(SaveStatusBadge)));
      expect(find.text(l10n.autosaving), findsOneWidget);

      setLocalState(() {
        isSaving = false;
        isDirty = false;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text(l10n.saved), findsOneWidget);
      await tester.pumpAndSettle();

      setLocalState(() => isDirty = true);
      await tester.pumpAndSettle();
      expect(find.text(l10n.unsavedEdits), findsOneWidget);

      // Reduced motion: immediate swap with zero running animations.
      await tester.pumpWidget(_wrap(
        const SaveStatusBadge(isSaving: false, isDirty: false),
        reduce: true,
      ));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text(l10n.saved), findsOneWidget);
    });

    testWidgets(
        'SectionCardWrapper expands/collapses smoothly and snaps under reduce',
        (tester) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(_wrap(
          const SingleChildScrollView(
            child: SectionCardWrapper(
              title: 'Experience',
              icon: Icons.work_outline,
              child: Text('Body content'),
            ),
          ),
          reduce: reduce,
        ));
        await tester.pumpAndSettle();
        expect(find.text('Body content'), findsOneWidget);

        await tester.tap(find.text('Experience'));
        if (reduce) {
          await tester.pump();
          expect(tester.hasRunningAnimations, isFalse);
        } else {
          await tester.pumpAndSettle();
        }
        expect(find.text('Body content'), findsNothing);

        await tester.tap(find.text('Experience'));
        if (reduce) {
          await tester.pump();
          expect(tester.hasRunningAnimations, isFalse);
        } else {
          await tester.pumpAndSettle();
        }
        expect(find.text('Body content'), findsOneWidget);
      }
    });

    testWidgets('SectionOrderTab wires tactile proxyDecorator and reorders',
        (tester) async {
      final controller = CvBuilderController(
        initialDocument: CvDocument.createEmpty(),
        repository: _MemRepo(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(
        SingleChildScrollView(
          child: SectionOrderTab(controller: controller),
        ),
      ));
      await tester.pumpAndSettle();

      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      expect(list.proxyDecorator, isNotNull);

      final before = List<String>.from(
        controller.document.sectionOrder ?? CvDocument.defaultSectionOrder,
      );
      await tester.tap(find.byIcon(Icons.arrow_downward).first);
      await tester.pumpAndSettle();
      final after = controller.document.sectionOrder!;
      expect(after[0], before[1]);
      expect(after[1], before[0]);
    });
  });
}
