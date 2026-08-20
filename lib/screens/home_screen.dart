import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/analytics_service.dart';
import '../services/mobile_content_service.dart';
import '../services/notification_engagement_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../services/session_cache.dart';
import '../utils/app_format.dart';
import '../utils/safe_url.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/motion.dart';
import '../widgets/offline_cache_banner.dart';
import '../widgets/screen_header.dart';
import '../services/api_exception.dart';
import 'cv_analysis_screen.dart';
import 'cv_generator_screen.dart';
import 'education_detail_screen.dart';
import 'education_screen.dart';
import 'history_screen.dart';
import 'job_news_screen.dart';
import 'my_cvs_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex = widget.initialIndex;
  DateTime? _lastBackAtRoot;

  static const _tabScreenNames = [
    'dashboard',
    'my_cvs',
    'education',
    'job_news',
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationTapHandler();
    // Touch server activity so quiet/recent-activity policy stays accurate.
    NotificationEngagementService.instance.reportActivity(event: 'app_open');
    // Home is one route — log the active tab manually.
    _logTabScreen(_currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_activatePushAfterVisible());
    });
  }

  Future<void> _activatePushAfterVisible() async {
    try {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.registerToken();
    } catch (e, st) {
      debugPrint('[FCM] post-home registration skipped: $e\n$st');
    }
  }

  void _setTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _logTabScreen(index);
  }

  void _logTabScreen(int index) {
    if (index < 0 || index >= _tabScreenNames.length) return;
    AnalyticsService.logScreenView(screenName: _tabScreenNames[index]);
  }

  void _onRootBack(bool didPop, Object? result) {
    if (didPop) return;

    // Other tabs: first back returns to Dashboard.
    if (_currentIndex != 0) {
      _setTab(0);
      _lastBackAtRoot = null;
      return;
    }

    // iOS: keep previous silent root behavior (no system back / double-exit).
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIos) return;

    final now = DateTime.now();
    final previous = _lastBackAtRoot;
    if (previous != null &&
        now.difference(previous) <= const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }

    _lastBackAtRoot = now;
    final english = AppLocale.isEnglish(context);
    AppSnackBar.info(
      context,
      english ? 'Press back again to exit' : 'اضغط رجوع مرة أخرى للخروج',
    );
  }

  void _setupNotificationTapHandler() {
    NotificationService.instance.onNotificationTap = (data) {
      final actionType = data['action_type']?.toString();
      final actionUrl = data['action_url']?.toString();

      switch (actionType) {
        case 'url':
          unawaited(launchSafeExternalUrl(actionUrl));
          break;
        case 'screen':
          _navigateToScreen(actionUrl);
          break;
        default:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
      }
    };
  }

  void _navigateToScreen(String? route) {
    if (route == null || route.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }

    final path = route.startsWith('/') ? route.substring(1) : route;
    final parts = path.split('/');
    final root = parts.isNotEmpty ? parts.first : path;
    final id = parts.length > 1 ? int.tryParse(parts[1]) : null;

    switch (root) {
      case 'home':
        _setTab(0);
        break;
      case 'my-cvs':
      case 'mycvs':
        _setTab(1);
        break;
      case 'education':
        _setTab(2);
        if (id != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EducationDetailScreen(
                id: id,
                fallback: const {},
              ),
            ),
          );
        }
        break;
      case 'job-news':
      case 'jobs':
        _setTab(3);
        break;
      case 'cv-analysis':
      case 'analysis-new':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CvAnalysisScreen()),
        );
        break;
      case 'analysis':
        if (id != null) {
          // Open analysis flow; full result load is handled inside history/result screens.
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CvAnalysisScreen()),
          );
        }
        break;
      case 'create-cv':
      case 'cv-generator':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CvGeneratorScreen()),
        );
        break;
      case 'notifications':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      default:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // canPop:false keeps Home as the authenticated root (no return to splash).
    // onPopInvokedWithResult handles tab → dashboard, then Android double-back exit.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onRootBack,
      child: Scaffold(
        backgroundColor: context.sirati.background,
        body: MotionTabStack(
          currentIndex: _currentIndex,
          children: [
            _DashboardTab(onNavigate: _setTab),
            const MyCvsScreen(),
            const EducationScreen(),
            JobNewsScreen(isActive: _currentIndex == 3),
          ],
        ),
        bottomNavigationBar: _DashboardNavigationBar(
          currentIndex: _currentIndex,
          onChanged: _setTab,
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const _DashboardTab({required this.onNavigate});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Future<Map<String, dynamic>>? _future;
  bool? _loadedEnglish;

  void _ensureFuture(bool english) {
    if (_future == null || _loadedEnglish != english) {
      _loadedEnglish = english;
      _future = MobileContentService().dashboard(english);
    }
  }

  Future<void> _retry(bool english) async {
    final next = MobileContentService().dashboard(english, force: true);
    setState(() {
      _loadedEnglish = english;
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // Error UI is driven by FutureBuilder; pull-to-refresh still completes.
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    _ensureFuture(english);
    final onNavigate = widget.onNavigate;

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = constraints.maxWidth >= 1100
                  ? 920.0
                  : constraints.maxWidth >= 780
                      ? 760.0
                      : constraints.maxWidth;
              final horizontalPadding =
                  AppSpacing.pageGutter(constraints.maxWidth);

              final waiting =
                  snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData;

              late final Object stateKey;
              late final Widget body;

              if (waiting) {
                stateKey = 'loading';
                body = Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child:
                        DashboardSkeleton(horizontalPadding: horizontalPadding),
                  ),
                );
              } else if (snapshot.hasError && !snapshot.hasData) {
                stateKey = 'error';
                final message = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).displayMessage
                    : (english
                        ? 'Could not load dashboard.'
                        : 'تعذر تحميل الرئيسية.');
                body = AppErrorState(
                  english: english,
                  message: message,
                  onRetry: () => _retry(english),
                  exception: snapshot.error is ApiException
                      ? snapshot.error as ApiException
                      : null,
                );
              } else {
                stateKey = 'data';
                // Product marketing only when API omits action cards — never
                // invent stats, names, or activity (trust-critical).
                final product = _dashboardProductCopy(english);
                final data = snapshot.data ?? product;
                final profile = _map(data['profile']);
                final stats = _map(data['stats']);
                final primaryRaw = _map(data['primary_action']);
                final analysisRaw = _map(data['analysis_action']);
                final primary = _string(primaryRaw['title']).isNotEmpty
                    ? primaryRaw
                    : _map(product['primary_action']);
                final analysis = _string(analysisRaw['title']).isNotEmpty
                    ? analysisRaw
                    : _map(product['analysis_action']);
                final news = _map(data['latest_news']);
                final cachedName =
                    SessionCache.instance.user.value?.name.trim() ?? '';
                final name = _string(profile['name'], fallback: cachedName);
                final status = _string(profile['status'], fallback: '');
                final unread = data.containsKey('unread_notifications')
                    ? _int(data['unread_notifications'])
                    : SessionCache.instance.unreadCount;
                SessionCache.instance.unreadCount = unread;
                final hasNews = _string(news['title']).isNotEmpty;
                final offline = MobileContentService.isOfflinePayload(data);

                body = Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: RefreshIndicator(
                      color: context.sirati.primary,
                      onRefresh: () => _retry(english),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 18,
                            horizontalPadding, AppSpacing.scrollBottomNav),
                        children: [
                          MotionReveal(
                            order: 0,
                            child: ScreenHeader(
                              english: english,
                              title: AppLocale.greeting(name, context),
                              titleSize: 22,
                              avatarLabel: BidiText.avatarInitial(name),
                              status: status.isEmpty ? null : status,
                              unreadCount: unread,
                              onNotifications: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen()),
                                );
                                if (mounted) _retry(english);
                              },
                              onAvatarTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ),
                          if (offline) ...[
                            const SizedBox(height: AppSpacing.sm),
                            OfflineCacheBanner(
                              english: english,
                              surface: 'dashboard',
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          MotionReveal(
                            order: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _DashboardStatCard(
                                    label:
                                        english ? 'My CVs' : 'السير الذاتية',
                                    count: _countInt(stats['generated_cvs']),
                                    icon: Icons.description_outlined,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _DashboardStatCard(
                                    label: english ? 'Analyses' : 'التحليلات',
                                    count: _countInt(stats['analyses']),
                                    icon: Icons.analytics_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MotionReveal(
                            order: 2,
                            child: _DashboardActionCard(
                              title: LocaleFormat.mixedTitle(
                                _string(primary['title']),
                                english: english,
                              ),
                              subtitle: LocaleFormat.mixedBody(
                                _string(primary['subtitle']),
                                english: english,
                              ),
                              buttonLabel: _string(primary['button_label']),
                              backgroundColor: context.sirati.primary,
                              gradient: context.sirati.primaryGradient,
                              buttonColor: context.sirati.surface,
                              buttonTextColor: context.sirati.primary,
                              icon: Icons.description_outlined,
                              watermark: Icons.description_outlined,
                              onTap: () => _openCreateCv(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          MotionReveal(
                            order: 3,
                            child: _DashboardActionCard(
                              title: LocaleFormat.mixedTitle(
                                _string(analysis['title']),
                                english: english,
                              ),
                              subtitle: LocaleFormat.mixedBody(
                                _string(analysis['subtitle']),
                                english: english,
                              ),
                              buttonLabel: _string(analysis['button_label']),
                              backgroundColor: context.sirati.surface,
                              border: Border.all(color: context.sirati.border),
                              textColor: context.sirati.textPrimary,
                              subtitleColor: context.sirati.textSecondary,
                              iconColor: context.sirati.amber,
                              buttonColor: context.sirati.amberLight,
                              buttonTextColor: context.sirati.amber,
                              icon: Icons.analytics_outlined,
                              watermark: Icons.bar_chart_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CvAnalysisScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                english ? 'Recent Activity' : 'النشاط الأخير',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.sirati.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const HistoryScreen()),
                                ),
                                icon: const Icon(Icons.history_rounded, size: 16),
                                label: Text(english ? 'History' : 'السجل'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () => onNavigate(1),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                ),
                                child: Text(
                                  english ? 'View All' : 'عرض الكل',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (hasNews)
                            MotionReveal(
                              order: 4,
                              child: _NewsCard(
                                title: LocaleFormat.mixedTitle(
                                  _string(news['title']),
                                  english: english,
                                ),
                                subtitle: _string(news['subtitle']),
                              ),
                            )
                          else
                            MotionReveal(
                              order: 4,
                              child: AppEmptyState(
                                icon: Icons.history_toggle_off_rounded,
                                title: english
                                    ? 'No recent activity yet'
                                    : 'لا يوجد نشاط أخير بعد',
                                subtitle: english
                                    ? 'Create a CV or run an analysis to see updates here.'
                                    : 'أنشئ سيرة ذاتية أو نفّذ تحليلاً لتظهر التحديثات هنا.',
                                actionLabel: english ? 'Create CV' : 'إنشاء سيرة',
                                onAction: () => _openCreateCv(context),
                                scrollable: false,
                                topInsetFactor: 0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return MotionStateSwitcher(
                stateKey: stateKey,
                child: body,
              );
            },
          );
        },
      ),
    );
  }
}

void _openCreateCv(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CvGeneratorScreen()),
  );
}

/// Static product marketing for action cards only — no user-specific fields.
Map<String, dynamic> _dashboardProductCopy(bool english) {
  return {
    'primary_action': {
      'title': english
          ? 'Create ATS-Optimized CV'
          : 'أنشئ سيرة ذاتية وفق ${BidiText.isolateLtr('ATS')}',
      'subtitle': english
          ? 'Build your CV step by step and get a professional design that passes screening systems.'
          : 'ابنِ سيرتك خطوة بخطوة واحصل على تصميم احترافي يتجاوز أنظمة الفرز.',
      'button_label': english ? 'Start Now' : 'ابدأ الآن',
    },
    'analysis_action': {
      'title': english
          ? 'Analyze Your CV with ATS'
          : 'حلّل سيرتك الذاتية بـ ${BidiText.isolateLtr('ATS')}',
      'subtitle': english
          ? 'Upload your CV and discover its strengths and match with target jobs.'
          : 'ارفع سيرتك واعرف نقاط قوتها ومدى توافقها مع الوظائف المستهدفة.',
      'button_label': english ? 'Analyze Now' : 'تحليل الآن',
    },
  };
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return fallback;
  return text;
}

/// Real counts from API/cache only. Null → absent (em-dash UI).
int? _countInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

int _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

class _DashboardStatCard extends StatelessWidget {
  final String label;
  final int? count;
  final IconData icon;

  const _DashboardStatCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Design hierarchy: label (top) → large number → icon at start corner.
    // MergeSemantics → TalkBack: "My CVs, 12".
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: context.sirati.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.sirati.border),
            boxShadow: context.sirati.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd(),
              ),
              const SizedBox(height: 6),
              _CountUpValue(count: count),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: context.sirati.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: context.sirati.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts 0 → [count] once on first mount; later rebuilds show the final value.
class _CountUpValue extends StatefulWidget {
  final int? count;

  const _CountUpValue({required this.count});

  @override
  State<_CountUpValue> createState() => _CountUpValueState();
}

class _CountUpValueState extends State<_CountUpValue> {
  /// After the first count-up finishes, stay static across rebuilds/tab switches.
  bool _hasPlayed = false;

  /// Stable tween instance so parent rebuilds do not restart the animation.
  IntTween? _tween;

  String _format(int n, {required bool english}) =>
      AppFormat.digits(n.toString().padLeft(2, '0'), english: english);

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final count = widget.count;
    if (count == null) {
      return Text(
        '—',
        textAlign: TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.displayStat(context.sirati),
      );
    }

    final style = AppTextStyles.displayStat(context.sirati);
    if (MotionSettings.reduce(context) || _hasPlayed) {
      return Text(
        _format(count, english: english),
        textAlign: TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    _tween ??= IntTween(begin: 0, end: count);

    return TweenAnimationBuilder<int>(
      tween: _tween!,
      duration: const Duration(milliseconds: 600),
      curve: MotionCurves.enter,
      onEnd: () {
        if (mounted) setState(() => _hasPlayed = true);
      },
      builder: (context, value, _) {
        return Text(
          _format(value, english: english),
          textAlign: TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final Color? textColor;
  final Color? subtitleColor;
  final Color? iconColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final IconData icon;
  final IconData watermark;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.backgroundColor,
    this.gradient,
    this.border,
    this.textColor,
    this.subtitleColor,
    this.iconColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.icon,
    required this.watermark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkText = textColor != null || backgroundColor == context.sirati.amber;
    final ink = textColor ?? (darkText ? context.sirati.textPrimary : Colors.white);
    final subInk = subtitleColor ??
        (darkText
            ? context.sirati.textSecondary
            : Colors.white.withValues(alpha: .82));
    final resolvedIconColor = iconColor ??
        (darkText
            ? context.sirati.textPrimary
            : Colors.white.withValues(alpha: .94));

    return PressScale(
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: border,
          boxShadow: context.sirati.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            // minHeight preserves default card density; content grows with scale.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 174),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      end: -36,
                      bottom: -40,
                      child: Icon(
                        watermark,
                        size: 114,
                        color: ink.withValues(alpha: .10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: resolvedIconColor,
                            size: 22,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                              color: subInk,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      buttonLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: buttonTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    AppLocale.direction(context) ==
                                            TextDirection.rtl
                                        ? Icons.arrow_back_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: buttonTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NewsCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leadingIcon: Icons.schedule_rounded,
      title: title,
      subtitle: subtitle,
    );
  }
}

class _DashboardNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _DashboardNavigationBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    // Logical order: Home → My CVs → Education → Job News.
    // Ambient Directionality places Home at **start** (right in AR, left in EN).
    const items = [
      _NavItemData(
        index: 0,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        labelAr: 'الرئيسية',
        labelEn: 'Home',
      ),
      _NavItemData(
        index: 1,
        icon: Icons.description_outlined,
        selectedIcon: Icons.description_rounded,
        labelAr: 'سيراتي',
        labelEn: 'My CVs',
      ),
      _NavItemData(
        index: 2,
        icon: Icons.school_outlined,
        selectedIcon: Icons.school_rounded,
        labelAr: 'التعليم',
        labelEn: 'Education',
      ),
      _NavItemData(
        index: 3,
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
        labelAr: 'الوظائف',
        labelEn: 'Job News',
      ),
    ];

    return Material(
      color: context.sirati.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.sirati.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: onChanged,
            backgroundColor: context.sirati.surface,
            selectedItemColor: context.sirati.primaryDark,
            unselectedItemColor: context.sirati.textPrimary,
            selectedFontSize: 12.5,
            unselectedFontSize: 11.5,
            iconSize: 24,
            showUnselectedLabels: true,
            items: [
              for (final item in items)
                BottomNavigationBarItem(
                  icon: MotionNavIcon(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    selected: currentIndex == item.index,
                    selectedBackgroundColor: context.sirati.primaryLight,
                  ),
                  label: english ? item.labelEn : item.labelAr,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String labelAr;
  final String labelEn;

  const _NavItemData({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.labelAr,
    required this.labelEn,
  });
}
