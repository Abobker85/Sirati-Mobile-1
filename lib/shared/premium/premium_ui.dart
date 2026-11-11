import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/subscription_status.dart';
import 'package:sirati/shared/premium/premium_feature.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// The signed-in account's Premium status from the session cache.
SubscriptionStatus currentSubscription() =>
    SessionCache.instance.user.value?.subscriptionStatus ??
    const SubscriptionStatus.free();

/// After a free account used up part of a daily limit, re-reads `/auth/me`
/// so the Home card's "used today" counts stay true. Premium: no-op.
void refreshUsageIfFree(WidgetRef ref) {
  if (!currentSubscription().isFreeTier) return;
  unawaited(
      ref.read(authApiServiceProvider).me().then((_) {}, onError: (_) {}));
}

/// Opens the Premium page for [feature]. Completes true only when the same
/// account that opened it was free and is Premium on return, so the caller
/// may finish what they were doing (e.g. start the download they asked
/// for). A stale cache or a switch of account never resumes anything.
Future<bool> openPremium(
  BuildContext context, {
  PremiumFeature feature = PremiumFeature.general,
}) async {
  final before = SessionCache.instance.user.value;
  final wasPremium = before?.subscriptionStatus.isPremium ?? false;
  await Navigator.of(context).pushNamed(AppRoutes.premium, arguments: feature);
  final after = SessionCache.instance.user.value;
  return before != null &&
      after != null &&
      after.id == before.id &&
      !wasPremium &&
      after.subscriptionStatus.isPremium;
}

/// Bottom sheet for a Premium feature a free user tapped: what it does,
/// "See Premium plans", "Not now". Completes with whether the account is
/// Premium afterwards.
class PremiumPromptSheet extends StatelessWidget {
  const PremiumPromptSheet({super.key, required this.feature});

  final PremiumFeature feature;

  static const seePlansKey = ValueKey('premium-prompt-see-plans');
  static const notNowKey = ValueKey('premium-prompt-not-now');

  static Future<bool> show(BuildContext context, PremiumFeature feature) async {
    final seePlans = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => PremiumPromptSheet(feature: feature),
    );
    if (seePlans != true || !context.mounted) return false;
    return openPremium(context, feature: feature);
  }

  /// For a failed request: a 402 opens the prompt for the feature the
  /// server named and returns true (handled); anything else returns false.
  /// [onUnlocked] runs when the user comes back Premium, to finish the
  /// action that was refused.
  static bool handle(
    BuildContext context,
    Object error, {
    VoidCallback? onUnlocked,
  }) {
    if (error is! ApiException || !error.requiresSubscription) return false;
    show(context, PremiumFeature.fromServer(error.feature)).then((premium) {
      if (premium) onUnlocked?.call();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.amberLight,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Icon(Icons.workspace_premium_rounded,
                      size: 32, color: c.onWarningContainer),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Center(child: PremiumChip()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              feature.title(l),
              textAlign: TextAlign.center,
              style: AppTypography.of(context, AppTypography.titleLg),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              feature.body(l),
              textAlign: TextAlign.center,
              style: AppTypography.of(context, AppTypography.bodyMd,
                  color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: seePlansKey,
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(l.premiumGateJobMatchSeePlans),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: notNowKey,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.premiumGateNotNow),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small gold "Premium" pill with a crown: the one marker for every
/// Premium feature a free user sees.
class PremiumChip extends StatelessWidget {
  const PremiumChip({super.key, this.compact = false});

  /// Crown only, for tight rows (menus, icon buttons).
  final bool compact;

  static const chipKey = ValueKey('premium-chip');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final icon = Icon(Icons.workspace_premium_rounded,
        size: 14, color: c.onWarningContainer);
    return Semantics(
      label: l.premiumFeatureLabel,
      excludeSemantics: true,
      child: Container(
        key: chipKey,
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8, vertical: compact ? 4 : 3),
        decoration: BoxDecoration(
          color: c.amberLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: compact
            ? icon
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    l.premiumChipLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.onWarningContainer,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Rebuilds when the signed-in account (and so its Premium status) changes.
class SubscriptionBuilder extends StatelessWidget {
  const SubscriptionBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, SubscriptionStatus status)
      builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: SessionCache.instance.user,
      builder: (context, user, _) => builder(
        context,
        user?.subscriptionStatus ?? const SubscriptionStatus.free(),
      ),
    );
  }
}
