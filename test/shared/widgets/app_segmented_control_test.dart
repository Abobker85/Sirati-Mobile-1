import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    ),
  );
}

/// Value-mode control whose selection is owned by the test.
class _ValueHarness extends StatefulWidget {
  const _ValueHarness(
      {super.key, required this.labels, this.initial = 0, this.log});

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

void _expectThumbUnder(
    WidgetTester tester, List<String> labels, int index, String reason) {
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

/// A non-text contrast check on the pumped control (WCAG 1.4.11): the
/// control's shape reads if the track stands 3:1 off the page, or the thumb
/// (its fill or its edge) stands 3:1 off the track.
void _expectControlShapeVisible(WidgetTester tester, String reason) {
  final trackElement = find.byKey(SegmentedTrack.trackKey).evaluate().single;
  final trackBox =
      (trackElement.widget as DecoratedBox).decoration as BoxDecoration;
  final pages = paintedBackgroundsOf(trackElement);
  final thumbElement = find.byKey(SegmentedTrack.thumbKey).evaluate().single;
  final thumbBox =
      (thumbElement.widget as DecoratedBox).decoration as BoxDecoration;
  final edge = thumbBox.border is Border &&
          (thumbBox.border! as Border).top.style == BorderStyle.solid &&
          (thumbBox.border! as Border).top.width > 0
      ? (thumbBox.border! as Border).top.color
      : null;
  for (final page in pages) {
    final track = Color.alphaBlend(trackBox.color!, page);
    final thumb = Color.alphaBlend(thumbBox.color!, track);
    final trackOnPage = AppContrast.ratio(track, page);
    final thumbOnTrack = [
      AppContrast.ratio(thumb, track),
      if (edge != null) AppContrast.ratio(Color.alphaBlend(edge, track), track),
    ].reduce((a, b) => a > b ? a : b);
    expect(
      trackOnPage >= 3 || thumbOnTrack >= 3,
      isTrue,
      reason: 'track/page ${trackOnPage.toStringAsFixed(2)}, '
          'thumb/track ${thumbOnTrack.toStringAsFixed(2)} ($reason)',
    );
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

    testWidgets('no selection hides the thumb and every segment reports',
        (tester) async {
      final random = Random(23);
      final handle = tester.ensureSemantics();
      for (final direction in directions) {
        final labels = _labels(random, 3);
        final log = <int>[];
        await tester.pumpWidget(_host(
          direction: direction,
          child: AppSegmentedControl<int>(
            value: null,
            onChanged: log.add,
            segments: [
              for (var i = 0; i < 3; i++)
                AppSegment(value: i, label: labels[i]),
            ],
          ),
        ));
        expect(find.byKey(SegmentedTrack.thumbKey), findsNothing);
        for (var i = 0; i < 3; i++) {
          expect(
              tester.getSemantics(find.text(labels[i])),
              matchesSemantics(
                label: labels[i],
                isSelected: false,
                hasSelectedState: true,
                hasTapAction: true,
                hasEnabledState: true,
                isEnabled: true,
                textDirection: direction,
              ));
          await tester.tap(_segment(labels[i]));
        }
        expect(log, [0, 1, 2]);
      }
      handle.dispose();
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
              textScaler: TextScaler.noScaling,
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
      await tester
          .pumpWidget(_host(child: tabs(labels, controller: controller)));
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

    testWidgets('reduced motion jumps the thumb and the page on tap',
        (tester) async {
      for (final direction in directions) {
        final labels = _labels(Random(13), 4);
        await tester.pumpWidget(_host(
          direction: direction,
          reduceMotion: true,
          child: Builder(
            builder: (context) => DefaultTabController(
              key: UniqueKey(),
              length: 4,
              animationDuration: AppSegmentedTabBar.pageDuration(context),
              child: tabs(labels),
            ),
          ),
        ));
        final controller = DefaultTabController.of(
            tester.element(find.byType(AppSegmentedTabBar)));
        for (final index in [3, 0, 2, 1]) {
          await tester.tap(_segment(labels[index]));
          await tester.pump();
          expect(controller.index, index);
          _expectThumbUnder(tester, labels, index, 'reduced tab $direction');
          expect(find.text('page $index').hitTestable(), findsOneWidget,
              reason: 'page $index shown in one frame ($direction)');
        }
      }
    });

    testWidgets('page duration follows reduced motion', (tester) async {
      for (final reduce in [false, true]) {
        late Duration duration;
        await tester.pumpWidget(_host(
          reduceMotion: reduce,
          child: Builder(builder: (context) {
            duration = AppSegmentedTabBar.pageDuration(context);
            return const SizedBox();
          }),
        ));
        expect(duration == Duration.zero, reduce);
      }
    });

    testWidgets(
        'debug build reports a controller that would still slide pages '
        'under reduced motion', (tester) async {
      final labels = _labels(Random(19), 3);
      final controller = TabController(length: 3, vsync: const TestVSync());
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(
        reduceMotion: true,
        child: tabs(labels, controller: controller),
      ));
      await tester.tap(_segment(labels[2]));
      await tester.pump();
      expect(tester.takeException(), isA<FlutterError>());
      await tester.pumpAndSettle();
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
          // The themed selection is told by ink too, not only by the thumb.
          final palette = AppSegmentedPalette.of(
              tester.element(find.byType(LanguageToggle)));
          expect(palette.selectedInk, isNot(palette.unselectedInk));
          expectAllTextAa('$suffix language toggle');
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
            final track = tester.getRect(find.byKey(SegmentedTrack.trackKey));
            expect(track.left, greaterThanOrEqualTo(0));
            expect(track.right, lessThanOrEqualTo(320));
          }
        });
      }
    }
  });

  group('page-aware palette', () {
    for (final dark in [false, true]) {
      for (final kind in PageSurfaceKind.values) {
        for (final direction in directions) {
          final suffix =
              '${dark ? 'dark' : 'light'}, ${kind.name}, ${direction.name}';
          testWidgets('control shape and labels read on the page ($suffix)',
              (tester) async {
            final theme = dark
                ? AppTheme.darkFor(arabic: direction == TextDirection.rtl)
                : AppTheme.lightFor(arabic: direction == TextDirection.rtl);
            final c = theme.extension<SiratiColors>()!;
            Widget page(Widget child) {
              final body = Builder(
                builder: (context) => ColoredBox(
                  color: PageSurface.pageColor(
                      context.sirati, PageSurface.of(context)),
                  child: Center(child: child),
                ),
              );
              return kind == PageSurfaceKind.grouped
                  ? GroupedSurface(child: body)
                  : body;
            }

            final random = Random(kind.index * 4 + (dark ? 2 : 0));
            final candidates = <String, Widget>{
              for (final n in [2, 4])
                'control n=$n':
                    _ValueHarness(key: UniqueKey(), labels: _labels(random, n)),
              'tab bar': DefaultTabController(
                length: 3,
                child: AppSegmentedTabBar(
                  textScaler: TextScaler.noScaling,
                  tabs: [
                    for (final l in _labels(random, 3))
                      AppSegmentedTab(label: l, icon: Icons.circle),
                  ],
                ),
              ),
              'language toggle': const LanguageToggle(),
              // How the sign-in screens pass the page fill (ticket 12).
              'language toggle, page fill': Builder(
                builder: (context) => LanguageToggle(
                  backgroundColor: PageSurface.fillOf(context),
                ),
              ),
            };
            for (final entry in candidates.entries) {
              await tester.pumpWidget(_host(
                theme: theme,
                direction: direction,
                child: page(entry.value),
              ));
              await tester.pumpAndSettle();
              final label = '${entry.key}, $suffix';
              _expectControlShapeVisible(tester, label);
              _expectInksAaOnBothFills(tester, label);
              expectAllTextAa(label);
              expectAllIconsAa(label);
              // No beige: the track is this page's own control fill.
              final track = ((find
                          .byKey(SegmentedTrack.trackKey)
                          .evaluate()
                          .single
                          .widget as DecoratedBox)
                      .decoration as BoxDecoration)
                  .color;
              expect(track, PageSurface.fillColor(c, kind), reason: label);
            }
          });
        }
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
              expect(
                  node.parent!.getSemanticsData().role, SemanticsRole.tabBar);
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

    for (final code in ['ar', 'en']) {
      testWidgets('shows published remote overrides of both codes ($code)',
          (tester) async {
        // Arbitrary override strings, distinct per catalog.
        final remoteFor = {'ar': 'R-${code}1', 'en': 'R-${code}2'};
        final state = RemoteL10nState(bundles: {
          for (final e in remoteFor.entries)
            e.key: RemoteStringBundle(
              code: e.key,
              version: 1,
              strings: {'sharedLanguageToggleShort': e.value},
            ),
        });
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightFor(arabic: code == 'ar'),
          locale: Locale(code),
          supportedLocales: appSupportedLocales(state),
          localizationsDelegates: appLocalizationsDelegates(state),
          home: const Scaffold(body: Center(child: LanguageToggle())),
        ));
        await tester.pumpAndSettle();
        // The English catalog's code names Arabic, and vice versa.
        final arLabel = find.text(remoteFor['en']!);
        final enLabel = find.text(remoteFor['ar']!);
        expect(arLabel, findsOneWidget);
        expect(enLabel, findsOneWidget);
        expect(tester.getCenter(arLabel).dx,
            lessThan(tester.getCenter(enLabel).dx));
        _expectThumbUnder(tester, [remoteFor['en']!, remoteFor['ar']!],
            code == 'ar' ? 0 : 1, 'remote $code');
      });
    }

    testWidgets('a remote-only language selects neither; either switches',
        (tester) async {
      for (final fallback in ['ar', 'en']) {
        for (final target in ['ar', 'en']) {
          const code = 'xq';
          final languages = RemoteLanguageList(languages: [
            RemoteLanguage(
              code: code,
              name: code,
              nativeName: code,
              direction: TextDirection.ltr,
              fallback: fallback,
            ),
          ]);
          AppLocale.resetForTest(language: code, languages: languages);
          final state = RemoteL10nState(languages: languages);
          await tester.pumpWidget(ValueListenableBuilder<String>(
            key: UniqueKey(),
            valueListenable: AppLocale.languageCode,
            builder: (context, lang, _) => MaterialApp(
              theme: AppTheme.lightFor(arabic: lang == 'ar'),
              locale: localeForLanguageCode(lang),
              supportedLocales: appSupportedLocales(state),
              localizationsDelegates: appLocalizationsDelegates(state),
              home: const Scaffold(body: Center(child: LanguageToggle())),
            ),
          ));
          await tester.pumpAndSettle();
          expect(AppLocale.languageCode.value, code);
          expect(find.byKey(SegmentedTrack.thumbKey), findsNothing,
              reason: 'fallback $fallback');
          final label =
              lookupAppLocalizations(Locale(target == 'ar' ? 'en' : 'ar'))
                  .sharedLanguageToggleShort;
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(AppLocale.languageCode.value, target,
              reason: 'fallback $fallback, tap $target');
          expect(find.byKey(SegmentedTrack.thumbKey), findsOneWidget);
        }
      }
    });

    testWidgets('switches the app language both ways and announces names',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      // Each catalog names the OTHER language.
      final ar =
          lookupAppLocalizations(const Locale('en')).sharedLanguageToggleShort;
      final en =
          lookupAppLocalizations(const Locale('ar')).sharedLanguageToggleShort;
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
