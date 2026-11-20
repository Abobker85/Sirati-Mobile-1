import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/greeting_reveal.dart';

/// Home's large title: the greeting on the start side, with the hint under
/// it. It scrolls with the page; once it is under the pinned bar, the bar
/// shows the same greeting as a small title.
class HomeLargeTitle extends StatelessWidget {
  const HomeLargeTitle({
    super.key,
    required this.name,
    required this.subtitle,
  });

  /// The greeting line, for tests.
  static const titleKey = ValueKey('home-large-title');

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final gutter = AppSpacing.pageGutter(MediaQuery.sizeOf(context).width);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xs, gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Good morning / evening, revealed once per session.
          Semantics(
            header: true,
            child: GreetingReveal(
              key: titleKey,
              text: AppLocale.timedGreeting(name, context),
              dayPart: AppLocale.dayPart(DateTime.now()),
              style: AppTypography.of(context, AppTypography.largeTitle),
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.of(
                context,
                AppTypography.bodyMd,
                color: c.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
