import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

// Production callers: ScreenHeader and Settings' ProfileSummaryCard.
void main() {
  for (final dark in [false, true]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'avatar initials remain proportional and contained, '
        'dark=$dark, direction=$direction',
        (tester) async {
          final theme = dark ? AppTheme.dark : AppTheme.light;
          final labels = direction == TextDirection.rtl
              ? const ['م', 'نور']
              : const ['W', 'AB'];
          for (final size in [24.0, 46.0, 64.0, 128.0]) {
            for (final label in labels) {
              Size? cappedSize;
              for (final scale in [1.0, 2.0, 4.0]) {
                await tester.pumpWidget(
                  MaterialApp(
                    theme: theme,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    home: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Directionality(
                        textDirection: direction,
                        child: Center(
                          child: ProfileAvatar(label: label, size: size),
                        ),
                      ),
                    ),
                  ),
                );

                expect(tester.takeException(), isNull);
                final avatar = find.byType(ProfileAvatar);
                expect(tester.getSize(avatar), Size.square(size));
                final paragraph = tester.renderObject<RenderParagraph>(
                  find.descendant(of: avatar, matching: find.byType(RichText)),
                );
                final style = (paragraph.text as TextSpan).style!;
                final typography = AppTypography.titleMd.resolve(
                  arabic: direction == TextDirection.rtl,
                );
                expect(style.fontSize, size * 0.35);
                expect(style.fontFamily, typography.fontFamily);
                expect(style.fontWeight, typography.fontWeight);
                expect(style.height, typography.height);
                expect(
                  paragraph.textScaler.scale(style.fontSize!),
                  style.fontSize! * (scale > 1.3 ? 1.3 : scale),
                );
                expect(paragraph.didExceedMaxLines, isFalse);

                // Include the real FittedBox transform in the painted bounds.
                final textBounds = Rect.fromPoints(
                  paragraph.localToGlobal(Offset.zero),
                  paragraph.localToGlobal(
                    paragraph.size.bottomRight(Offset.zero),
                  ),
                );
                final faceBounds = tester.getRect(avatar);
                expect(textBounds.left, greaterThanOrEqualTo(faceBounds.left));
                expect(textBounds.top, greaterThanOrEqualTo(faceBounds.top));
                expect(textBounds.right, lessThanOrEqualTo(faceBounds.right));
                expect(textBounds.bottom, lessThanOrEqualTo(faceBounds.bottom));
                expect(textBounds.width, greaterThan(0));
                expect(textBounds.height, greaterThan(0));
                if (scale == 2) {
                  cappedSize = textBounds.size;
                } else if (scale > 2) {
                  expect(textBounds.size, cappedSize);
                }

                final face = tester.widget<Container>(
                  find.descendant(
                    of: avatar,
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget is Container &&
                          widget.decoration is BoxDecoration &&
                          (widget.decoration! as BoxDecoration).gradient !=
                              null,
                    ),
                  ),
                );
                final gradient = (face.decoration! as BoxDecoration).gradient!;
                for (final fill in gradient.colors) {
                  expect(
                    AppContrast.ratio(style.color!, fill),
                    greaterThanOrEqualTo(4.5),
                  );
                }
              }
            }
          }
        },
      );
    }
  }
}
