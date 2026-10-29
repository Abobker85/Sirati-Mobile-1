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
    return FutureBuilder<CvAnalysis>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AnalysisResultScreen(analysis: snapshot.data!);
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final apiError = error is ApiException ? error : null;
          return Scaffold(
            backgroundColor: context.sirati.background,
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
        }
        return Scaffold(
          backgroundColor: context.sirati.background,
          appBar: AppBar(
            // Same as the page: a transparent bar over `background`.
            backgroundColor: context.sirati.background,
            elevation: 0,
          ),
          body: const Center(child: BrandedLoader()),
        );
      },
    );
  }
}
