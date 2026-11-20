import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/ai_error_message.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/application/improved_cv_controller.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/recommendations_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_tab.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Analysis result: score + criteria tab, recommendations tab, and a
/// "generate improved CV" action driven by [ImprovedCvController].
class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({
    super.key,
    required this.analysis,
    this.justScanned = false,
    this.previousScore,
  });

  final CvAnalysis analysis;

  /// Opened straight from a finished scan: the score is revealed as a
  /// moment. Saved results show it at once.
  final bool justScanned;

  /// The score of the last scan of the same CV for the same job, when there
  /// was one: the ring then shows how far the score moved.
  final int? previousScore;

  /// The docked "generate improved CV" bar.
  static const actionBarKey = ValueKey('analysis-result-action-bar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final isGenerating = ref.watch(improvedCvControllerProvider(analysis.id));
    final l = AppLocalizations.of(context);
    final c = context.sirati;

    return Directionality(
      textDirection: AppLocale.direction(context),
      child: DefaultTabController(
        length: 2,
        // Zero under reduced motion: the page jumps with the thumb.
        animationDuration: AppSegmentedTabBar.pageDuration(context),
        child: Scaffold(
          appBar: AppBar(
            title: Text(l.atsResultsTitle),
            toolbarHeight:
                56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
            actions: const [LanguageToggle()],
            bottom: AppSegmentedTabBar(
              textScaler: MediaQuery.textScalerOf(context),
              tabs: [
                AppSegmentedTab(label: l.atsTabScore),
                AppSegmentedTab(label: l.atsTabRecommendations),
              ],
            ),
          ),
          // The page colour, no edge: the button carries its own fill.
          bottomNavigationBar: ColoredBox(
            key: AnalysisResultScreen.actionBarKey,
            color: c.pageBackground,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SubmitButton(
                  label: l.atsGenerateImprovedCv,
                  loadingLabel: l.atsGenerating,
                  isLoading: isGenerating,
                  icon: Icons.auto_awesome_rounded,
                  onPressed:
                      isGenerating ? null : () => _generate(context, ref),
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              ScoreTab(
                analysis: analysis,
                english: english,
                revealScore: justScanned,
                previousScore: previousScore,
              ),
              RecommendationsTab(
                weaknesses: analysis.weaknesses,
                strengths: analysis.strengths,
                quickWins: analysis.quickWins,
                hidden: analysis.hidden,
                english: english,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final english = AppLocale.isEnglish(context);
    final controller = ref.read(
      improvedCvControllerProvider(analysis.id).notifier,
    );

    final progress = await AiProgressOverlay.show(
      context,
      kind: AiProgressKind.generation,
      english: english,
      onCancelled: controller.cancel,
    );
    final outcome = await controller.generate(
      isCancelled: () => progress.isCancelled,
    );
    if (!context.mounted) {
      await progress.dismiss();
      return;
    }

    switch (outcome) {
      case ImprovedCvCancelled():
        await progress.dismiss();
        return;
      case ImprovedCvFailed(:final error):
        await progress.dismiss();
        if (!context.mounted) return;
        if (error is ApiException) {
          AppSnackBar.fromException(context, error);
        } else {
          AppSnackBar.error(
            context,
            AppLocalizations.of(context).atsGenerateUnexpectedError,
          );
        }
      case ImprovedCvReady(
          :final generatedCvId,
          :final timedOut,
          :final aiFailed,
          :final aiError,
        ):
        if (!timedOut && !aiFailed) await progress.complete();
        if (!context.mounted) {
          await progress.dismiss();
          return;
        }
        if (timedOut) {
          AppSnackBar.warning(
            context,
            AppLocalizations.of(context).atsAiStillWorkingGeneration,
          );
        } else if (aiFailed) {
          AppSnackBar.error(
            context,
            AiErrorMessage.generationFailed(
                aiError, AppLocalizations.of(context)),
            actionLabel: AppLocalizations.of(context).retry,
            onAction: () => _generate(context, ref),
          );
        }
        final navigator = Navigator.of(context);
        final route = navigator.widget.onGenerateRoute?.call(
          RouteSettings(name: AppRoutes.cv(generatedCvId)),
        );
        if (route != null) {
          unawaited(progress.handOff<dynamic>(navigator, route));
        } else {
          await progress.dismiss();
          unawaited(navigator.pushNamed(AppRoutes.cv(generatedCvId)));
        }
    }
  }
}
