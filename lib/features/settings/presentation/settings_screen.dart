import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/notification_engagement_service.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/theme/app_theme_controller.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/screen_header.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/features/settings/presentation/delete_account_screen.dart';
import 'package:sirati/features/settings/presentation/privacy_policy_screen.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';

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

  String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
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
        AppLocalizations.of(context).notificationPrefUpdateFailed,
      );
    }
  }

  /// Opens email client addressed to official support (SIRATI-62).
  Future<void> _contactUs() async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: ApiConfig.supportEmail,
      queryParameters: {
        'subject': l10n.contactUsEmailSubject,
      },
    );
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        AppSnackBar.warning(
          context,
          l10n.contactUsFallback(ApiConfig.supportEmail),
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.warning(
        context,
        l10n.contactUsFallback(ApiConfig.supportEmail),
      );
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.sirati.error),
            child: Text(l10n.logOut),
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
    }
    if (!mounted) return;

    if (serverFailed) {
      AppSnackBar.info(
        context,
        l10n.signedOutLocally,
      );
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: FutureBuilder<AuthUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              SessionCache.instance.user.value == null;

          if (waiting) {
            return const Padding(
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
                  : l10n.couldNotLoadProfile,
              onRetry: _refreshUser,
              exception: snapshot.error is ApiException
                  ? snapshot.error as ApiException
                  : null,
            );
          }

          final user = snapshot.data ?? SessionCache.instance.user.value;
          final name = user?.name ?? l10n.userFallback;
          final email = user?.email ?? '';
          final initial = BidiText.avatarInitial(name);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              // Profile card (Display-only single view — SIRATI-61 & SIRATI-63)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.sirati.surface,
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLg(context.sirati),
                          ),
                          if (user?.displayJobTitle(english: english) != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              user!.displayJobTitle(english: english)!,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm(context.sirati).copyWith(
                                color: context.sirati.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              email,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm(context.sirati).copyWith(
                                color: context.sirati.textHint,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              _SectionLabel(l10n.accountSection),
              const SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.person_outline_rounded,
                title: l10n.editProfile,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  _refreshUser();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.lock_outline_rounded,
                title: l10n.changePassword,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              _SectionLabel(l10n.preferencesSection),
              const SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.language_rounded,
                title: l10n.language,
                subtitle: english ? l10n.languageEnglish : l10n.languageArabic,
                showChevron: false,
                trailing: TextButton(
                  onPressed: _toggleLanguage,
                  child: Text(
                    english ? l10n.languageArabic : l10n.languageEnglish,
                    style: TextStyle(
                      color: context.sirati.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: _toggleLanguage,
              ),
              const SizedBox(height: AppSpacing.sm),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) {
                  return AppListTile(
                    leadingIcon: Icons.palette_outlined,
                    title: l10n.appearance,
                    subtitle: _themeModeLabel(mode, l10n),
                    showChevron: false,
                    trailing: PopupMenuButton<ThemeMode>(
                      initialValue: mode,
                      tooltip: l10n.appearance,
                      onSelected: _setThemeMode,
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: ThemeMode.system,
                          child: Text(l10n.themeSystem),
                        ),
                        PopupMenuItem(
                          value: ThemeMode.light,
                          child: Text(l10n.themeLight),
                        ),
                        PopupMenuItem(
                          value: ThemeMode.dark,
                          child: Text(l10n.themeDark),
                        ),
                      ],
                      child: Text(
                        l10n.change,
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
              const SizedBox(height: AppSpacing.xs),
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
                        chip(ThemeMode.system, l10n.themeSystem),
                        chip(ThemeMode.light, l10n.themeLight),
                        chip(ThemeMode.dark, l10n.themeDark),
                      ],
                    );
                  },
                ),
              ),
              AppListTile(
                leadingIcon: Icons.notifications_none_rounded,
                title: l10n.pushNotifications,
                showChevron: false,
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return context.sirati.primary;
                    }
                    return null;
                  }),
                  onChanged: _toggleNotifications,
                ),
                onTap: () => _toggleNotifications(!_notificationsEnabled),
              ),

              const SizedBox(height: AppSpacing.xl),
              _SectionLabel(l10n.aboutSection),
              const SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.mail_outline_rounded,
                title: l10n.contactUs,
                subtitle: ApiConfig.supportEmail,
                onTap: _contactUs,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppListTile(
                leadingIcon: Icons.info_outline_rounded,
                title: l10n.appVersion,
                subtitle: ApiConfig.appVersion,
                showChevron: false,
                onTap: null,
              ),

              const SizedBox(height: AppSpacing.xl),
              _SectionLabel(l10n.dangerZone),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                button: true,
                label: l10n.logOut,
                child: AppListTile(
                  leadingIcon: Icons.logout_rounded,
                  leadingBackground: context.sirati.errorLight,
                  leadingIconColor: context.sirati.error,
                  title: l10n.logOut,
                  titleColor: context.sirati.error,
                  showChevron: false,
                  onTap: _loggingOut ? null : _logout,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: l10n.deleteAccount,
                child: AppListTile(
                  leadingIcon: Icons.delete_forever_rounded,
                  leadingBackground: context.sirati.errorLight,
                  leadingIconColor: context.sirati.error,
                  title: l10n.deleteAccount,
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
