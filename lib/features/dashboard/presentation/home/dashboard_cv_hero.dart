import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Select by real update timestamps; a missing score is never shown as zero.
final latestDashboardCvProvider = FutureProvider.autoDispose
    .family<GeneratedCv?, bool>((ref, english) async {
      final list = await ref.watch(myCvsProvider(english).future);
      final items = list.items.where((cv) => cv.id != null).toList()
        ..sort(
          (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
            a.updatedAt ?? DateTime(1970),
          ),
        );
      if (items.isEmpty) return null;
      return ref.read(cvApiServiceProvider).getGeneratedCv(items.first.id!);
    });

/// Home hero (Salem review, elements 2–6), in its two agreed states:
/// no CV yet — start one or bring an old one; a CV — its ATS score and the
/// next step towards a stronger CV or a targeted job.
class DashboardCvHero extends ConsumerWidget {
  const DashboardCvHero({super.key, this.onReturnFromJobMatch});

  /// Job match can create a tailored CV; Home reloads when the user is back.
  final Future<void> Function()? onReturnFromJobMatch;

  static const primaryKey = ValueKey('home-hero-primary');
  static const secondaryKey = ValueKey('home-hero-secondary');
  static const scoreKey = ValueKey('home-hero-score');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final state = ref.watch(latestDashboardCvProvider(english));
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final cv = state.value;

    final List<Widget> children;
    if (state.isLoading) {
      children = [
        Text(l.savedCvsLoading, style: TextStyle(color: c.textSecondary)),
      ];
    } else if (state.hasError) {
      children = [
        Text(l.homeHeroLatestCvError, style: TextStyle(color: c.textSecondary)),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () {
                ref.invalidate(myCvsProvider(english));
                ref.invalidate(latestDashboardCvProvider(english));
              },
              child: Text(l.retry),
            ),
            TextButton(
              onPressed: () =>
                  unawaited(Navigator.pushNamed(context, AppRoutes.myCvs)),
              child: Text(l.homeHeroSavedCvs),
            ),
          ],
        ),
      ];
    } else if (cv == null) {
      children = _start(context, l);
    } else {
      children = _returning(context, ref, l, cv, english);
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        key: const ValueKey('home-cv-hero'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  List<Widget> _start(BuildContext context, AppLocalizations l) {
    final c = context.sirati;
    return [
      const Center(child: _CvIllustration(scored: false)),
      const SizedBox(height: 16),
      Text(
        l.homeHeroStartTitle,
        style: TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      const SizedBox(height: 8),
      Text(l.homeHeroStartBody, style: TextStyle(color: c.textSecondary)),
      const SizedBox(height: 16),
      SubmitButton(
        key: primaryKey,
        label: l.homeHeroCreateYourCv,
        onPressed: () =>
            unawaited(Navigator.pushNamed(context, AppRoutes.createCv)),
      ),
      const SizedBox(height: 10),
      SubmitButton(
        key: secondaryKey,
        label: l.homeHeroUploadOld,
        outlined: true,
        onPressed: () => unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CvAnalysisScreen()),
          ),
        ),
      ),
    ];
  }

  List<Widget> _returning(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    GeneratedCv cv,
    bool english,
  ) {
    final c = context.sirati;
    final scored = cv.hasScore &&
        cv.scoreTotal >= 0 &&
        cv.scoreTotal <= 100 &&
        !AiStatus.isPending(cv.aiStatus);
    final score = cv.scoreTotal.clamp(0, 100);
    final rows = ref.watch(myCvsProvider(english)).value?.items;
    final savedRow = rows?.where((item) => item.id == cv.id).firstOrNull;
    final updatedAt = savedRow?.updatedAt;
    // The backend label is already a full phrase ("Last updated: ..."); only
    // a date formatted here needs the "Updated {time}" wrapper.
    final updatedText = updatedAt == null
        ? savedRow?.updatedLabel ?? ''
        : l.homeHeroUpdatedAt(
            '${MaterialLocalizations.of(context).formatCompactDate(updatedAt.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt.toLocal()))}',
          );
    final caption = switch (ScoreBand.of(score)) {
      ScoreBand.excellent => l.homeHeroScoreExcellent,
      ScoreBand.veryGood => l.homeHeroScoreVeryGood,
      ScoreBand.fair => l.homeHeroScoreFair,
      ScoreBand.weak => l.homeHeroScoreWeak,
    };

    return [
      const Center(child: _CvIllustration(scored: true)),
      const SizedBox(height: 12),
      Text(
        cv.targetJobTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      if (updatedText.isNotEmpty)
        Text(
          updatedText,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSecondary, fontSize: 12),
        ),
      const SizedBox(height: 14),
      Container(
        key: scoreKey,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: scored
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.homeHeroScoreTitle(
                            AppFormat.digits('$score', english: english),
                          ),
                          style: TextStyle(
                            color: c.primaryInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          caption,
                          style: TextStyle(color: c.primaryInk, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: l.homeHeroAtsScore,
                    value: '$score / 100',
                    child: SizedBox.square(
                      dimension: 56,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: score / 100,
                            color: c.primaryInk,
                            backgroundColor: c.surface,
                            strokeWidth: 5,
                          ),
                          Center(
                            child: Text(
                              AppFormat.digits('$score', english: english),
                              style: TextStyle(
                                color: c.primaryInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                l.homeHeroScoreUnavailable,
                style: TextStyle(color: c.primaryInk),
              ),
      ),
      const SizedBox(height: 16),
      Text(
        l.homeHeroNextStronger,
        style: TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      const SizedBox(height: 12),
      SubmitButton(
        key: primaryKey,
        label: l.homeHeroImprove,
        onPressed: () => unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CvAnalysisScreen(initialCvId: cv.id),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SubmitButton(
        key: secondaryKey,
        label: l.homeHeroTargetJob,
        outlined: true,
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.jobMatch);
          if (context.mounted) await onReturnFromJobMatch?.call();
        },
      ),
    ];
  }
}

/// The hero's CV drawing: a page with a check while there is no CV yet, with
/// a score gauge and sparkles once there is one.
class _CvIllustration extends StatelessWidget {
  const _CvIllustration({required this.scored});

  final bool scored;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    Widget line(double width) => Container(
          width: width,
          height: 4,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: c.borderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return ExcludeSemantics(
      child: SizedBox(
        width: 180,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (scored) ...[
              PositionedDirectional(
                start: 22,
                top: 24,
                child: Icon(Icons.auto_awesome, size: 26, color: c.primaryInk),
              ),
              PositionedDirectional(
                end: 22,
                top: 18,
                child: Icon(Icons.auto_awesome, size: 22, color: c.primaryInk),
              ),
            ] else
              Container(
                width: 160,
                height: 26,
                decoration: BoxDecoration(
                  color: c.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            Container(
              width: 64,
              height: 88,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.primaryInk, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    scored ? Icons.speed_rounded : Icons.check_box_rounded,
                    size: 24,
                    color: c.primaryInk,
                  ),
                  line(40),
                  line(32),
                  line(40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
