import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/models/ats_grade.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Compact circular ATS score for cards.
///
/// The arc draws and the number counts up from 0 the first time the ring
/// appears, and from the old score to the new one when [score] changes. With
/// "remove animations" on it shows the final score at once. The arc colour
/// follows the score band; the number stays on body ink so it holds AA in
/// both themes.
///
/// The ring always sits on a [SiratiColors.cardFill] card (My CVs, Home), so
/// its track is that fill pressed twice: a neutral grey that keeps an edge
/// on the card (no warm beige), with the band's ink tone on top so the arc
/// holds 3:1 against both the track and the card in either theme.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 44,
    this.semanticLabel,
  });

  /// 0–100. Callers only build the ring for a CV that has a score.
  final int score;
  final double size;

  /// Read by screen readers. Leave null when text beside the ring already
  /// says the score.
  final String? semanticLabel;

  /// Same pace as the large ring on the analysis result.
  static const duration = Duration(milliseconds: 560);

  /// The grey track under the arc: the card fill, pressed twice.
  static Color trackOf(SiratiColors c) => c.pressed(c.pressed(c.cardFill));

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    final target = score.clamp(0, 100);
    final arc = switch (ScoreBand.of(target)) {
      ScoreBand.excellent || ScoreBand.veryGood => colors.onSuccessContainer,
      ScoreBand.fair => colors.onWarningContainer,
      ScoreBand.weak => colors.onErrorContainer,
    };
    final track = trackOf(colors);
    final reduce = MotionSettings.reduce(context);
    final english = AppLocale.isEnglish(context);

    final ring = RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? target / 100 : 0, end: target / 100),
        duration: reduce ? Duration.zero : duration,
        curve: MotionCurves.enter,
        builder: (context, value, _) => SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                color: arc,
                backgroundColor: track,
              ),
              Center(
                child: Text(
                  AppFormat.digits('${(value * 100).round()}', english: english),
                  style: AppTypography.of(context, AppTypography.labelLg),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: ring);
    return Semantics(label: label, excludeSemantics: true, child: ring);
  }
}
