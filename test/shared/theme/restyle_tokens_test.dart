import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// iOS 26 restyle foundation (ticket 01): surface, radius and type tokens,
/// and the themed components that consume them.
void main() {
  const modes = {'light': SiratiColors.light, 'dark': SiratiColors.dark};

  group('surface tokens', () {
    for (final MapEntry(key: mode, value: c) in modes.entries) {
      test('lerp returns each endpoint for the new tokens ($mode)', () {
        final other = mode == 'light' ? SiratiColors.dark : SiratiColors.light;
        Color sample(SiratiColors s, int i) => [
              s.pageBackground,
              s.groupedBackground,
              s.cardFill,
              s.groupedCard,
              s.separator,
            ][i];
        for (var i = 0; i < 5; i++) {
          expect(sample(c.lerp(other, 0), i), sample(c, i));
          expect(sample(c.lerp(other, 1), i), sample(other, i));
        }
      });

      test('copyWith keeps or replaces each new token ($mode)', () {
        const probe = Color(0xFF123456);
        expect(c.copyWith().pageBackground, c.pageBackground);
        expect(c.copyWith(pageBackground: probe).pageBackground, probe);
        expect(c.copyWith(groupedBackground: probe).groupedBackground, probe);
        expect(c.copyWith(cardFill: probe).cardFill, probe);
        expect(c.copyWith(groupedCard: probe).groupedCard, probe);
        expect(c.copyWith(separator: probe).separator, probe);
      });

      test('pressed fill visibly differs from its resting fill ($mode)', () {
        for (final fill in [c.cardFill, c.groupedCard]) {
          final pressed = c.pressed(fill);
          expect(pressed, isNot(fill));
          expect(AppContrast.ratio(pressed, fill), greaterThan(1.05),
              reason: 'press feedback must be perceptible on $fill');
        }
        expect(c.cardFillPressed, c.pressed(c.cardFill));
      });

      test('pressed darkens light fills and lightens dark fills ($mode)', () {
        final pressed = c.cardFillPressed.computeLuminance();
        final rest = c.cardFill.computeLuminance();
        if (mode == 'light') {
          expect(pressed, lessThan(rest));
        } else {
          expect(pressed, greaterThan(rest));
        }
      });

      test('grouped cards stand apart from the grouped background ($mode)', () {
        expect(c.groupedCard, isNot(c.groupedBackground));
        expect(c.cardFill, isNot(c.pageBackground));
      });
    }
  });

  group('radius tokens', () {
    test('card, sheet and capsule radii', () {
      expect(AppRadius.card, 18);
      expect(AppRadius.sheet, 38);
      expect(AppRadius.capsule, greaterThanOrEqualTo(500));
      expect(AppRadius.cardAll, BorderRadius.circular(18));
      expect(
        AppRadius.sheetTop,
        const BorderRadius.vertical(top: Radius.circular(38)),
      );
    });
  });

  group('type tokens', () {
    test('large title, section, body, headline and caption sizes', () {
      expect(AppTypography.largeTitle.size, 34);
      expect(AppTypography.sectionTitle.size, 22);
      expect(AppTypography.bodyXl.size, 17);
      expect(AppTypography.headline.size, 17);
      expect(AppTypography.caption.size, 13);
    });

    test('new tokens are in the scale and use only shipped weights', () {
      for (final t in [
        AppTypography.largeTitle,
        AppTypography.sectionTitle,
        AppTypography.bodyXl,
        AppTypography.headline,
        AppTypography.caption,
      ]) {
        expect(AppTypography.all, contains(t));
      }
      for (final t in AppTypography.all) {
        expect(
          [FontWeight.w400, FontWeight.w600, FontWeight.w700],
          contains(t.weight),
          reason: 'size ${t.size} requests an unshipped weight',
        );
      }
    });
  });

  group('themed components', () {
    for (final MapEntry(key: mode, value: c) in modes.entries) {
      for (final arabic in [true, false]) {
        final label = '$mode, ${arabic ? 'AR' : 'EN'}';
        final theme = mode == 'light'
            ? AppTheme.lightFor(arabic: arabic)
            : AppTheme.darkFor(arabic: arabic);

        test('dialogs are rounded like sheets, untinted ($label)', () {
          final d = theme.dialogTheme;
          expect(d.backgroundColor, c.groupedCard);
          expect(d.surfaceTintColor, Colors.transparent);
          expect(
            (d.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(AppRadius.sheet),
          );
          expect(d.titleTextStyle!.fontSize, AppTypography.headline.size);
          expect(d.titleTextStyle!.color, c.textPrimary);
          expect(d.contentTextStyle!.color, c.textSecondary);
        });

        test('dividers are hairline separators ($label)', () {
          expect(theme.dividerTheme.color, c.separator);
          // 0 draws exactly one device pixel.
          expect(theme.dividerTheme.thickness, 0);
        });

        test('list tiles use the 17pt body row ($label)', () {
          final l = theme.listTileTheme;
          expect(l.titleTextStyle!.fontSize, AppTypography.bodyXl.size);
          expect(l.titleTextStyle!.color, c.textPrimary);
          expect(l.subtitleTextStyle!.fontSize, AppTypography.caption.size);
          expect(l.subtitleTextStyle!.color, c.textSecondary);
          expect(l.minTileHeight, greaterThanOrEqualTo(AppTouchTarget.min));
          final expectedHeight = arabic
              ? AppTypography.bodyXl.heightArabic
              : AppTypography.bodyXl.heightLatin;
          expect(l.titleTextStyle!.height, expectedHeight);
        });

        test('switch thumb and track keep contrast in every state ($label)',
            () {
          final s = theme.switchTheme;
          const on = {WidgetState.selected};
          const off = <WidgetState>{};
          final thumbOn = s.thumbColor!.resolve(on)!;
          final trackOn = s.trackColor!.resolve(on)!;
          final thumbOff = s.thumbColor!.resolve(off)!;
          final trackOff = s.trackColor!.resolve(off)!;
          expect(AppContrast.ratio(thumbOn, trackOn), greaterThanOrEqualTo(3));
          expect(
            AppContrast.ratio(thumbOff, trackOff),
            greaterThanOrEqualTo(3),
          );
          // The track is the control boundary: 3:1 against any row fill.
          for (final row in [
            c.surface,
            c.pageBackground,
            c.groupedCard,
            c.cardFill,
            c.groupedBackground,
          ]) {
            for (final track in [trackOn, trackOff]) {
              expect(AppContrast.ratio(track, row), greaterThanOrEqualTo(3),
                  reason: 'track $track on $row');
            }
          }
        });

        test('cards use the card radius ($label)', () {
          expect(
            (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
            AppRadius.cardAll,
          );
          expect(theme.cardTheme.elevation, 0);
        });

        test('sheets have large top corners and no grabber ($label)', () {
          final b = theme.bottomSheetTheme;
          expect(b.showDragHandle, isFalse);
          expect(b.backgroundColor, c.groupedBackground);
          expect(b.surfaceTintColor, Colors.transparent);
          expect(
            (b.shape! as RoundedRectangleBorder).borderRadius,
            AppRadius.sheetTop,
          );
        });
      }
    }
  });

  testWidgets('themed dialog renders in RTL dark with the sheet radius',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkFor(arabic: true),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AlertDialog(title: Text('t'), content: Text('c')),
          ),
        ),
      ),
    );
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, SiratiColors.dark.groupedCard);
    expect(
      (material.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(AppRadius.sheet),
    );
  });
}
