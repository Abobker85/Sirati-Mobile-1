import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/theme/auth_hero_palette.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';

import '../../support/contrast_probe.dart';

/// Labels mixing scripts and lengths, so no assertion is tuned to one string.
const _labelPool = [
  'النتيجة',
  'Score',
  'التوصيات والتحسينات المقترحة',
  'Recommendations',
  'السجل',
  'CVs السير الذاتية',
  'Skills المهارات',
  'ترتيب الأقسام',
];

List<String> _labels(Random random, int n) {
  final pool = [..._labelPool]..shuffle(random);
  return pool.take(n).toList();
}

Widget _host({
  required Widget child,
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  double textScale = 1,
  Decoration? background,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightFor(arabic: direction == TextDirection.rtl),
    locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: Directionality(textDirection: direction, child: body!),
    ),
    home: Scaffold(
      body: Center(
        child: DecoratedBox(
          decoration: background ?? const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Value-mode control whose selection is owned by the test.
class _ValueHarness extends StatefulWidget {
  const _ValueHarness({super.key, required this.labels, this.initial = 0, this.log});

  final List<String> labels;
  final int initial;
  final List<int>? log;

  @override
  State<_ValueHarness> createState() => _ValueHarnessState();
}

class _ValueHarnessState extends State<_ValueHarness> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<int>(
      value: value,
      onChanged: (v) {
        widget.log?.add(v);
        setState(() => value = v);
      },
      segments: [
        for (var i = 0; i < widget.labels.length; i++)
          AppSegment(value: i, label: widget.labels[i]),
      ],
    );
  }
}

Rect _thumb(WidgetTester tester) =>
    tester.getRect(find.byKey(SegmentedTrack.thumbKey));

/// The tappable segment that holds [label].
Finder _segment(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
    .first;

void _expectThumbUnder(WidgetTester tester, List<String> labels, int index,
    String reason) {
  final thumb = _thumb(tester);
  for (var i = 0; i < labels.length; i++) {
    final segment = tester.getRect(_segment(labels[i]));
    expect(thumb.contains(segment.center), i == index,
        reason: '$reason: segment $i vs thumb at $index');
  }
}

void _expectReadingOrder(
    WidgetTester tester, List<String> labels, TextDirection direction) {
  for (var i = 1; i < labels.length; i++) {
    final previous = tester.getCenter(_segment(labels[i - 1])).dx;
    final current = tester.getCenter(_segment(labels[i])).dx;
    expect(
      direction == TextDirection.ltr ? current > previous : current < previous,
      isTrue,
      reason: 'segment $i follows $direction reading order',
    );
  }
}

/// Every label ink reaches AA on both painted fills (track and thumb), so a
/// label stays legible wherever the sliding thumb is.
void _expectInksAaOnBothFills(WidgetTester tester, String reason) {
  final thumbElement = find.byKey(SegmentedTrack.thumbKey).evaluate().single;
  final thumbFill =
      ((thumbElement.widget as DecoratedBox).decoration as BoxDecoration)
          .color!;
  // What lies under the thumb: the track composited over the page.
  final underThumb = paintedBackgroundsOf(thumbElement);
  final fills = <Color>[
    ...underThumb,
    for (final background in underThumb)
      Color.alphaBlend(thumbFill, background),
  ];
  final track = find.byKey(SegmentedTrack.trackKey);
  final texts = find.descendant(of: track, matching: find.byType(Text));
  expect(texts, findsWidgets);
  for (final element in texts.evaluate()) {
    final ink = paragraphOf(element.findRenderObject()!).text.style!.color!;
    for (final fill in fills) {
      expect(
        AppContrast.ratio(Color.alphaBlend(ink, fill), fill),
        greaterThanOrEqualTo(4.5),
        reason: '"${(element.widget as Text).data}" $ink on $fill ($reason)',
      );
    }
  }
}

void main() {
  const directions = [TextDirection.ltr, TextDirection.rtl];

  group('value mode', () {
    testWidgets(
        'thumb sits under the selected segment and segments follow reading '
        'order, for every count, index and direction', (tester) async {
      final random = Random(11);
      for (final direction in directions) {
        for (var n = 2; n <= 4; n++) {
          final labels = _labels(random, n);
          for (var index = 0; index < n; index++) {
            await tester.pumpWidget(_host(
              direction: direction,
              child: _ValueHarness(
                key: UniqueKey(),
                labels: labels,
                initial: index,
              ),
            ));
            await tester.pumpAndSettle();
            _expectReadingOrder(tester, labels, direction);
            _expectThumbUnder(tester, labels, index, '$direction n=$n');
          }
        }
      }
    });

    testWidgets('tap reports the value and the thumb slides to it',
        (tester) async {
      final random = Random(7);
      for (final direction in directions) {
        final labels = _labels(random, 3);
        final log = <int>[];
        await tester.pumpWidget(_host(
          direction: direction,
          child: _ValueHarness(key: UniqueKey(), labels: labels, log: log),
        ));
        await tester.pumpAndSettle();
        final start = _thumb(tester).center;

        await tester.tap(_segment(labels[2]));
        await tester.pump();
        expect(log, [2]);
        await tester.pump(MotionDurations.navIndicator ~/ 3);
        final middle = _thumb(tester).center;
        final target = tester.getCenter(_segment(labels[2]));
        expect(tester.hasRunningAnimations, isTrue, reason: '$direction');
        // Mid-slide: strictly between where it was and where it goes.
        expect((middle.dx - start.dx).sign, (target.dx - start.dx).sign);
        expect((target.dx - middle.dx).abs(),
            lessThan((target.dx - start.dx).abs()));
        expect((middle.dx - start.dx).abs(), greaterThan(0));

        await tester.pumpAndSettle();
        _expectThumbUnder(tester, labels, 2, '$direction after slide');

        // Tapping the selected segment reports nothing.
        await tester.tap(_segment(labels[2]));
        await tester.pump();
        expect(log, [2]);
      }
    });

    testWidgets('reduced motion jumps the thumb in one frame', (tester) async {
      final random = Random(3);
      for (final direction in directions) {
        final labels = _labels(random, 4);
        await tester.pumpWidget(_host(
          direction: direction,
          reduceMotion: true,
          child: _ValueHarness(key: UniqueKey(), labels: labels),
        ));
        await tester.pumpAndSettle();
        for (final index in [3, 1, 2, 0]) {
          await tester.tap(_segment(labels[index]));
          await tester.pump();
          expect(tester.hasRunningAnimations, isFalse);
          _expectThumbUnder(tester, labels, index, '$direction reduced');
        }
      }
    });

    testWidgets('disabled control ignores taps', (tester) async {
      await tester.pumpWidget(_host(
        child: const AppSegmentedControl<int>(
          value: 0,
          onChanged: null,
          segments: [
            AppSegment(value: 0, label: 'Score'),
            AppSegment(value: 1, label: 'النتيجة'),
          ],
        ),
      ));
      await tester.tap(_segment('النتيجة'));
      await tester.pumpAndSettle();
      _expectThumbUnder(tester, ['Score', 'النتيجة'], 0, 'disabled');
    });
  });

  group('tab mode', () {
    Widget tabs(List<String> labels, {TabController? controller}) => Column(
          children: [
            AppSegmentedTabBar(
              controller: controller,
              tabs: [
                for (final l in labels)
                  AppSegmentedTab(label: l, icon: Icons.circle),
              ],
            ),
            SizedBox(
              height: 200,
              width: 300,
              child: TabBarView(
                controller: controller,
                children: [
                  for (var i = 0; i < labels.length; i++) Text('page $i'),
                ],
              ),
            ),
          ],
        );

    testWidgets('tap and swipe stay in sync with DefaultTabController',
        (tester) async {
      final random = Random(5);
      for (final direction in directions) {
        final labels = _labels(random, 3);
        await tester.pumpWidget(_host(
          direction: direction,
          child: DefaultTabController(
            key: UniqueKey(),
            length: labels.length,
            child: tabs(labels),
          ),
        ));
        await tester.pumpAndSettle();
        final controller = DefaultTabController.of(
            tester.element(find.byType(AppSegmentedTabBar)));

        await tester.tap(_segment(labels[2]));
        await tester.pumpAndSettle();
        expect(controller.index, 2, reason: '$direction tap');
        expect(find.text('page 2'), findsOneWidget);
        _expectThumbUnder(tester, labels, 2, '$direction tap');

        // Swipe the pages back one step: toward reading-order start.
        final back = direction == TextDirection.ltr ? 1 : -1;
        await tester.fling(find.text('page 2'), Offset(300.0 * back, 0), 1000);
        await tester.pumpAndSettle();
        expect(controller.index, 1, reason: '$direction swipe');
        _expectThumbUnder(tester, labels, 1, '$direction swipe');
      }
    });

    testWidgets('thumb tracks a page drag before it settles', (tester) async {
      final labels = _labels(Random(9), 2);
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
          _host(child: tabs(labels, controller: controller)));
      final start = _thumb(tester).center.dx;
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('page 0')));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      final dragged = _thumb(tester).center.dx;
      expect(controller.animation!.value, inExclusiveRange(0, 1));
      expect(dragged, greaterThan(start));
      expect(dragged, lessThan(tester.getCenter(_segment(labels[1])).dx));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion jumps the thumb on tap', (tester) async {
      final labels = _labels(Random(13), 4);
      final controller = TabController(length: 4, vsync: const TestVSync());
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(
        reduceMotion: true,
        child: tabs(labels, controller: controller),
      ));
      for (final index in [3, 0, 2]) {
        await tester.tap(_segment(labels[index]));
        await tester.pump();
        expect(controller.index, index);
        _expectThumbUnder(tester, labels, index, 'reduced tab');
        await tester.pumpAndSettle();
      }
    });

    testWidgets('preferred size reserves the scaled control height',
        (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        final scaler = TextScaler.linear(scale);
        final bar = AppSegmentedTabBar(
          textScaler: scaler,
          tabs: const [
            AppSegmentedTab(label: 'النتيجة'),
            AppSegmentedTab(label: 'Score'),
          ],
        );
        await tester.pumpWidget(_host(
          textScale: scale,
          child: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(bottom: bar),
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull, reason: 'scale $scale');
        expect(tester.getSize(find.byType(AppSegmentedTabBar)).height,
            bar.preferredSize.height);
      }
    });
  });

  group('size and contrast', () {
    for (final dark in [false, true]) {
      for (final direction in directions) {
        final suffix = '${dark ? 'dark' : 'light'}, ${direction.name}';
        ThemeData theme() => dark
            ? AppTheme.darkFor(arabic: direction == TextDirection.rtl)
            : AppTheme.lightFor(arabic: direction == TextDirection.rtl);

        testWidgets('labels are AA on track and thumb ($suffix)',
            (tester) async {
          final random = Random(dark ? 1 : 2);
          for (final n in [2, 3, 4]) {
            final labels = _labels(random, n);
            await tester.pumpWidget(_host(
              theme: theme(),
              direction: direction,
              child: _ValueHarness(key: UniqueKey(), labels: labels),
            ));
            // Mid-slide too: inks swap while the thumb passes.
            await tester.tap(_segment(labels[n - 1]));
            await tester.pump(MotionDurations.navIndicator ~/ 2);
            _expectInksAaOnBothFills(tester, '$suffix n=$n mid-slide');
            await tester.pumpAndSettle();
            _expectInksAaOnBothFills(tester, '$suffix n=$n');
            expectAllTextAa('$suffix n=$n');
          }
          await tester.pumpWidget(_host(
            theme: theme(),
            direction: direction,
            child: const LanguageToggle(),
          ));
          _expectInksAaOnBothFills(tester, '$suffix language toggle');
          expectAllTextAa('$suffix language toggle');
        });

        testWidgets('hero language toggle is AA on track and thumb ($suffix)',
            (tester) async {
          await tester.pumpWidget(_host(
            theme: theme(),
            direction: direction,
            background: const BoxDecoration(
              gradient: AuthHeroPalette.gradient,
            ),
            child: const LanguageToggle(
              backgroundColor: AuthHeroPalette.pillBackground,
              foregroundColor: AuthHeroPalette.onHero,
              side: BorderSide(color: AuthHeroPalette.pillBorder),
            ),
          ));
          _expectInksAaOnBothFills(tester, '$suffix hero');
          expectAllTextAa('$suffix hero');
        });

        testWidgets('segments stay >= 44 tall and fit at 200% ($suffix)',
            (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final scale in [1.0, 2.0]) {
            final labels = [
              'التوصيات والتحسينات المقترحة',
              'Recommendations and fixes',
              'السير الذاتية المحفوظة',
              'ترتيب الأقسام',
            ];
            await tester.pumpWidget(_host(
              theme: theme(),
              direction: direction,
              textScale: scale,
              child: _ValueHarness(key: UniqueKey(), labels: labels),
            ));
            expect(tester.takeException(), isNull, reason: '$suffix $scale');
            for (final label in labels) {
              expect(tester.getSize(_segment(label)).height,
                  greaterThanOrEqualTo(44),
                  reason: '$label at $scale');
            }
            // The whole track still fits a 320dp screen.
            expect(tester.getRect(find.byKey(SegmentedTrack.trackKey)).right,
                lessThanOrEqualTo(320));
          }
        });
      }
    }
  });

  group('semantics', () {
    testWidgets('each segment is a tab with its label and selected state',
        (tester) async {
      final handle = tester.ensureSemantics();
      final random = Random(17);
      for (final direction in directions) {
        for (final n in [2, 4]) {
          final labels = _labels(random, n);
          for (final selected in {0, n - 1}) {
            await tester.pumpWidget(_host(
              direction: direction,
              child: _ValueHarness(
                key: UniqueKey(),
                labels: labels,
                initial: selected,
              ),
            ));
            await tester.pumpAndSettle();
            for (var i = 0; i < n; i++) {
              final node = tester.getSemantics(find.text(labels[i]));
              expect(
                node,
                matchesSemantics(
                  label: labels[i],
                  isSelected: i == selected,
                  hasSelectedState: true,
                  hasTapAction: true,
                  hasEnabledState: true,
                  isEnabled: true,
                  textDirection: direction,
                ),
              );
              expect(node.getSemanticsData().role, SemanticsRole.tab);
              expect(node.parent!.getSemanticsData().role,
                  SemanticsRole.tabBar);
            }
          }
        }
      }
      handle.dispose();
    });
  });

  group('language toggle (production call site)', () {
    setUp(() {
      AppLocale.resetForTest();
      const channel =
          MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
    });
    tearDown(AppLocale.resetForTest);

    Widget app() => ValueListenableBuilder<String>(
          valueListenable: AppLocale.languageCode,
          builder: (context, code, _) => MaterialApp(
            locale: Locale(code),
            theme: AppTheme.lightFor(arabic: code == 'ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Center(child: LanguageToggle())),
          ),
        );

    testWidgets('switches the app language both ways and announces names',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final ar = LanguageToggle.shortCode('ar');
      final en = LanguageToggle.shortCode('en');
      expect(ar, isNot(en));

      for (final (tap, code) in [(en, 'en'), (ar, 'ar'), (en, 'en')]) {
        await tester.tap(find.text(tap));
        await tester.pumpAndSettle();
        expect(AppLocale.languageCode.value, code);
        final l10n = lookupAppLocalizations(Locale(code));
        final names = {
          'ar': l10n.languageArabic,
          'en': l10n.languageEnglish,
        };
        for (final (label, segment) in [(ar, 'ar'), (en, 'en')]) {
          expect(
            tester.getSemantics(find.text(label)),
            matchesSemantics(
              label: names[segment],
              isSelected: segment == code,
              hasSelectedState: true,
              hasTapAction: true,
              hasEnabledState: true,
              isEnabled: true,
            ),
          );
        }
        // Fixed physical order: Arabic stays left of English in both
        // directions, and the thumb sits under the active language.
        expect(tester.getCenter(find.text(ar)).dx,
            lessThan(tester.getCenter(find.text(en)).dx));
        _expectThumbUnder(tester, [ar, en], code == 'ar' ? 0 : 1, code);
      }
      handle.dispose();
    });
  });
}
