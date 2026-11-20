import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Every painted colour of every bone, in every screen skeleton, at every
/// sampled shimmer frame, is the grey card fill or its pressed shade: the
/// skeletons never paint the old beige surfaces.
void main() {
  final screens = <String, Widget>{
    'dashboard': const DashboardSkeleton(),
    'cv list': const CvListSkeleton(),
    'job news': const JobNewsSkeleton(),
    'list': const ListScreenSkeleton(),
    'education': const EducationSkeleton(),
    'lone bone': const Center(child: AppSkeleton(width: 120)),
  };

  for (final dark in [false, true]) {
    for (final reduce in [false, true]) {
      for (final direction in TextDirection.values) {
        final suffix = '${dark ? 'dark' : 'light'}, '
            '${reduce ? 'reduced' : 'animated'}, ${direction.name}';
        testWidgets('skeleton bones stay in the grey family ($suffix)',
            (tester) async {
          final theme = dark ? AppTheme.dark : AppTheme.light;
          final c = theme.extension<SiratiColors>()!;
          final grey = {c.cardFill, c.cardFillPressed};
          for (final entry in screens.entries) {
            await tester.pumpWidget(MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduce),
                child: Directionality(textDirection: direction, child: child!),
              ),
              home: Scaffold(body: entry.value),
            ));
            const steps = 7;
            for (var i = 0; i < steps; i++) {
              await tester.pump(MotionDurations.skeleton ~/ steps);
              final bones = find.descendant(
                of: find.byType(AppSkeleton),
                matching: find.byType(DecoratedBox),
              );
              expect(bones, findsWidgets, reason: entry.key);
              for (final element in bones.evaluate()) {
                final d = (element.widget as DecoratedBox).decoration
                    as BoxDecoration;
                final painted = [
                  if (d.color != null) d.color!,
                  ...?d.gradient?.colors,
                ];
                expect(painted, isNotEmpty, reason: entry.key);
                for (final color in painted) {
                  expect(grey, contains(color),
                      reason: '${entry.key} frame $i ($suffix)');
                }
              }
              // Nothing fades the bone into the page.
              expect(
                find.descendant(
                  of: find.byType(AppSkeleton),
                  matching: find.byType(Opacity),
                ),
                findsNothing,
              );
            }
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
