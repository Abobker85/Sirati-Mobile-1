import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Score ring that animates once from 0 to [score] on first appear.
class AnimatedScoreRing extends StatelessWidget {
  const AnimatedScoreRing({
    super.key,
    required this.score,
    required this.scoreColor,
  });

  final int score;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    final target = score.clamp(0, 100) / 100.0;
    final reduce = MotionSettings.reduce(context);
    final english = AppLocale.isEnglish(context);
    final label = english
        ? 'ATS compatibility score'
        : 'درجة توافق السيرة الذاتية مع نظام تتبع المتقدمين';
    final valueText = english ? '$score out of 100' : '$score من 100';

    // RepaintBoundary keeps the per-frame ring animation from repainting the
    // rest of the score card.
    return Semantics(
      label: label,
      value: valueText,
      excludeSemantics: true,
      child: RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? target : 0, end: target),
        duration: reduce ? Duration.zero : MotionDurations.slow * 2,
        curve: MotionCurves.enter,
        builder: (context, value, _) {
          final display = (value * 100).round();
          return SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  backgroundColor: context.sirati.surface,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$display',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              // The ring carries the band colour; the number
                              // stays in a text tone (primary is ~2.9:1).
                              color: context.sirati.textPrimary,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.sirati.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
}
