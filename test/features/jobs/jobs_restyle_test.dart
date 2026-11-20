import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/jobs/domain/job_news_filters.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_pressable_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';

import '../../support/contrast_probe.dart';

/// iOS 26 restyle, ticket 13: borderless grey job cards that darken and
/// spring, filled capsule filters, a grouped detail page, Latin digits.

JobNews _job({
  int id = 1,
  String language = 'en',
  String title = 'Backend Developer',
  String method = 'url',
  String? sourceType = 'gov',
  bool remote = true,
  String? salary = '15000 - 20000',
  DateTime? published,
  DateTime? validUntil,
}) =>
    JobNews.fromJson({
      'id': id,
      'language': language,
      'title': title,
      'body': 'Build APIs with Laravel. 5 years of experience.',
      'category': 'tech',
      'skills_required': ['PHP', 'Laravel'],
      'company': 'Acme',
      'location': 'Riyadh',
      'source_name': '@jobmag',
      'source_url': 'https://t.me/jobmag/123',
      'apply_method': method,
      if (method == 'url') 'apply_url': 'https://careers.acme.example/jobs/1',
      if (method == 'email') 'apply_email': 'hr@acme.example',
      if (sourceType != null) 'source_type': sourceType,
      'is_remote': remote,
      if (salary != null) 'salary_range': salary,
      'published_at': (published ?? DateTime.now().toUtc()).toIso8601String(),
      if (validUntil != null) ...{
        'valid_until': validUntil.toIso8601String(),
        'valid_until_label': 'deadline',
      },
    });

Widget _host(
  Widget child, {
  required String lang,
  required bool dark,
  bool reduce = false,
  bool page = false,
}) {
  AppLocale.languageCode.value = lang;
  final arabic = lang == 'ar';
  return MaterialApp(
    theme: dark
        ? AppTheme.darkFor(arabic: arabic)
        : AppTheme.lightFor(arabic: arabic),
    locale: Locale(lang),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: w!,
    ),
    home: page
        ? child
        : Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
  );
}

SiratiColors _colors(WidgetTester tester, Finder within) =>
    Theme.of(tester.element(within)).extension<SiratiColors>()!;

/// Every decoration painted under [root] that draws an edge or a shadow.
/// Hairline row separators of a grouped list ([separator] coloured) are not
/// edges of a box.
List<String> _edgesAndShadows(Finder root, {Color? separator}) {
  final hits = <String>[];
  bool isSeparator(BoxBorder b) =>
      b is Border &&
      b.top == BorderSide.none &&
      b.left == BorderSide.none &&
      b.right == BorderSide.none &&
      b.bottom.color == separator;
  for (final e in find
      .descendant(of: root, matching: find.byType(DecoratedBox))
      .evaluate()) {
    final d = (e.widget as DecoratedBox).decoration;
    if (d is BoxDecoration &&
        ((d.border != null && !isSeparator(d.border!)) ||
            (d.boxShadow?.isNotEmpty ?? false))) {
      hits.add('$d');
    }
    if (d is ShapeDecoration &&
        ((d.shadows?.isNotEmpty ?? false) ||
            (d.shape is OutlinedBorder &&
                (d.shape as OutlinedBorder).side != BorderSide.none))) {
      hits.add('$d');
    }
  }
  for (final e in find
      .descendant(of: root, matching: find.byType(Material))
      .evaluate()) {
    final m = e.widget as Material;
    if (m.elevation > 0) hits.add('Material elevation ${m.elevation}');
    final shape = m.shape;
    if (shape is OutlinedBorder && shape.side != BorderSide.none) {
      hits.add('Material side ${shape.side}');
    }
  }
  return hits;
}

Color _surfaceFill(WidgetTester tester, Finder card) {
  final box = tester.widget<AnimatedContainer>(find
      .descendant(of: card, matching: find.byType(AnimatedContainer))
      .first);
  return (box.decoration! as BoxDecoration).color!;
}

double _surfaceScale(WidgetTester tester, Finder card) => tester
    .widget<AnimatedScale>(
        find.descendant(of: card, matching: find.byType(AnimatedScale)).first)
    .scale;

const _arabicIndic = r'[٠-٩۰-۹]';

void _expectLatinDigitsOnly(String label) {
  final re = RegExp(_arabicIndic);
  for (final e in find.byType(Text).evaluate()) {
    final text = paragraphOf(e.findRenderObject()!).text.toPlainText();
    expect(re.hasMatch(text), isFalse, reason: '"$text" ($label)');
  }
}

void main() {
  tearDown(() => AppLocale.languageCode.value = 'ar');

  group('job cards', () {
    for (final lang in ['en', 'ar']) {
      for (final dark in [false, true]) {
        for (final reduce in [false, true]) {
          final variant = '$lang ${dark ? 'dark' : 'light'}'
              '${reduce ? ' reduced' : ''}';

          final cards = <String, Widget Function(VoidCallback)>{
            'JobNewsCard': (onTap) => JobNewsCard(
                item: _job(language: lang),
                english: lang == 'en',
                onTap: onTap),
            'JobNewsCard compact': (onTap) => JobNewsCard(
                item: _job(language: lang, method: 'email'),
                english: lang == 'en',
                compact: true,
                onTap: onTap),
            'FeaturedJobCard': (onTap) => FeaturedJobCard(
                item: _job(language: lang),
                english: lang == 'en',
                onTap: onTap),
          };

          for (final MapEntry(key: name, value: build) in cards.entries) {
            testWidgets(
                '$name: borderless grey fill darkens and springs, inks AA '
                'resting and held ($variant)', (tester) async {
              var taps = 0;
              await tester.pumpWidget(_host(build(() => taps++),
                  lang: lang, dark: dark, reduce: reduce));
              await tester.pumpAndSettle();
              final card = find.byType(JobPressSurface);
              final c = _colors(tester, card);

              expect(_edgesAndShadows(find.byType(JobPressSurface)), isEmpty);
              expect(_surfaceFill(tester, card), c.cardFill);
              expect(_surfaceScale(tester, card), 1);
              expectAllTextAa('$name resting $variant');
              expectAllIconsAa('$name resting $variant');

              // Hold the details area (the title is always in it).
              final title = find.descendant(
                  of: card,
                  matching: find.byWidgetPredicate((w) =>
                      w is RichText &&
                      w.text.toPlainText().contains('Backend Developer')));
              final gesture =
                  await tester.startGesture(tester.getCenter(title.first));
              await tester.pump(const Duration(milliseconds: 200));
              await tester.pump(const Duration(milliseconds: 200));
              expect(_surfaceFill(tester, card), c.pressed(c.cardFill));
              expect(_surfaceScale(tester, card),
                  reduce ? 1 : JobPressSurface.pressedScale);
              expectAllTextAa('$name held $variant');
              expectAllIconsAa('$name held $variant');

              await gesture.up();
              await tester.pumpAndSettle();
              expect(taps, 1);
              expect(_surfaceFill(tester, card), c.cardFill);
              expect(_surfaceScale(tester, card), 1);
            });
          }

          testWidgets(
              'FeaturedJobCard: Apply is a teal capsule beside the card '
              'target, AA resting and held ($variant)', (tester) async {
            var taps = 0;
            await tester.pumpWidget(_host(
                FeaturedJobCard(
                    item: _job(language: lang),
                    english: lang == 'en',
                    onTap: () => taps++),
                lang: lang,
                dark: dark,
                reduce: reduce));
            await tester.pumpAndSettle();
            final c = _colors(tester, find.byType(FeaturedJobCard));
            final apply = find.byType(FilledButton);
            final style = tester.widget<FilledButton>(apply).style!;
            expect(style.shape!.resolve({}), isA<StadiumBorder>());
            expect(style.backgroundColor!.resolve({}), c.brandSurface);
            expect(tester.getSize(apply).height, greaterThanOrEqualTo(48));

            // The Apply button is not inside the card's details target.
            expect(find.ancestor(of: apply, matching: find.byType(InkWell)),
                findsNothing);

            final gesture = await tester.startGesture(tester.getCenter(apply));
            await tester.pump(const Duration(milliseconds: 300));
            final card = find.byType(JobPressSurface);
            // Holding Apply leaves the card at rest.
            expect(_surfaceFill(tester, card), c.cardFill);
            expectAllTextAa('apply held $variant');
            await gesture.cancel();
            await tester.pumpAndSettle();
            expect(taps, 0);
          });
        }
      }
    }
  });

  group('filter chips', () {
    for (final lang in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final variant = '$lang ${dark ? 'dark' : 'light'}';
        for (final preset in JobNewsFilters.presets) {
          testWidgets(
              'filled capsules, one selected with checkmark, AA resting and '
              'held: preset $preset ($variant)', (tester) async {
            var selected = preset;
            var region = JobNewsFilters.all;
            await tester.pumpWidget(_host(
                StatefulBuilder(
                  builder: (context, setState) => Column(children: [
                    PresetChips(
                        english: lang == 'en',
                        selectedPreset: selected,
                        onSelected: (v) => setState(() => selected = v)),
                    RegionChips(
                        selectedRegion: region,
                        onSelected: (v) => setState(() => region = v)),
                  ]),
                ),
                lang: lang,
                dark: dark));
            await tester.pumpAndSettle();
            final root = find
                .byWidgetPredicate((w) => w is PresetChips || w is RegionChips);
            final c = _colors(tester, root.first);

            expect(_edgesAndShadows(root.first), isEmpty);
            expect(_edgesAndShadows(root.last), isEmpty);
            final pills = find.descendant(
                of: root,
                matching: find.byWidgetPredicate(
                    (w) => w is Material && w.shape is StadiumBorder));
            expect(pills.evaluate().length,
                JobNewsFilters.presets.length + JobNewsFilters.regions.length);
            var selectedCount = 0;
            for (final e in pills.evaluate()) {
              final fill = (e.widget as Material).color;
              expect(fill, anyOf(c.cardFill, c.primaryLight));
              if (fill == c.primaryLight) selectedCount++;
            }
            // One preset and one region.
            expect(selectedCount, 2);
            expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
            expectAllTextAa('chips $variant');
            expectAllIconsAa('chips $variant');

            // Hold every pill in turn: the fill darkens, inks stay AA.
            for (final e in pills.evaluate().toList()) {
              final pill = find.byElementPredicate((x) => x == e);
              await tester.ensureVisible(pill);
              await tester.pumpAndSettle();
              final gesture = await tester.startGesture(tester.getCenter(pill));
              await tester.pump(const Duration(milliseconds: 300));
              expectAllTextAa('chip held $variant');
              expectAllIconsAa('chip held $variant');
              await gesture.cancel();
              await tester.pumpAndSettle();
            }
          });
        }
      }
    }
  });

  group('detail page', () {
    for (final lang in ['en', 'ar']) {
      for (final dark in [false, true]) {
        for (final method in ['url', 'email', 'none']) {
          final variant = '$lang ${dark ? 'dark' : 'light'} $method';
          testWidgets('grouped sections, capsule actions, AA ($variant)',
              (tester) async {
            tester.view.physicalSize = const Size(1080, 4000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(_host(
                JobNewsDetailScreen(
                    item: _job(
                        language: lang,
                        method: method,
                        validUntil: DateTime.utc(2027, 3, 14))),
                lang: lang,
                dark: dark,
                page: true));
            await tester.pumpAndSettle();
            final screen = find.byType(JobNewsDetailScreen);
            final c = _colors(tester, screen);
            final l = AppLocalizations.of(tester.element(screen));

            // A grouped page.
            final scaffold =
                find.descendant(of: screen, matching: find.byType(Scaffold));
            expect(Theme.of(tester.element(scaffold)).scaffoldBackgroundColor,
                c.groupedBackground);
            expect(PageSurface.of(tester.element(find.byType(ListView))),
                PageSurfaceKind.grouped);

            // Facts, how to apply, skills, description and source are
            // sections; the body has no bordered or shadowed box.
            final sections = find.byType(AppListSection);
            expect(sections, findsNWidgets(5));
            for (final header in [
              l.jobsHowToApply,
              l.jobsSkillsRequired,
              l.jobsDescriptionTitle,
            ]) {
              expect(find.descendant(of: sections, matching: find.text(header)),
                  findsOneWidget);
            }
            expect(
                _edgesAndShadows(find.byType(ListView), separator: c.separator),
                isEmpty);

            // Actions: a teal capsule, plus a grey capsule when applying is
            // possible. Same actions as before the restyle.
            final primary =
                tester.widget<FilledButton>(find.byType(FilledButton));
            expect(primary.style!.shape!.resolve({}), isA<StadiumBorder>());
            expect(primary.style!.backgroundColor!.resolve({}), c.brandSurface);
            final secondary = find.byType(OutlinedButton);
            if (method == 'none') {
              expect(secondary, findsNothing);
            } else {
              final s = tester.widget<OutlinedButton>(secondary).style!;
              expect(s.shape!.resolve({}), isA<StadiumBorder>());
              expect(s.side!.resolve({}), BorderSide.none);
              expect(s.backgroundColor!.resolve({}), c.groupedCard);
            }

            expectAllTextAa('detail $variant');
            expectAllIconsAa('detail $variant');
            _expectLatinDigitsOnly('detail $variant');

            // The primary action held: still AA.
            final gesture = await tester
                .startGesture(tester.getCenter(find.byType(FilledButton)));
            await tester.pump(const Duration(milliseconds: 300));
            expectAllTextAa('detail primary held $variant');
            await gesture.cancel();
          });
        }
      }
    }
  });

  group('Latin digits', () {
    // Dates across the year, relative and absolute, in both languages.
    final now = DateTime.now().toUtc();
    final dates = [
      now.subtract(const Duration(minutes: 7)),
      now.subtract(const Duration(hours: 13)),
      now.subtract(const Duration(days: 3)),
      now.subtract(const Duration(days: 40)),
      DateTime.utc(2025, 12, 31, 23, 59),
      DateTime.utc(2024, 2, 29),
    ];
    for (final lang in ['ar', 'en']) {
      for (final (i, at) in dates.indexed) {
        testWidgets(
            'cards and detail never render Arabic-Indic digits '
            '($lang, date $i)', (tester) async {
          tester.view.physicalSize = const Size(1080, 4000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final job = _job(
            id: 100 + i,
            language: lang,
            salary: '${8000 + i * 1250} - ${12000 + i * 990}',
            published: at,
            validUntil: at.add(Duration(days: 30 + i * 17)),
          );
          for (final widget in [
            JobNewsCard(item: job, english: lang == 'en', onTap: () {}),
            FeaturedJobCard(item: job, english: lang == 'en', onTap: () {}),
          ]) {
            await tester.pumpWidget(_host(widget, lang: lang, dark: false));
            await tester.pumpAndSettle();
            _expectLatinDigitsOnly('$widget $lang $i');
          }
          await tester.pumpWidget(_host(JobNewsDetailScreen(item: job),
              lang: lang, dark: false, page: true));
          await tester.pumpAndSettle();
          _expectLatinDigitsOnly('detail $lang $i');
          // Every digit the server sent is still shown.
          expect(find.textContaining(job.salaryRange!), findsOneWidget);
        });
      }
    }
  });
}
