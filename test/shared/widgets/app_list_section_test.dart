import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';

import '../../support/contrast_probe.dart';

/// Titles of every shape a section meets in the app: Arabic, English,
/// mixed-script, digits, and long enough to wrap and ellipsise.
const _titles = [
  'الملف الشخصي',
  'Edit profile',
  'Senior Flutter مطور تطبيقات 2026',
  'تغيير كلمة المرور الخاصة بحسابك في سيرتي مع ملاحظة طويلة جداً للتجربة',
  'A very long English settings row title that has to wrap onto a second line',
  'Privacy الخصوصية',
];

Widget _app(
  ThemeData theme,
  TextDirection direction,
  Widget child,
) =>
    MaterialApp(
      theme: theme,
      home: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.sirati.groupedBackground,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

Iterable<SemanticsNode> _nodes(SemanticsNode root) sync* {
  yield root;
  final children = <SemanticsNode>[];
  root.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _nodes(child);
  }
}

void main() {
  for (final (mode, arabic) in [
    ('light', false),
    ('light', true),
    ('dark', false),
    ('dark', true),
  ]) {
    final theme = mode == 'light'
        ? AppTheme.lightFor(arabic: arabic)
        : AppTheme.darkFor(arabic: arabic);
    final direction = arabic ? TextDirection.rtl : TextDirection.ltr;
    final suffix = '$mode, ${direction.name}';

    group('AppListSection ($suffix)', () {
      for (var count = 1; count <= _titles.length; count++) {
        testWidgets('$count rows draw ${count - 1} separators', (tester) async {
          await tester.pumpWidget(_app(
            theme,
            direction,
            AppListSection(
              children: [
                for (final title in _titles.take(count))
                  AppListTile(
                    leadingIcon: Icons.settings_outlined,
                    title: title,
                    onTap: () {},
                  ),
              ],
            ),
          ));
          expect(
            find.descendant(
              of: find.byType(AppListSection),
              matching: find.byType(Divider),
            ),
            findsNWidgets(count - 1),
          );
        });
      }

      testWidgets('no rows draw nothing, not an empty card', (tester) async {
        await tester.pumpWidget(_app(
          theme,
          direction,
          const AppListSection(header: 'Empty فارغ', children: []),
        ));
        expect(find.byType(Material).evaluate().length,
            lessThanOrEqualTo(2)); // the Scaffold's own materials only
        expect(find.text('Empty فارغ'), findsNothing);
      });

      testWidgets(
          'rows are one card: icon at start, chevron at end, '
          'separator inset from the start', (tester) async {
        await tester.pumpWidget(_app(
          theme,
          direction,
          AppListSection(
            header: 'Account الحساب',
            footer: 'Help text under the card نص مساعدة',
            children: [
              for (final title in _titles)
                AppListTile(
                  leadingIcon: Icons.person_outline_rounded,
                  title: title,
                  subtitle: 'Subtitle وصف 42',
                  onTap: () {},
                ),
            ],
          ),
        ));
        await tester.pumpAndSettle();

        final card = tester.getRect(find.descendant(
          of: find.byType(AppListSection),
          matching: find.byKey(AppListSection.cardKey),
        ));
        for (final title in _titles) {
          final row = find.ancestor(
            of: find.text(title),
            matching: find.byType(AppListTile),
          );
          final rowRect = tester.getRect(row);
          // Rows sit edge to edge inside the one card.
          expect(rowRect.left, moreOrLessEquals(card.left));
          expect(rowRect.right, moreOrLessEquals(card.right));

          final text = tester.getRect(find.text(title));
          final icon = tester.getRect(find.descendant(
            of: row,
            matching: find.byIcon(Icons.person_outline_rounded),
          ));
          final chevron = tester.getRect(find.descendant(
            of: row,
            matching: find.byType(DirectionalIcon),
          ));
          if (direction == TextDirection.rtl) {
            expect(icon.left, greaterThan(text.right - 1));
            expect(chevron.right, lessThan(text.left + 1));
          } else {
            expect(icon.right, lessThan(text.left + 1));
            expect(chevron.left, greaterThan(text.right - 1));
          }
          expect(rowRect.height, greaterThanOrEqualTo(AppTouchTarget.min));
        }

        // The chevron points to the end side: mirrored once in RTL.
        // Icon flips glyphs that match text direction itself; DirectionalIcon
        // adds a Transform only for the rest.
        final chevron = find.byType(DirectionalIcon).first;
        final glyph = tester.widget<Icon>(
            find.descendant(of: chevron, matching: find.byType(Icon)));
        final flipped = find
            .descendant(of: chevron, matching: find.byType(Transform))
            .evaluate()
            .isNotEmpty;
        if (direction == TextDirection.rtl) {
          expect(glyph.icon!.matchTextDirection || flipped, isTrue);
        } else {
          expect(flipped, isFalse);
        }

        for (final divider in find
            .descendant(
              of: find.byType(AppListSection),
              matching: find.byType(Divider),
            )
            .evaluate()) {
          final rect = tester.getRect(find.byWidget(divider.widget));
          final line = (divider.widget as Divider);
          expect(line.indent, AppListSection.iconSeparatorIndent);
          // Divider indents from the start edge, so in RTL the gap is on
          // the right and the line meets the card's left edge.
          expect(rect.width, moreOrLessEquals(card.width));
          final painted = tester.getRect(find.descendant(
            of: find.byWidget(divider.widget),
            matching: find.byType(DecoratedBox),
          ));
          if (direction == TextDirection.rtl) {
            expect(painted.left, moreOrLessEquals(card.left));
            expect(
                painted.right,
                moreOrLessEquals(
                    card.right - AppListSection.iconSeparatorIndent));
          } else {
            expect(
                painted.left,
                moreOrLessEquals(
                    card.left + AppListSection.iconSeparatorIndent));
            expect(painted.right, moreOrLessEquals(card.right));
          }
        }

        // Header above the card, footer below it.
        expect(tester.getRect(find.text('Account الحساب')).bottom,
            lessThanOrEqualTo(card.top));
        expect(
            tester.getRect(find.text('Help text under the card نص مساعدة')).top,
            greaterThanOrEqualTo(card.bottom));

        expectAllTextAa('section $suffix');
        expectAllIconsAa('section $suffix');
      });

      testWidgets(
          'each tappable row is one button node; a static row is not a '
          'button', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final taps = <String>[];
          await tester.pumpWidget(_app(
            theme,
            direction,
            AppListSection(
              header: 'Header عنوان',
              children: [
                for (final title in _titles)
                  AppListTile(
                    leadingIcon: Icons.lock_outline_rounded,
                    title: title,
                    onTap: () => taps.add(title),
                  ),
                const AppListTile(
                  leadingIcon: Icons.info_outline_rounded,
                  title: 'Version الإصدار',
                  subtitle: '1.0.0',
                  showChevron: false,
                ),
              ],
            ),
          ));
          await tester.pumpAndSettle();
          final owner =
              tester.binding.renderViews.single.owner!.semanticsOwner!;
          final all = _nodes(owner.rootSemanticsNode!).toList();
          for (final title in _titles) {
            final buttons = all
                .where((n) =>
                    n.flagsCollection.isButton && n.label.contains(title))
                .toList();
            expect(buttons, hasLength(1), reason: title);
            expect(
                buttons.single
                    .getSemanticsData()
                    .hasAction(SemanticsAction.tap),
                isTrue);
            owner.performAction(buttons.single.id, SemanticsAction.tap);
          }
          expect(taps, _titles);
          final static =
              all.where((n) => n.label.contains('Version الإصدار')).toList();
          expect(static, hasLength(1));
          expect(static.single.flagsCollection.isButton, isFalse);
          expect(
            all.where(
                (n) => n.flagsCollection.isButton && n.label.trim().isEmpty),
            isEmpty,
          );
          final header = all.where((n) => n.label == 'Header عنوان').toList();
          expect(header, hasLength(1));
          expect(header.single.flagsCollection.isHeader, isTrue);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('a pressed row fills with the tested pressed colour',
          (tester) async {
        await tester.pumpWidget(_app(
          theme,
          direction,
          AppListSection(children: [
            AppListTile(title: _titles.first, onTap: () {}),
          ]),
        ));
        final c = theme.extension<SiratiColors>()!;
        final ink = tester.widget<InkWell>(find.descendant(
          of: find.byType(AppListTile),
          matching: find.byType(InkWell),
        ));
        expect(
          ink.overlayColor!.resolve({WidgetState.pressed}),
          c.pressed(c.groupedCard),
        );
      });
    });

    test('every row ink holds AA on the pressed card ($mode)', () {
      final c = theme.extension<SiratiColors>()!;
      final pressed = c.pressed(c.groupedCard);
      for (final (name, ink) in [
        ('textPrimary', c.textPrimary),
        ('textSecondary', c.textSecondary),
        ('textHint', c.textHint),
        ('primaryInk', c.primaryInk),
        // Sign out / delete account titles are text, so 4.5, not 3: they use
        // onErrorContainer (error itself is 4.08:1 on the pressed light card).
        ('onErrorContainer', c.onErrorContainer),
      ]) {
        expect(AppContrast.ratio(ink, pressed), greaterThanOrEqualTo(4.5),
            reason: '$name on pressed groupedCard ($mode)');
        expect(AppContrast.ratio(ink, c.groupedCard), greaterThanOrEqualTo(4.5),
            reason: '$name on groupedCard ($mode)');
      }
      expect(AppContrast.ratio(c.textSecondary, c.groupedBackground),
          greaterThanOrEqualTo(4.5),
          reason: 'section header / footer on the grey page ($mode)');
    });
  }
}
