import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/storage/guest_session.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/auth/data/auth_session_guard.dart';
import 'package:sirati/features/auth/presentation/sign_in_required_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_loader_screen.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_detail_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_navigation_bar.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/navigation/notification_target.dart';
import 'package:sirati/shared/services/notification_engagement_service.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// App shell: bottom-navigation tabs, Android back handling, and
/// push-notification routing.
///
/// Guests ("Continue without account") get Jobs and Education; Home and
/// My CVs show [SignInRequiredView] instead, so they never call endpoints
/// that need an account.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DashboardTab _tab = DashboardTab.fromIndex(widget.initialIndex);
  DateTime? _lastBackAtRoot;

  /// Null until the token store answers; then whether nobody is signed in.
  /// If the store can't be read the shell behaves as signed in and the
  /// server stays the judge.
  bool? _guest;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.onNotificationTap = _onNotificationTap;
    _logTab(_tab);
    unawaited(_resolveSession());
  }

  Future<void> _resolveSession() async {
    String? token;
    try {
      token = await AuthSessionGuard.tokenStore.readToken();
    } catch (_) {
      token = 'unknown';
    }
    if (!mounted) return;
    if (token == null || token.trim().isEmpty) {
      GuestSession.active.value = true;
      setState(() {
        _guest = true;
        // Land guests on what they can use.
        if (_tab == DashboardTab.home) _tab = DashboardTab.jobNews;
      });
      _logTab(_tab);
      return;
    }
    GuestSession.active.value = false;
    setState(() => _guest = false);
    // Touch server activity so quiet/recent-activity policy stays accurate.
    unawaited(
      NotificationEngagementService.instance.reportActivity(event: 'app_open'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_activatePushAfterVisible());
    });
  }

  static bool _needsAccount(DashboardTab tab) =>
      tab == DashboardTab.home || tab == DashboardTab.myCvs;

  @override
  void dispose() {
    // Detach so taps after logout are buffered for the next session instead
    // of navigating with this disposed context.
    final service = NotificationService.instance;
    if (service.onNotificationTap == _onNotificationTap) {
      service.onNotificationTap = null;
    }
    super.dispose();
  }

  Future<void> _activatePushAfterVisible() async {
    try {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.registerToken();
    } catch (e, st) {
      debugPrint('[FCM] post-home registration skipped: $e\n$st');
    }
  }

  void _setTab(DashboardTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _logTab(tab);
  }

  void _logTab(DashboardTab tab) {
    unawaited(AnalyticsService.logScreenView(screenName: tab.screenName));
  }

  void _onRootBack(bool didPop, Object? result) {
    if (didPop) return;

    // Other tabs: first back returns to Home.
    if (_tab != DashboardTab.home) {
      _setTab(DashboardTab.home);
      _lastBackAtRoot = null;
      return;
    }

    // iOS: no system back / double-exit at the root.
    if (Theme.of(context).platform == TargetPlatform.iOS) return;

    final now = DateTime.now();
    final previous = _lastBackAtRoot;
    if (previous != null &&
        now.difference(previous) <= const Duration(seconds: 2)) {
      unawaited(SystemNavigator.pop());
      return;
    }

    _lastBackAtRoot = now;
    AppSnackBar.info(
      context,
      AppLocalizations.of(context).dashboardPressBackAgainToExit,
    );
  }

  void _onNotificationTap(Map<String, dynamic> data) {
    if (!mounted) return;
    switch (resolveNotificationTarget(data)) {
      case OpenExternalUrl(:final url):
        unawaited(launchSafeExternalUrl(url));
      case OpenTab(:final tab, :final educationId):
        _setTab(tab);
        if (educationId != null) {
          _push(EducationDetailScreen(id: educationId, fallback: const {}));
        }
      case OpenGeneratedCv(:final id):
        _setTab(DashboardTab.myCvs);
        _push(GeneratedCvLoaderScreen(cvId: id));
      case OpenScreen(:final screen):
        _push(switch (screen) {
          NotificationScreen.notifications => const NotificationsScreen(),
          NotificationScreen.cvAnalysis => const CvAnalysisScreen(),
          NotificationScreen.history => const HistoryScreen(),
          NotificationScreen.cvGenerator => const CvGeneratorScreen(),
          NotificationScreen.settings => const SettingsScreen(),
        });
    }
  }

  void _push(Widget screen) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // canPop:false keeps Home as the authenticated root (no return to splash).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onRootBack,
      child: Scaffold(
        backgroundColor: context.sirati.background,
        body: MotionTabStack(
          currentIndex: _tab.index,
          // Built from the enum so page order always matches the nav bar.
          children: [
            for (final tab in DashboardTab.values)
              // Account tabs wait for the session check, so a guest never
              // calls their endpoints.
              if (_needsAccount(tab) && _guest == null)
                const SizedBox.shrink()
              else if (_needsAccount(tab) && _guest == true)
                SignInRequiredView(
                  key: ValueKey('sign-in-required-${tab.name}'),
                  onBrowseJobs: () => _setTab(DashboardTab.jobNews),
                  showBack: false,
                )
              else
                switch (tab) {
                  DashboardTab.home => DashboardHomeTab(onNavigate: _setTab),
                  DashboardTab.myCvs => const MyCvsScreen(),
                  DashboardTab.jobNews =>
                    JobNewsScreen(isActive: _tab == DashboardTab.jobNews),
                  DashboardTab.education => const EducationScreen(),
                },
          ],
        ),
        bottomNavigationBar: DashboardNavigationBar(
          current: _tab,
          onChanged: _setTab,
        ),
      ),
    );
  }
}
