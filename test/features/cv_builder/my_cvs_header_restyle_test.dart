import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';

import '../../support/app_screens.dart' show loadAppFonts;
import '../../support/contrast_probe.dart';

// iOS 26 restyle (ticket 24): the My CVs header is a large title on the
// plain page with no gradient band, and the slim bar that takes over on
// scroll matches it.

class _Content extends MobileContentService {
  _Content(this.items);
  final List<Map<String, dynamic>> items;

  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {'title': english ? 'My CVs' : 'سيرتي', 'items': items};
}

List<Map<String, dynamic>> _cvs(int count) => [
      for (var i = 1; i <= count; i++)
        {
          'id': i,
          'title': i.isEven ? 'مطور Backend Developer CV $i' : 'CV $i',
          'score_total': i.isEven ? null : (i * 13) % 101,
          'can_download': true,
        },
    ];

/// Every gradient painted by a box decoration under [root].
List<Gradient> _paintedGradients(RenderObject root) {
  final found = <Gradient>[];
  void visit(RenderObject node) {
    if (node is RenderDecoratedBox) {
      final gradient = switch (node.decoration) {
        BoxDecoration(:final gradient?) => gradient,
        ShapeDecoration(:final gradient?) => gradient,
        _ => null,
      };
      if (gradient != null) found.add(gradient);
    }
    node.visitChildren(visit);
  }

  visit(root);
  return found;
}

void main() {
  setUpAll(loadAppFonts);

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SessionCache.instance.unreadCount = 0);

  final list = find.byType(ListView);
  final large = find.byType(MyCvsHeader);
  final slim = find.byType(MyCvsSlimHeader);

  Future<void> pump(
    WidgetTester tester, {
    required String language,
    bool dark = false,
    int cvs = 12,
    int unread = 0,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    AppLocale.languageCode.value = language;
    SessionCache.instance.unreadCount = unread;
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final arabic = language == 'ar';
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mobileContentServiceProvider.overrideWithValue(_Content(_cvs(cvs))),
      ],
      child: MaterialApp(
        theme: dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic),
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: MyCvsScreen()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToSlim(WidgetTester tester) async {
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(slim, findsOneWidget);
  }

  Color pageOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(MyCvsScreen)))
          .scaffoldBackgroundColor;

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      final variant = '$language/${dark ? 'dark' : 'light'}';

      testWidgets('$variant: no gradient at rest or scrolled', (tester) async {
        await pump(tester, language: language, dark: dark, unread: 3);
        final screen = tester.renderObject(find.byType(MyCvsScreen));
        expect(find.byType(BreathingBand), findsNothing);
        expect(_paintedGradients(screen), isEmpty);

        await scrollToSlim(tester);
        expect(find.byType(BreathingBand), findsNothing);
        expect(_paintedGradients(screen), isEmpty);
      });

      testWidgets('$variant: the large title sits on the plain page',
          (tester) async {
        await pump(tester, language: language, dark: dark);
        final title =
            find.descendant(of: large, matching: find.byType(Text)).first;
        final element = tester.element(title);
        expect(paintedBackgroundsOf(element), [pageOf(tester)]);
        expect(
          tester.widget<Text>(title).style?.fontSize,
          AppTypography.largeTitle.size,
        );
        // Announced as the page heading.
        expect(
          tester.getSemantics(title),
          containsSemantics(isHeader: true),
        );
        // The tools card follows the title, not overlapping it.
        expect(
          tester.getRect(find.byType(MyCvsToolsCard)).top,
          greaterThanOrEqualTo(tester.getRect(large).bottom),
        );
      });

      testWidgets(
          '$variant: header text is AA and icons 3:1, at rest and '
          'in the slim bar', (tester) async {
        await pump(tester, language: language, dark: dark, unread: 5);
        expectAllTextAa('$variant rest');
        expectAllIconsAa('$variant rest');

        await scrollToSlim(tester);
        expectAllTextAa('$variant slim');
        expectAllIconsAa('$variant slim');
        // The bar is opaque, so its title is checked against the bar itself.
        final slimTitle =
            find.descendant(of: slim, matching: find.byType(Text)).first;
        expect(
          paintedBackgroundsOf(tester.element(slimTitle)),
          everyElement(isA<Color>().having((c) => c.a, 'alpha', 1)),
        );
        expect(
          tester.getSemantics(slimTitle),
          containsSemantics(isHeader: true),
        );
      });
    }
  }

  // Latin digits only, for every unread and CV count (Arabic included).
  for (final (unread, cvs) in [(1, 4), (7, 3), (12, 25)]) {
    testWidgets(
        'ar: counts render in Latin digits '
        '(unread $unread, cvs $cvs)', (tester) async {
      await pump(tester, language: 'ar', unread: unread, cvs: cvs);
      final arabicIndic = RegExp('[٠-٩۰-۹]');
      String allText() => [
            for (final e in find.byType(RichText).evaluate())
              (e.widget as RichText).text.toPlainText(),
          ].join(' ');
      expect(allText(), isNot(contains(arabicIndic)));
      // The count is still shown, in the catalog's plural form.
      final l = AppLocalizations.of(tester.element(find.byType(MyCvsScreen)));
      expect(
        find.descendant(
          of: find.byType(MyCvsListHeading),
          matching: find.text(l.cvCount(cvs)),
        ),
        findsOneWidget,
      );

      await scrollToSlim(tester);
      expect(allText(), isNot(contains(arabicIndic)));
    });
  }

  for (final language in ['ar', 'en']) {
    for (final textScale in [1.3, 2.0]) {
      testWidgets(
          '$language x$textScale at 320x568: no overflow at rest or '
          'in the slim bar', (tester) async {
        await pump(
          tester,
          language: language,
          unread: 9,
          size: const Size(320, 568),
          textScale: textScale,
        );
        expect(tester.takeException(), isNull);
        final width = tester.getSize(find.byType(MyCvsScreen)).width;
        expect(tester.getRect(large).right, lessThanOrEqualTo(width));
        expect(
          tester.getSize(find.byKey(MyCvsHeader.bellKey)),
          const Size.square(AppTouchTarget.min),
        );

        await scrollToSlim(tester);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(slim).width, width);
        expect(
          tester.getSize(find.byKey(MyCvsSlimHeader.bellKey)),
          const Size.square(AppTouchTarget.min),
        );
      });
    }
  }
}
