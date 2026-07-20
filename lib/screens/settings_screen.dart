import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../models/auth_session.dart';
import '../services/api_config.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../services/notification_engagement_service.dart';
import '../services/notification_service.dart';
import '../services/preference_store.dart';
import '../services/session_cache.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_controller.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/screen_header.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthApiService();
  final _prefs = const PreferenceStore();
  late Future<AuthUser?> _userFuture;
  bool _notificationsEnabled = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final server =
        await NotificationEngagementService.instance.fetchServerEnabled();
    final enabled = server ?? await _prefs.readNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<AuthUser?> _loadUser() async {
    final cached = SessionCache.instance.user.value;
    try {
      return await _auth.me() ?? cached;
    } on ApiException {
      if (cached != null) return cached;
      rethrow;
    }
  }

  void _refreshUser() {
    setState(() => _userFuture = _loadUser());
  }

  Future<void> _toggleLanguage() async {
    final english = AppLocale.isEnglish(context);
    await AppLocale.setLanguage(english ? 'ar' : 'en');
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await AppThemeController.setMode(mode);
  }

  String _themeModeLabel(ThemeMode mode, bool english) {
    return switch (mode) {
      ThemeMode.light => english ? 'Light' : 'فاتح',
      ThemeMode.dark => english ? 'Dark' : 'داكن',
      ThemeMode.system => english ? 'System' : 'النظام',
    };
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _prefs.saveNotificationsEnabled(value);
    try {
      // Persist server-side preference first so automation respects opt-out
      // even if FCM token unregister fails offline.
      await NotificationEngagementService.instance.syncPreferenceEnabled(value);
      if (value) {
        await NotificationService.instance.requestPermission();
        await NotificationService.instance.registerToken();
      } else {
        await NotificationService.instance.unregisterToken(optOut: true);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.warning(
        context,
        AppLocale.isEnglish(context)
            ? 'Could not update notification preference on server.'
            : 'تعذر تحديث تفضيل الإشعارات على الخادم.',
      );
    }
  }

  /// Opens the product tour without signing out. Finish/skip returns here.
  Future<void> _replayIntro() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: context.sirati.background,
          body: OnboardingScreen(
            onFinished: () {
              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final english = AppLocale.isEnglish(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(english ? 'Log out?' : 'تسجيل الخروج؟'),
        content: Text(
          english
              ? 'You will need to sign in again to access your CVs.'
              : 'ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى سيرتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(english ? 'Cancel' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.sirati.error),
            child: Text(english ? 'Log out' : 'تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    var serverFailed = false;
    try {
      await _auth.logout();
    } catch (_) {
      serverFailed = true;
      // Token is cleared in AuthApiService.finally
    }
    if (!mounted) return;

    if (serverFailed) {
      AppSnackBar.info(
        context,
        english
            ? 'Signed out locally. Server may still have an active session.'
            : 'تم تسجيل الخروج محلياً. قد تبقى جلسة على الخادم.',
      );
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(
        title: Text(english ? 'Settings' : 'الإعدادات'),
      ),
      body: FutureBuilder<AuthUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              SessionCache.instance.user.value == null;

          if (waiting) {
            return Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSkeletonScope(
                child: Column(
                  children: [
                    AppSkeleton(width: 72, height: 72, radius: 36),
                    SizedBox(height: AppSpacing.md),
                    AppSkeleton(height: 18),
                    SizedBox(height: AppSpacing.xs),
                    AppSkeleton(width: 180, height: 14),
                    SizedBox(height: AppSpacing.xl),
                    AppSkeleton(height: 56, radius: 16),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeleton(height: 56, radius: 16),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError &&
              snapshot.data == null &&
              SessionCache.instance.user.value == null) {
            return AppErrorState(
              english: english,
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).displayMessage
                  : (english
                      ? 'Could not load your profile.'
                      : 'تعذر تحميل ملفك الشخصي.'),
              onRetry: _refreshUser,
              exception: snapshot.error is ApiException
                  ? snapshot.error as ApiException
                  : null,
            );
          }

          final user = snapshot.data ?? SessionCache.instance.user.value;
          final name = user?.name ?? (english ? 'User' : 'مستخدم');
          final email = user?.email ?? '';
          final initial = BidiText.avatarInitial(name);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              // Profile card
              Material(
                color: context.sirati.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    _refreshUser();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.sirati.border),
                      boxShadow: context.sirati.softShadow,
                    ),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          label: initial,
                          size: 64,
                          english: english,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleLg(),
                              ),
                              if (email.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  email,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySm(),
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                              SizedBox(height: 6),
                              Text(
                                english ? 'View profile' : 'عرض الملف الشخصي',
                                style: AppTextStyles.labelMd().copyWith(
                                  color: context.sirati.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.sirati.textHint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.xl),
              _SectionLabel(english ? 'Account' : 'الحساب'),
              SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.person_outline_rounded,
                title: english ? 'Edit profile' : 'تعديل الملف الشخصي',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  _refreshUser();
                },
              ),
              SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.lock_outline_rounded,
                title: english ? 'Change password' : 'تغيير كلمة المرور',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),

              SizedBox(height: AppSpacing.xl),
              _SectionLabel(english ? 'Preferences' : 'التفضيلات'),
              SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.language_rounded,
                title: english ? 'Language' : 'اللغة',
                subtitle: english ? 'English' : 'العربية',
                showChevron: false,
                trailing: TextButton(
                  onPressed: _toggleLanguage,
                  child: Text(
                    english ? 'العربية' : 'English',
                    style: TextStyle(
                      color: context.sirati.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: _toggleLanguage,
              ),
              SizedBox(height: AppSpacing.sm),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) {
                  return AppListTile(
                    leadingIcon: Icons.palette_outlined,
                    title: english ? 'Appearance' : 'المظهر',
                    subtitle: _themeModeLabel(mode, english),
                    showChevron: false,
                    trailing: PopupMenuButton<ThemeMode>(
                      initialValue: mode,
                      tooltip: english ? 'Appearance' : 'المظهر',
                      onSelected: _setThemeMode,
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: ThemeMode.system,
                          child: Text(english ? 'System' : 'النظام'),
                        ),
                        PopupMenuItem(
                          value: ThemeMode.light,
                          child: Text(english ? 'Light' : 'فاتح'),
                        ),
                        PopupMenuItem(
                          value: ThemeMode.dark,
                          child: Text(english ? 'Dark' : 'داكن'),
                        ),
                      ],
                      child: Text(
                        english ? 'Change' : 'تغيير',
                        style: TextStyle(
                          color: context.sirati.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: null,
                  );
                },
              ),
              SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppThemeController.themeMode,
                  builder: (context, mode, _) {
                    final c = context.sirati;
                    Widget chip(ThemeMode m, String label) {
                      final selected = mode == m;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Material(
                            color: selected ? c.primaryLight : c.surfaceLow,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _setThemeMode(m),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? c.primary : c.border,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? c.primaryDark
                                        : c.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Row(
                      children: [
                        chip(ThemeMode.system, english ? 'System' : 'النظام'),
                        chip(ThemeMode.light, english ? 'Light' : 'فاتح'),
                        chip(ThemeMode.dark, english ? 'Dark' : 'داكن'),
                      ],
                    );
                  },
                ),
              ),
              AppListTile(
                leadingIcon: Icons.notifications_none_rounded,
                title: english ? 'Push notifications' : 'إشعارات الدفع',
                showChevron: false,
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  activeColor: context.sirati.primary,
                  onChanged: _toggleNotifications,
                ),
                onTap: () => _toggleNotifications(!_notificationsEnabled),
              ),

              SizedBox(height: AppSpacing.xl),
              _SectionLabel(english ? 'About' : 'حول'),
              SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.privacy_tip_outlined,
                title: english ? 'Privacy policy' : 'سياسة الخصوصية',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.auto_stories_outlined,
                title: english ? 'Replay app intro' : 'إعادة مقدمة التطبيق',
                subtitle: english
                    ? 'Walk through the product tour again'
                    : 'اعرض جولة التعريف بالمنتج مجدداً',
                onTap: _replayIntro,
              ),
              SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.info_outline_rounded,
                title: english ? 'App version' : 'إصدار التطبيق',
                subtitle: ApiConfig.appVersion,
                showChevron: false,
                onTap: null,
              ),

              SizedBox(height: AppSpacing.xl),
              _SectionLabel(english ? 'Danger zone' : 'منطقة الخطر'),
              SizedBox(height: AppSpacing.sm),
              Semantics(
                button: true,
                label: english ? 'Log out' : 'تسجيل الخروج',
                child: AppListTile(
                  leadingIcon: Icons.logout_rounded,
                  leadingBackground: context.sirati.errorLight,
                  leadingIconColor: context.sirati.error,
                  title: english ? 'Log out' : 'تسجيل الخروج',
                  titleColor: context.sirati.error,
                  showChevron: false,
                  onTap: _loggingOut ? null : _logout,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: english ? 'Delete account' : 'حذف الحساب',
                child: AppListTile(
                  leadingIcon: Icons.delete_forever_rounded,
                  leadingBackground: context.sirati.errorLight,
                  leadingIconColor: context.sirati.error,
                  title: english ? 'Delete account' : 'حذف الحساب',
                  titleColor: context.sirati.error,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DeleteAccountScreen()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.start,
      style: AppTextStyles.labelMd().copyWith(
        color: context.sirati.textHint,
        letterSpacing: 0.2,
      ),
    );
  }
}
