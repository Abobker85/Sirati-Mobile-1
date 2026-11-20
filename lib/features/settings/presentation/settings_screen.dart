import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/features/settings/presentation/delete_account_screen.dart';
import 'package:sirati/features/settings/presentation/privacy_policy_screen.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';
import 'package:sirati/features/settings/presentation/settings/language_picker_sheet.dart';
import 'package:sirati/features/settings/presentation/settings/settings_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/subscription_status.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/theme/app_theme_controller.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/components/app_dialog.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const subscriptionKey = ValueKey('settings-subscription');

  /// The "Decorative motion" switch.
  static const decorativeMotionKey = ValueKey('settings-decorative-motion');
  static const manageSubscriptionKey = ValueKey('settings-manage-subscription');

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  /// Apple's own page for changing or cancelling App Store subscriptions.
  static final manageSubscriptionsUrl =
      Uri.parse('https://apps.apple.com/account/subscriptions');

  void _push(Widget screen) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ));
  }

  Future<void> _editProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (mounted) ref.invalidate(settingsUserProvider);
  }

  /// Plans and restore, or the active subscription, on the Premium screen.
  /// Re-reads the account afterwards so a purchase shows here at once.
  Future<void> _openPremium() async {
    await Navigator.of(context).pushNamed(AppRoutes.premium);
    if (mounted) ref.invalidate(settingsUserProvider);
  }

  Future<void> _manageSubscription() async {
    var launched = false;
    try {
      launched = await launchUrl(
        manageSubscriptionsUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!launched && mounted) {
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context).subscriptionManageHint,
      );
    }
  }

  /// What the subscription tile says under its title: plan and end date
  /// for Premium, the way to the plans otherwise.
  String _subscriptionSubtitle(SubscriptionStatus status) {
    final l10n = AppLocalizations.of(context);
    if (!status.isPremium) return l10n.premiumGateJobMatchSeePlans;
    final plan = switch (status.plan) {
      SubscriptionPlanKind.monthly => l10n.serverPlanMonthlyName,
      SubscriptionPlanKind.semiannual => l10n.serverPlanSixMonthsName,
      SubscriptionPlanKind.annual => l10n.serverPlanAnnualName,
      null => null,
    };
    final expires = status.expiresAt;
    final state = expires == null
        ? l10n.subscriptionActive
        : l10n.subscriptionActiveUntil(MaterialLocalizations.of(context)
            .formatMediumDate(expires.toLocal()));
    return plan == null ? state : '$plan · $state';
  }

  Future<void> _toggleNotifications(bool value) async {
    final ok = await ref
        .read(notificationPreferenceProvider.notifier)
        .setEnabled(value);
    if (!ok && mounted) {
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context).notificationPrefUpdateFailed,
      );
    }
  }

  /// Opens the email client addressed to support (SIRATI-62).
  Future<void> _contactUs() async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: ApiConfig.supportEmail,
      queryParameters: {'subject': l10n.contactUsEmailSubject},
    );
    var launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {}
    if (!launched && mounted) {
      AppSnackBar.warning(
        context,
        l10n.contactUsFallback(ApiConfig.supportEmail),
      );
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showSiratiDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle, textAlign: TextAlign.center),
        content: Text(l10n.logOutConfirmBody, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            // Same destructive ink as the sign-out row (AA when pressed).
            style: TextButton.styleFrom(
              foregroundColor: context.sirati.onErrorContainer,
            ),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      // Local cleanup completes before remote cleanup starts in the background.
      await ref.read(authApiServiceProvider).logout();
    } catch (error) {
      if (!mounted) return;
      if (error is LocalSessionCleanupException && error.tokenCleared) {
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).logOutPartial,
        );
      } else {
        setState(() => _loggingOut = false);
        AppSnackBar.error(context, l10n.logOutFailed);
        return;
      }
    }
    if (!mounted) return;
    unawaited(
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(settingsUserProvider);
    final notifications = ref.watch(notificationPreferenceProvider);
    final cachedUser = SessionCache.instance.user.value;

    Widget body;
    if (userAsync.isLoading && !userAsync.hasValue && cachedUser == null) {
      body = const Padding(
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
    } else if (userAsync.hasError &&
        !userAsync.hasValue &&
        cachedUser == null) {
      final error = userAsync.error;
      body = AppErrorState(
        english: english,
        message: error is ApiException
            ? error.displayMessage
            : l10n.couldNotLoadProfile,
        onRetry: () => ref.invalidate(settingsUserProvider),
        exception: error is ApiException ? error : null,
      );
    } else {
      final user = userAsync.value ?? cachedUser;
      final subscription =
          user?.subscriptionStatus ?? const SubscriptionStatus.free();
      final premium = subscription.isPremium;
      final c = context.sirati;
      // Switch rows line up with AppListTile rows inside a section.
      Widget switchRow({
        Key? key,
        required IconData icon,
        required String title,
        String? subtitle,
        required bool value,
        required ValueChanged<bool>? onChanged,
      }) =>
          SwitchListTile.adaptive(
            key: key,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppListSection.rowPadding,
            ),
            horizontalTitleGap: AppListTileMetrics.gap,
            minLeadingWidth: AppListTileMetrics.groupedIcon,
            secondary: AppListIcon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            value: value,
            onChanged: onChanged,
          );
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          ProfileSummaryCard(user: user),
          const SizedBox(height: AppSpacing.xl),
          AppListSection(
            header: l10n.subscriptionSection,
            children: [
              AppListTile(
                key: SettingsScreen.subscriptionKey,
                leadingIcon: Icons.workspace_premium_rounded,
                leadingBackground: premium ? c.amberLight : null,
                leadingIconColor: premium ? c.onWarningContainer : null,
                title: premium
                    ? l10n.premiumGateAppBar
                    : l10n.subscriptionFreePlan,
                subtitle: _subscriptionSubtitle(subscription),
                onTap: () => unawaited(_openPremium()),
              ),
              // Store subscriptions are changed and cancelled in Apple's
              // settings.
              if (premium &&
                  subscription.managedByStore &&
                  defaultTargetPlatform == TargetPlatform.iOS)
                AppListTile(
                  key: SettingsScreen.manageSubscriptionKey,
                  leadingIcon: Icons.manage_accounts_outlined,
                  title: l10n.subscriptionManage,
                  subtitle: l10n.subscriptionManageHint,
                  onTap: () => unawaited(_manageSubscription()),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppListSection(
            header: l10n.accountSection,
            children: [
              AppListTile(
                leadingIcon: Icons.person_outline_rounded,
                title: l10n.editProfile,
                onTap: () => unawaited(_editProfile()),
              ),
              // Google/Apple-only accounts have no current password to
              // change; "Forgot password" on the login screen can set one.
              if (user?.hasPassword ?? true)
                AppListTile(
                  leadingIcon: Icons.lock_outline_rounded,
                  title: l10n.changePassword,
                  onTap: () => _push(const ChangePasswordScreen()),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppListSection(
            header: l10n.preferencesSection,
            children: [
              AppListTile(
                leadingIcon: Icons.language_rounded,
                title: l10n.language,
                subtitle: currentLanguageName(),
                onTap: () => unawaited(showLanguagePicker(context)),
              ),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppListTile(
                      leadingIcon: Icons.palette_outlined,
                      title: l10n.appearance,
                      subtitle: switch (mode) {
                        ThemeMode.light => l10n.themeLight,
                        ThemeMode.dark => l10n.themeDark,
                        ThemeMode.system => l10n.themeSystem,
                      },
                      showChevron: false,
                      onTap: null,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppListSection.rowPadding,
                        0,
                        AppListSection.rowPadding,
                        AppSpacing.sm,
                      ),
                      child: ThemeModeSelector(
                        mode: mode,
                        onChanged: (m) =>
                            unawaited(AppThemeController.setMode(m)),
                      ),
                    ),
                  ],
                ),
              ),
              switchRow(
                icon: Icons.notifications_none_rounded,
                title: l10n.pushNotifications,
                value: notifications.value ?? true,
                // Wait for the persisted value before accepting changes.
                onChanged: notifications.hasValue
                    ? (value) => unawaited(_toggleNotifications(value))
                    : null,
              ),
              // Lets anyone stop the motion that plays by itself (shines,
              // floating pictures, glows); motion that answers a tap stays.
              ValueListenableBuilder<bool>(
                valueListenable: AmbientMotion.enabled,
                builder: (context, on, _) => switchRow(
                  key: SettingsScreen.decorativeMotionKey,
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.settingsDecorativeMotion,
                  subtitle: l10n.settingsDecorativeMotionHint,
                  value: on,
                  onChanged: (value) =>
                      unawaited(AmbientMotion.setEnabled(value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppListSection(
            header: l10n.aboutSection,
            children: [
              AppListTile(
                leadingIcon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => _push(const PrivacyPolicyScreen()),
              ),
              AppListTile(
                leadingIcon: Icons.mail_outline_rounded,
                title: l10n.contactUs,
                subtitle: ApiConfig.supportEmail,
                onTap: () => unawaited(_contactUs()),
              ),
              AppListTile(
                leadingIcon: Icons.info_outline_rounded,
                title: l10n.appVersion,
                subtitle: ApiConfig.appVersion,
                showChevron: false,
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Destructive titles use onErrorContainer: error itself drops
          // under 4.5:1 on the pressed light card.
          AppListSection(
            header: l10n.dangerZone,
            children: [
              AppListTile(
                leadingIcon: Icons.logout_rounded,
                leadingBackground: c.errorLight,
                leadingIconColor: c.onErrorContainer,
                title: l10n.logOut,
                titleColor: c.onErrorContainer,
                showChevron: false,
                onTap: _loggingOut ? null : () => unawaited(_logout()),
              ),
              AppListTile(
                leadingIcon: Icons.delete_forever_rounded,
                leadingBackground: c.errorLight,
                leadingIconColor: c.onErrorContainer,
                title: l10n.deleteAccount,
                titleColor: c.onErrorContainer,
                onTap: () => _push(const DeleteAccountScreen()),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: context.sirati.groupedBackground,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: context.sirati.groupedBackground,
        surfaceTintColor: context.sirati.groupedBackground,
        scrolledUnderElevation: 0,
      ),
      body: body,
    );
  }
}
