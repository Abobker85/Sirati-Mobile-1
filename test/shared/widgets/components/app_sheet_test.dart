import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';

const _homeBody = ValueKey('home-body');
const _sheetBody = ValueKey('sheet-body');

typedef _Open = void Function(BuildContext context);

Future<void> _pump(
  WidgetTester tester, {
  required _Open open,
  Locale locale = const Locale('ar'),
  bool dark = false,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(412, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final arabic = locale.languageCode == 'ar';
  await tester.pumpWidget(
    MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => SizedBox.expand(
            key: _homeBody,
            child: Center(
              child: TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _openGlass(BuildContext context, {bool? showDragHandle, bool? close}) {
  showGlassBottomSheet<void>(
    context: context,
    showDragHandle: showDragHandle ?? true,
    showCloseButton: close,
    builder: (_) => const SizedBox(key: _sheetBody, height: 160),
  );
}

/// The scale the screen behind the sheet is drawn at (1 when untouched).
double _backgroundScale(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(find.ancestor(
    of: find.byKey(_homeBody),
    matching: find.byKey(const ValueKey('sheet-background-scale')),
  ));
  if (transforms.isEmpty) return 1;
  // The x scale; getMaxScaleOnAxis would also count the untouched z axis.
  return transforms.single.transform.storage[0];
}

Finder get _glass => find.ancestor(
      of: find.byKey(_sheetBody),
      matching: find.byType(GlassSurface),
    );

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final dark in [false, true]) {
      final label = '${locale.languageCode} ${dark ? 'dark' : 'light'}';

      testWidgets('$label: rises in ~400ms, the screen behind shrinks to 95%',
          (tester) async {
        await _pump(tester, open: _openGlass, locale: locale, dark: dark);
        expect(_backgroundScale(tester), 1);

        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final midway = _backgroundScale(tester);
        expect(midway, lessThan(1));
        expect(midway, greaterThan(appSheetBackgroundScale));

        await tester.pump(const Duration(milliseconds: 200));
        expect(_backgroundScale(tester),
            moreOrLessEquals(appSheetBackgroundScale));
        await tester.pumpAndSettle();
        expect(_backgroundScale(tester),
            moreOrLessEquals(appSheetBackgroundScale));

        // The barrier dims the screen behind.
        final barrier = tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .where((b) => b.color != null && b.color!.a > 0);
        expect(barrier, isNotEmpty);
      });

      testWidgets('$label: large top radius, no grab bar, X at the end side',
          (tester) async {
        await _pump(tester, open: _openGlass, locale: locale, dark: dark);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final glass = tester.widget<GlassSurface>(_glass);
        expect(appSheetRadius, 38);
        expect(glass.borderRadius, AppRadius.sheetTop);
        expect(glass.borderRadius.topLeft, const Radius.circular(38));
        expect(glass.borderRadius.topRight, const Radius.circular(38));

        // Nothing but the close row sits between the sheet's top edge and
        // its content: no grab bar.
        final close = find.byKey(const ValueKey('sheet-close'));
        final glassRect = tester.getRect(_glass);
        final closeRect = tester.getRect(close);
        final bodyRect = tester.getRect(find.byKey(_sheetBody));
        expect(closeRect.top - glassRect.top, AppSpacing.md);
        expect(bodyRect.top, closeRect.bottom);

        // End side: left in Arabic, right in English.
        if (locale.languageCode == 'ar') {
          expect(closeRect.left - glassRect.left, AppSpacing.md);
        } else {
          expect(glassRect.right - closeRect.right, AppSpacing.md);
        }
        // A 44 round button inside a 48 tap target.
        expect(closeRect.width, greaterThanOrEqualTo(48));
        expect(closeRect.height, greaterThanOrEqualTo(48));
        final circle = tester.getRect(
          find.descendant(of: close, matching: find.byType(Material)).first,
        );
        expect(circle.width, SheetCloseButton.size);
        expect(circle.height, SheetCloseButton.size);
        expect(circle.center, closeRect.center);
      });

      testWidgets('$label: X has a localized label, contrast and closes',
          (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(tester, open: _openGlass, locale: locale, dark: dark);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final context = tester.element(find.byKey(_sheetBody));
        final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;
        expect(closeLabel, isNotEmpty);
        expect(find.bySemanticsLabel(closeLabel), findsOneWidget);
        expect(
          tester.getSemantics(find.byKey(const ValueKey('sheet-close'))),
          isSemantics(
            label: closeLabel,
            isButton: true,
            hasTapAction: true,
          ),
        );

        final button = tester.widget<IconButton>(
          find.byKey(const ValueKey('sheet-close')),
        );
        final style = button.style!;
        for (final states in [
          <WidgetState>{},
          {WidgetState.pressed},
          {WidgetState.hovered},
          {WidgetState.focused},
        ]) {
          final ink = style.foregroundColor!.resolve(states)!;
          final fill = style.backgroundColor!.resolve(states)!;
          final overlay = style.overlayColor?.resolve(states);
          final shown =
              overlay == null ? fill : Color.alphaBlend(overlay, fill);
          expect(AppContrast.ratio(ink, shown), greaterThanOrEqualTo(4.5),
              reason: 'X glyph over its fill in $states');
        }

        await tester.tap(find.byKey(const ValueKey('sheet-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(_sheetBody), findsNothing);
        expect(_backgroundScale(tester), 1);
        semantics.dispose();
      });

      testWidgets('$label: a swipe down closes the sheet', (tester) async {
        await _pump(tester, open: _openGlass, locale: locale, dark: dark);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Partway down, the screen behind grows back with the finger.
        final gesture =
            await tester.startGesture(tester.getCenter(find.byKey(_sheetBody)));
        await gesture.moveBy(const Offset(0, 20));
        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();
        final dragged = _backgroundScale(tester);
        expect(dragged, greaterThan(appSheetBackgroundScale));
        expect(dragged, lessThan(1));
        await gesture.moveBy(const Offset(0, 300));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byKey(_sheetBody), findsNothing);
        expect(_backgroundScale(tester), 1);
      });

      testWidgets('$label: reduced motion, no rise and no shrink',
          (tester) async {
        await _pump(
          tester,
          open: _openGlass,
          locale: locale,
          dark: dark,
          disableAnimations: true,
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        expect(find.byKey(_sheetBody), findsOneWidget);
        expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
        // Already in place on the first frame.
        final first = tester.getRect(_glass);
        await tester.pumpAndSettle();
        expect(tester.getRect(_glass), first);
        expect(_backgroundScale(tester), 1);
        expect(
            find.byKey(const ValueKey('sheet-background-scale')), findsNothing);
      });
    }
  }

  group('existing callers', () {
    testWidgets('showDragHandle: false keeps their own top, with no X',
        (tester) async {
      await _pump(
        tester,
        open: (context) => _openGlass(context, showDragHandle: false),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sheet-close')), findsNothing);
      expect(tester.getRect(find.byKey(_sheetBody)).top,
          tester.getRect(_glass).top);
      expect(_backgroundScale(tester), moreOrLessEquals(0.95));
    });

    testWidgets('showCloseButton overrides showDragHandle', (tester) async {
      await _pump(
        tester,
        open: (context) =>
            _openGlass(context, showDragHandle: false, close: true),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
    });

    testWidgets('showAppBottomSheet has the X and returns on close',
        (tester) async {
      Future<String?>? result;
      await _pump(
        tester,
        open: (context) => result = showAppBottomSheet<String>(
          context: context,
          semanticLabel: 'Options',
          child: const SizedBox(key: _sheetBody, height: 80),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(find.byKey(_sheetBody), findsNothing);
    });
  });
}
