import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/storage/guest_session.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_loader_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/features/auth/presentation/sign_in_required_screen.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_loader_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_detail_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/features/dashboard/presentation/gallery_screen.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/dashboard/presentation/home_screen.dart';
import 'package:sirati/features/dashboard/presentation/not_found_screen.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/features/dashboard/presentation/splash_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/settings/presentation/deleted_account_cleanup_screen.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/privacy_policy_screen.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';

/// Composition root: maps route names onto feature screens.
void registerSiratiRouteWidgets() {
  AppRouter.registerWidgets(_guardedWidgetFor);
  GeneratedCvHubLinks.atsCheck = openCvHubAtsCheck;
}

/// Source CV and its current text carried into the ATS input screen.
class CvHubAtsCheckArguments {
  const CvHubAtsCheckArguments({required this.cvId, required this.markdown});

  final int cvId;
  final String markdown;
}

Future<void> openCvHubAtsCheck(BuildContext context, GeneratedCv cv) async {
  await Navigator.of(context).push<void>(MaterialPageRoute<void>(
    settings: RouteSettings(
        arguments: CvHubAtsCheckArguments(
      cvId: cv.id,
      markdown: cv.resumeText,
    )),
    builder: (_) => CvAnalysisScreen(
      initialCvId: cv.id,
      initialMarkdown: cv.resumeText,
      initialJobTitle: cv.targetJobTitle,
      initialJobDescription: cv.jobDescriptionInput,
    ),
  ));
}

/// Routes a guest ("Continue without account") may open: browsing jobs and
/// learning, and the ways in. Everything else needs an account.
const _openToGuests = {
  AppRoutes.splash,
  AppRoutes.home,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.myCvs,
  AppRoutes.education,
  AppRoutes.jobNews,
  AppRoutes.privacy,
  AppRoutes.notFound,
};

bool routeOpenToGuests(ParsedRoute parsed) =>
    _openToGuests.contains(parsed.name) ||
    (parsed.name.startsWith(AppRoutes.educationItemPrefix) &&
        parsed.id != null);

/// For a guest, an account-only route opens the sign-in invitation instead
/// of a screen that would fail with a 401.
Widget _guardedWidgetFor(ParsedRoute parsed) {
  if (GuestSession.active.value && !routeOpenToGuests(parsed)) {
    return const SignInRequiredScreen();
  }
  return _widgetFor(parsed);
}

Widget _widgetFor(ParsedRoute parsed) {
  switch (parsed.name) {
    case AppRoutes.splash:
      return const SplashScreen();
    case AppRoutes.home:
      return const HomeScreen();
    case AppRoutes.login:
      final cleanup = parsed.arguments;
      if (cleanup is PendingLocalSessionCleanup) {
        return DeletedAccountCleanupScreen(retryCleanup: cleanup.retry);
      }
      return const LoginScreen();
    case AppRoutes.register:
      return const RegisterScreen();
    case AppRoutes.history:
      return const HistoryScreen();
    case AppRoutes.createCv:
      final job = parsed.arguments;
      return CvGeneratorScreen(targetJob: job is CvTargetJob ? job : null);
    case AppRoutes.cvBuilder:
      return const CvBuilderScreen();
    case AppRoutes.myCvs:
      return const HomeScreen(initialIndex: 1);
    case AppRoutes.education:
      return const EducationScreen();
    case AppRoutes.jobNews:
      // Jobs is a Home tab: deep links land on it with the bottom nav.
      return HomeScreen(initialIndex: DashboardTab.jobNews.index);
    case AppRoutes.profile:
      return const ProfileScreen();
    case AppRoutes.privacy:
      return const PrivacyPolicyScreen();
    case AppRoutes.settings:
      return const SettingsScreen();
    case AppRoutes.notifications:
      return const NotificationsScreen();
    case AppRoutes.premium:
      return const PremiumGateScreen();
    case AppRoutes.gallery:
      return const ComponentGalleryScreen();
    case AppRoutes.jobMatch:
      final cvId = parsed.arguments;
      return JobMatchScreen(initialCvId: cvId is int ? cvId : null);
    case AppRoutes.atsScan:
      final args = parsed.arguments;
      return args is AtsScanArgs
          ? _SavedCvAnalysisEntry(
              initialCvId: args.cvId,
              initialSource: args.upload
                  ? AnalysisCvSource.upload
                  : AnalysisCvSource.saved,
            )
          : const _SavedCvAnalysisEntry();
    case AppRoutes.notFound:
      return const NotFoundScreen();
  }

  if (parsed.name.startsWith(AppRoutes.cvBuilderPrefix) &&
      parsed.stringId != null) {
    return CvBuilderScreen(cvId: parsed.stringId);
  }
  if (parsed.name.startsWith(AppRoutes.cvPrefix) && parsed.id != null) {
    final cv = parsed.arguments;
    if (cv is GeneratedCv && cv.id == parsed.id) {
      return GeneratedCvScreen(generatedCv: cv);
    }
    return GeneratedCvLoaderScreen(cvId: parsed.id!);
  }
  if (parsed.name.startsWith(AppRoutes.analysisPrefix) && parsed.id != null) {
    return CvAnalysisLoaderScreen(analysisId: parsed.id!);
  }
  if (parsed.name.startsWith(AppRoutes.analysisPrefix)) {
    return const _SavedCvAnalysisEntry();
  }
  if (parsed.name.startsWith(AppRoutes.educationItemPrefix) &&
      parsed.id != null) {
    return EducationDetailScreen(id: parsed.id, fallback: const {});
  }
  return const NotFoundScreen();
}

/// Compose the saved list here so ATS never imports the CV builder feature.
class _SavedCvAnalysisEntry extends ConsumerWidget {
  const _SavedCvAnalysisEntry({
    this.initialCvId,
    this.initialSource = AnalysisCvSource.saved,
  });

  final int? initialCvId;
  final AnalysisCvSource initialSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final saved = ref.watch(myCvsProvider(english));
    return CvAnalysisScreen(
      savedCvs: saved.whenData(
        (list) => [
          for (final cv in list.items)
            if (cv.id != null) SavedAnalysisCv(id: cv.id!, title: cv.title),
        ],
      ),
      onRetrySaved: () => ref.invalidate(myCvsProvider(english)),
      initialCvId: initialCvId,
      initialSource: initialSource,
    );
  }
}
