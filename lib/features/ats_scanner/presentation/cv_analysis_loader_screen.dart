import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/branded_loader.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Deep-link entry for `/analysis/:id` — loads the analysis then shows the real screen.
class CvAnalysisLoaderScreen extends ConsumerStatefulWidget {
  final int analysisId;

  const CvAnalysisLoaderScreen({
    super.key,
    required this.analysisId,
  });

  @override
  ConsumerState<CvAnalysisLoaderScreen> createState() =>
      _CvAnalysisLoaderScreenState();
}

class _CvAnalysisLoaderScreenState
    extends ConsumerState<CvAnalysisLoaderScreen> {
  late Future<CvAnalysis> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cvApiServiceProvider).getAnalysis(widget.analysisId);
  }

  /// Fetches before swapping the future so the offline screen's automatic
  /// retries don't flash the loader. While still offline the error is
  /// rethrown to [OfflineView], which stays up and tries again later.
  Future<void> _retry({required bool offline}) async {
    final next = ref.read(cvApiServiceProvider).getAnalysis(widget.analysisId);
    try {
      await next;
    } on ApiException catch (e) {
      if (offline && e.type == ApiErrorType.network) rethrow;
    } catch (_) {}
    if (mounted) setState(() => _future = next);
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final reduce = MotionSettings.reduce(context);
    return FutureBuilder<CvAnalysis>(
      future: _future,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.hasData) {
          child = AnalysisResultScreen(
            key: ValueKey('analysis-loader-data-${snapshot.data!.id}'),
            analysis: snapshot.data!,
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          final apiError = error is ApiException ? error : null;
          child = Scaffold(
            key: const ValueKey('analysis-loader-error'),
            backgroundColor: context.sirati.pageBackground,
            appBar: AppBar(),
            body: AppErrorState(
              english: english,
              message: apiError?.displayMessage ??
                  AppLocalizations.of(context).atsOpenAnalysisFailed,
              exception: apiError,
              onRetry: () => _retry(
                offline: apiError?.type == ApiErrorType.network,
              ),
              onOpenSaved: () => Navigator.pushNamed(context, AppRoutes.myCvs),
            ),
          );
        } else {
          child = Scaffold(
            key: const ValueKey('analysis-loader-loading'),
            backgroundColor: context.sirati.pageBackground,
            appBar: AppBar(
              // Same as the result page it fades into.
              backgroundColor: context.sirati.pageBackground,
              elevation: 0,
            ),
            body: const Center(child: BrandedLoader()),
          );
        }

        if (reduce) return child;
        return AnimatedSwitcher(
          duration: MotionDurations.medium,
          switchInCurve: MotionCurves.enter,
          switchOutCurve: MotionCurves.exit,
          child: child,
        );
      },
    );
  }
}
