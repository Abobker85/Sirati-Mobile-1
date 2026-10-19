import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
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

class DashboardCvHero extends ConsumerWidget {
  const DashboardCvHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final state = ref.watch(latestDashboardCvProvider(english));
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final cv = state.value;
    final ready =
        cv != null &&
        cv.hasScore &&
        cv.scoreTotal >= 0 &&
        cv.scoreTotal <= 100 &&
        !AiStatus.isPending(cv.aiStatus);
    final rows = ref.watch(myCvsProvider(english)).value?.items;
    final savedRow = rows?.where((item) => item.id == cv?.id).firstOrNull;
    final updatedAt = savedRow?.updatedAt;
    final updatedLabel = updatedAt == null
        ? savedRow?.updatedLabel ?? ''
        : '${MaterialLocalizations.of(context).formatCompactDate(updatedAt.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt.toLocal()))}';
    final band = cv == null ? null : ScoreBand.of(cv.scoreTotal);
    final bandLabel = switch (band) {
      ScoreBand.excellent => l.homeHeroBandExcellent,
      ScoreBand.veryGood => l.homeHeroBandVeryGood,
      ScoreBand.fair => l.homeHeroBandFair,
      _ => l.homeHeroBandWeak,
    };
    final review = ready && cv.scoreTotal >= 80;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        key: const ValueKey('home-cv-hero'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isLoading)
            Text(l.savedCvsLoading, style: TextStyle(color: c.textSecondary))
          else if (state.hasError) ...[
            Text(
              l.homeHeroLatestCvError,
              style: TextStyle(color: c.textSecondary),
            ),
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
          ] else if (cv == null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Icon(
                Icons.post_add_rounded,
                size: 36,
                color: c.primaryInk,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.homeHeroFirstCvTitle,
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.homeHeroFirstCvDescription,
              style: TextStyle(color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            SubmitButton(
              label: l.homeHeroCreateCv,
              onPressed: () =>
                  unawaited(Navigator.pushNamed(context, AppRoutes.createCv)),
            ),
          ] else ...[
            Text(
              l.homeHeroLatestCv,
              style: TextStyle(
                color: c.primaryInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cv.targetJobTitle,
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            if (updatedLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.homeHeroUpdatedAt(updatedLabel),
                style: TextStyle(color: c.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            if (ready) ...[
              Center(
                child: Semantics(
                  label: l.homeHeroAtsScore,
                  value: '${cv.scoreTotal.clamp(0, 100)} / 100',
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: cv.scoreTotal.clamp(0, 100) / 100,
                          color: c.primaryInk,
                          backgroundColor: c.surface,
                          strokeWidth: 7,
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: FittedBox(
                              child: Text(
                                '${cv.scoreTotal.clamp(0, 100)}%',
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${l.homeHeroAtsScore} · $bandLabel',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary),
              ),
            ] else
              Text(
                l.homeHeroScoreUnavailable,
                style: TextStyle(color: c.textSecondary),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.homeHeroNextStep,
                    style: TextStyle(
                      color: c.primaryInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review
                        ? l.homeHeroReviewNextStep
                        : l.homeHeroAnalyzeNextStep,
                    style: TextStyle(color: c.primaryInk),
                  ),
                  const SizedBox(height: 12),
                  SubmitButton(
                    label: review ? l.homeHeroReviewCv : l.atsInputAnalyze,
                    onPressed: () => unawaited(
                      review
                          ? Navigator.pushNamed(context, AppRoutes.cv(cv.id))
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CvAnalysisScreen(initialCvId: cv.id),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
