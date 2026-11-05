import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/dashboard/application/premium_gate_controller.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/services/session_user_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Apple's standard licence agreement, linked as the paywall's Terms of Use.
const appleStandardEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// Premium gate: benefits, server plans, App Store purchase and restore.
///
/// When this build cannot sell ([StorePurchases.isAvailable] is false) the
/// plans are informational. Access is only ever granted by the server
/// (`/auth/me` → `subscription.is_subscribed`), which learns about App Store
/// purchases from the RevenueCat webhook.
class PremiumGateScreen extends ConsumerStatefulWidget {
  const PremiumGateScreen({
    super.key,
    this.confirmDelay = const Duration(seconds: 2),
    this.confirmAttempts = 4,
  });

  /// Pause between server checks after a purchase (the webhook is async).
  final Duration confirmDelay;
  final int confirmAttempts;

  static const refreshKey = ValueKey('premium-refresh');
  static const notNowKey = ValueKey('premium-not-now');
  static const privacyKey = ValueKey('premium-privacy');
  static const termsKey = ValueKey('premium-terms');
  static const restoreKey = ValueKey('premium-restore');
  static const buyKey = ValueKey('premium-buy');
  static const storeRetryKey = ValueKey('premium-store-retry');
  static const successKey = ValueKey('premium-success');
  static const retryKey = ValueKey('premium-plans-retry');
  static const continueKey = ValueKey('premium-continue');
  static const checkAgainKey = ValueKey('premium-check-again');
  static const supportKey = ValueKey('premium-support');
  static const noticeKey = ValueKey('premium-notice');
  static Key planKey(String key) => ValueKey('premium-plan-$key');

  @override
  ConsumerState<PremiumGateScreen> createState() => _PremiumGateScreenState();
}

enum _GateNotice {
  notFound,
  refreshFailed,
  purchaseFailed,
  purchasePending,
  otherAccount,
}

class _PremiumGateScreenState extends ConsumerState<PremiumGateScreen> {
  bool _refreshing = false;
  bool _purchasing = false;
  bool? _activated;
  _GateNotice? _notice;
  String? _selectedPlan;

  /// Set after a completed purchase or restore; true once the server agrees.
  bool? _successConfirmed;

  /// The account a purchase, restore or confirmation runs for. Every result
  /// is applied only while that account is still the one signed in; a
  /// session change resets the flow.
  int? _flowUser;

  bool get _busy => _refreshing || _purchasing;

  /// Re-reads access for the account signed in now. A reply that arrives
  /// after the session changed belongs to another account and is dropped.
  Future<void> _refresh() async {
    if (_busy) return;
    final askedFor = SessionCache.instance.user.value?.id;
    setState(() {
      _refreshing = true;
      _notice = null;
    });
    _GateNotice? notice;
    var active = false;
    var stale = false;
    try {
      final user = await ref.read(authApiServiceProvider).me();
      stale = !_refreshStillCurrent(askedFor, user?.id);
      active = isSubscriptionActive(user?.subscription);
      if (!active) notice = _GateNotice.notFound;
    } catch (_) {
      stale = !_refreshStillCurrent(askedFor, null);
      notice = _GateNotice.refreshFailed;
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      if (stale) return;
      _activated = active;
      _notice = notice;
    });
  }

  /// Whether a refresh answer may be shown: the session has not moved to
  /// another account (or signed out) since [askedFor] asked, and the answer
  /// is not for an account other than the one signed in now. A session that
  /// was not known yet when the refresh started does not count as a change.
  bool _refreshStillCurrent(int? askedFor, int? answeredFor) {
    final now = SessionCache.instance.user.value?.id;
    if (askedFor != null && now != askedFor) return false;
    if (answeredFor != null && now != null && now != answeredFor) return false;
    return true;
  }

  /// True while [userId] is still the account signed in on this device.
  bool _stillSignedIn(int userId) =>
      mounted && SessionCache.instance.user.value?.id == userId;

  /// Results of a flow for an account that is no longer current are dropped.
  bool _flowIsCurrent(int userId) =>
      _flowUser == userId && _stillSignedIn(userId);

  /// The signed-in account, confirmed by the server and by the session the
  /// app holds now (a reply for a previous account does not count).
  Future<int?> _confirmedUserId() async {
    final id = (await ref.read(authApiServiceProvider).me())?.id;
    return id != null && _stillSignedIn(id) ? id : null;
  }

  void _resetFlow() {
    setState(() {
      _flowUser = null;
      _successConfirmed = null;
      _purchasing = false;
      _refreshing = false;
      _activated = null;
      _notice = null;
    });
  }

  /// Asks the server to re-read [userId] from RevenueCat (repairs a lost
  /// webhook), then polls until the server reports access for that same
  /// account. Any other account's answer never confirms this flow.
  Future<bool> _serverConfirms(int userId) async {
    if (_flowIsCurrent(userId)) {
      try {
        await ref.read(subscriptionPlansRepositoryProvider).syncWithStore();
      } catch (_) {
        // Polling below still sees a webhook that arrives on its own.
      }
    }
    for (var attempt = 0; attempt < widget.confirmAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(widget.confirmDelay);
      if (!_flowIsCurrent(userId)) return false;
      try {
        final user = await ref.read(authApiServiceProvider).me();
        if (user?.id != userId || !_flowIsCurrent(userId)) return false;
        if (isSubscriptionActive(user?.subscription)) return true;
      } catch (_) {
        // Keep polling; the view says when the account lags.
      }
    }
    return false;
  }

  Future<void> _showSuccess(int userId) async {
    final confirmed = await _serverConfirms(userId);
    if (!mounted || !_flowIsCurrent(userId)) return;
    setState(() {
      _purchasing = false;
      _refreshing = false;
      _successConfirmed = confirmed;
    });
  }

  /// Re-runs the server check from the "payment received" view.
  Future<void> _checkAgain() async {
    final userId = _flowUser;
    if (_busy || userId == null) return;
    setState(() => _refreshing = true);
    await _showSuccess(userId);
  }

  Future<void> _buy(StoreCatalog catalog, String planKey) async {
    if (_busy) return;
    setState(() {
      _purchasing = true;
      _notice = null;
    });
    StorePurchaseOutcome outcome;
    int? userId;
    try {
      // The catalogue may belong to an account that has since signed out:
      // buy only for the account signed in now, and only while it stays so.
      userId = await _confirmedUserId();
      if (userId == null || userId != catalog.userId) {
        ref.invalidate(storeCatalogProvider);
        outcome = const StorePurchaseFailed();
      } else {
        final buyer = userId;
        _flowUser = buyer;
        outcome = await ref.read(storePurchasesProvider).purchase(
              userId: buyer,
              planKey: planKey,
              isCurrent: () => _flowIsCurrent(buyer),
            );
      }
    } catch (_) {
      outcome = const StorePurchaseFailed();
    }
    if (!mounted) return;
    if (userId != null && !_stillSignedIn(userId)) {
      // The session changed meanwhile: drop this account's result.
      _resetFlow();
      return;
    }
    if (outcome is StorePurchaseCompleted && userId != null) {
      return _showSuccess(userId);
    }
    setState(() {
      _purchasing = false;
      _flowUser = null;
      _notice = switch (outcome) {
        StorePurchasePending() => _GateNotice.purchasePending,
        StorePurchaseOtherAccount() => _GateNotice.otherAccount,
        StorePurchaseFailed() => _GateNotice.purchaseFailed,
        _ => null,
      };
    });
  }

  /// Needs only the signed-in account, not the sales catalogue, so a
  /// subscriber can recover access while prices fail to load.
  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _refreshing = true;
      _notice = null;
    });
    StoreRestoreOutcome? outcome;
    int? userId;
    try {
      userId = await _confirmedUserId();
      if (userId != null) {
        final owner = userId;
        _flowUser = owner;
        outcome = await ref.read(storePurchasesProvider).restore(
              userId: owner,
              isCurrent: () => _flowIsCurrent(owner),
            );
      }
    } catch (_) {
      outcome = null;
    }
    if (!mounted) return;
    if (userId != null && !_stillSignedIn(userId)) {
      // The session changed meanwhile: drop this account's result.
      _resetFlow();
      return;
    }
    if (outcome == StoreRestoreOutcome.active && userId != null) {
      return _showSuccess(userId);
    }
    setState(() {
      _refreshing = false;
      _flowUser = null;
      _notice = switch (outcome) {
        StoreRestoreOutcome.none => _GateNotice.notFound,
        StoreRestoreOutcome.otherAccount => _GateNotice.otherAccount,
        _ => _GateNotice.refreshFailed,
      };
    });
  }

  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(sessionUserIdProvider, (previous, next) {
      final flowUser = _flowUser;
      if (flowUser != null) {
        if (next != flowUser) _resetFlow();
      } else if (next != previous && (_activated != null || _notice != null)) {
        // A refresh result shown for the previous account is not this one's.
        _resetFlow();
      }
    });
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final offer = ref.watch(subscriptionOfferProvider);
    final storeAvailable = ref.watch(storePurchasesProvider).isAvailable;
    final active = _activated ?? (offer.value?.subscribed ?? false);
    const padding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xxl,
    );

    final List<Widget> children;
    if (_successConfirmed != null) {
      children = [
        _SuccessView(
          key: PremiumGateScreen.successKey,
          confirmed: _successConfirmed!,
          checking: _refreshing,
          onCheckAgain: _checkAgain,
          onContinue: _leave,
        ),
      ];
    } else if (storeAvailable) {
      children = _storeChildren(context, offer, active);
    } else {
      children = _informationalChildren(context, offer, active);
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(l.premiumGateAppBar)),
      body: SafeArea(
        top: false,
        child: ListView(padding: padding, children: children),
      ),
    );
  }

  /// This build cannot sell: plans are information plus a server refresh.
  List<Widget> _informationalChildren(
    BuildContext context,
    AsyncValue<SubscriptionOffer> offer,
    bool active,
  ) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return [
      const _Hero(),
      const SizedBox(height: AppSpacing.lg),
      if (active) ...[
        _ActiveCard(onContinue: _leave),
        const SizedBox(height: AppSpacing.lg),
      ],
      const _Benefits(),
      const SizedBox(height: AppSpacing.md),
      _Notice(
        tone: _Tone.info,
        message: '${l.premiumGateAvailabilityNote}\n${l.premiumGatePriceNote}',
      ),
      if (!active) ...[
        const SizedBox(height: AppSpacing.lg),
        _plans(context, offer),
        if (_notice != null) ...[
          const SizedBox(height: AppSpacing.md),
          _noticeFor(context, _notice!),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
      ElevatedButton(
        key: PremiumGateScreen.refreshKey,
        style: ElevatedButton.styleFrom(
          animationDuration: Duration.zero,
          disabledBackgroundColor: c.surface,
          disabledForegroundColor: c.textSecondary,
        ),
        onPressed: _refreshing ? null : _refresh,
        child: _refreshing
            ? _BusyLabel(l.premiumGateRefreshing)
            : Text(l.premiumGateRefresh, textAlign: TextAlign.center),
      ),
      const SizedBox(height: AppSpacing.xs),
      Center(
        child: TextButton(
          key: PremiumGateScreen.notNowKey,
          onPressed: _leave,
          child: Text(l.premiumGateNotNow),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Footer(
        onPrivacy: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
      ),
    ];
  }

  /// This build sells through the App Store.
  List<Widget> _storeChildren(
    BuildContext context,
    AsyncValue<SubscriptionOffer> offer,
    bool active,
  ) {
    final l = AppLocalizations.of(context);
    final catalog = ref.watch(storeCatalogProvider);
    final offerValue = offer.value;
    return [
      const _Hero(),
      const SizedBox(height: AppSpacing.lg),
      if (active) ...[
        _ActiveCard(onContinue: _leave),
        const SizedBox(height: AppSpacing.lg),
      ],
      const _Benefits(),
      if (!active) ...[
        const SizedBox(height: AppSpacing.lg),
        if (offer.hasError || (offerValue != null && offerValue.plans.isEmpty))
          _plans(context, offer)
        else
          _storePlans(context, offerValue, catalog),
      ],
      // Outside the plans: Restore stays available to an active account,
      // and its result must be visible there too.
      if (_notice != null) ...[
        const SizedBox(height: AppSpacing.md),
        _noticeFor(context, _notice!),
      ],
      const SizedBox(height: AppSpacing.xs),
      Center(
        child: TextButton(
          key: PremiumGateScreen.notNowKey,
          style: _footerButtonStyle(context),
          onPressed: _busy ? null : _leave,
          child: Text(l.premiumGateNotNow),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Footer(
        onPrivacy: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
        onTerms: () => launchSafeExternalUrl(appleStandardEulaUrl),
        onRestore: _busy ? null : _restore,
      ),
    ];
  }

  Widget _storePlans(
    BuildContext context,
    SubscriptionOffer? offer,
    AsyncValue<StoreCatalog?> catalog,
  ) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final english = AppLocale.isEnglish(context);
    final title = Text(
      l.premiumGateChoosePlan,
      style: AppTypography.of(context, AppTypography.titleLg),
    );
    final data = catalog.value;

    if (offer == null || (catalog.isLoading && !catalog.hasValue)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final plans = [
      for (final plan in offer.plans)
        if (data?.offers[plan.key] != null) plan,
    ];
    if (catalog.hasError || data == null || plans.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          _Notice(
            tone: _Tone.error,
            message: l.premiumGateStorePricesFailed,
            action: TextButton(
              key: PremiumGateScreen.storeRetryKey,
              onPressed: () => ref.invalidate(storeCatalogProvider),
              style: TextButton.styleFrom(foregroundColor: c.onErrorContainer),
              child: Text(l.premiumGateRetry),
            ),
          ),
        ],
      );
    }

    String keyOr(String? wanted, String fallback) =>
        plans.any((p) => p.key == wanted) ? wanted! : fallback;
    final selectedKey =
        keyOr(_selectedPlan, keyOr(offer.defaultPlan?.key, plans.first.key));
    final selectedPlan = plans.firstWhere((p) => p.key == selectedKey);
    final selectedOffer = data.offers[selectedKey]!;
    final trial = selectedOffer.trial;
    final period = _periodLabel(l, selectedPlan.periodMonths);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        const SizedBox(height: AppSpacing.sm),
        for (final plan in plans) ...[
          _PlanCard(
            key: PremiumGateScreen.planKey(plan.key),
            plan: plan,
            english: english,
            storePrice: data.offers[plan.key]!.priceString,
            selected: plan.key == selectedKey,
            onSelect: _busy
                ? null
                : () => setState(() {
                      _selectedPlan = plan.key;
                      _notice = null;
                    }),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (trial != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.premiumGateTrial(_trialDuration(l, trial)),
            textAlign: TextAlign.center,
            style: AppTypography.of(context, AppTypography.titleSm,
                color: c.primaryInk),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          key: PremiumGateScreen.buyKey,
          style: ElevatedButton.styleFrom(
            animationDuration: Duration.zero,
            disabledBackgroundColor: c.surface,
            disabledForegroundColor: c.textSecondary,
          ),
          onPressed: _busy ? null : () => _buy(data, selectedKey),
          child: _purchasing
              ? _BusyLabel(l.premiumGatePurchasing)
              : Text(
                  trial != null
                      ? l.premiumGateStartTrial
                      : l.premiumGateSubscribe,
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          trial != null
              ? l.premiumGateRenewNoticeTrial(selectedOffer.priceString, period)
              : l.premiumGateRenewNotice(selectedOffer.priceString, period),
          textAlign: TextAlign.center,
          style: AppTypography.of(context, AppTypography.bodySm,
              color: c.textSecondary),
        ),
      ],
    );
  }

  Widget _plans(BuildContext context, AsyncValue<SubscriptionOffer> offer) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final english = AppLocale.isEnglish(context);
    final title = Text(
      l.premiumGatePlansTitle,
      style: AppTypography.of(context, AppTypography.titleLg),
    );

    if (offer.isLoading && !offer.hasValue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final data = offer.value;
    if (offer.hasError || data == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          _Notice(
            tone: _Tone.error,
            message: l.premiumGatePlansFailed,
            action: TextButton(
              key: PremiumGateScreen.retryKey,
              onPressed: () => ref.invalidate(subscriptionOfferProvider),
              style: TextButton.styleFrom(foregroundColor: c.onErrorContainer),
              child: Text(l.premiumGateRetry),
            ),
          ),
        ],
      );
    }

    if (data.plans.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          _Notice(tone: _Tone.info, message: l.premiumGateNoPlans),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        const SizedBox(height: AppSpacing.sm),
        for (final plan in data.plans) ...[
          _PlanCard(
            key: PremiumGateScreen.planKey(plan.key),
            plan: plan,
            english: english,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _noticeFor(BuildContext context, _GateNotice notice) {
    final l = AppLocalizations.of(context);
    return KeyedSubtree(
      key: PremiumGateScreen.noticeKey,
      child: switch (notice) {
        _GateNotice.notFound => _Notice(
            tone: _Tone.warning,
            message: l.premiumGateNotFound,
          ),
        _GateNotice.refreshFailed => _Notice(
            tone: _Tone.error,
            message: l.premiumGateRefreshFailed,
          ),
        _GateNotice.purchaseFailed => _Notice(
            tone: _Tone.error,
            message: l.premiumGatePurchaseFailed,
          ),
        _GateNotice.purchasePending => _Notice(
            tone: _Tone.warning,
            message: l.premiumGatePurchasePending,
          ),
        _GateNotice.otherAccount => _Notice(
            tone: _Tone.warning,
            message: l.premiumGateOtherAccount(ApiConfig.supportEmail),
            action: TextButton(
              key: PremiumGateScreen.supportKey,
              style: TextButton.styleFrom(
                  foregroundColor: context.sirati.onWarningContainer),
              onPressed: () => launchMailto(
                ApiConfig.supportEmail,
                subject: l.premiumGateSupportSubject,
              ),
              child: Text(l.premiumGateContactSupport),
            ),
          ),
      },
    );
  }
}

/// Formats a price with Latin digits: whole amounts without decimals,
/// anything else with exactly two.
String formatPlanPrice(double value) {
  final cents = (value * 100).round();
  if (cents % 100 == 0) return '${cents ~/ 100}';
  return (cents / 100).toStringAsFixed(2);
}

String _currencyLabel(AppLocalizations l, String code) =>
    code.toUpperCase() == 'SAR' ? l.premiumGateCurrencySar : code;

String _periodLabel(AppLocalizations l, int months) =>
    months == 12 ? l.premiumGatePeriodYear : l.premiumGatePeriod(months);

/// The trial length in the store's own unit (a month is never "30 days").
String _trialDuration(AppLocalizations l, StoreTrial trial) =>
    switch (trial.unit) {
      StoreTrialUnit.day => l.premiumGateTrialDays(trial.count),
      StoreTrialUnit.week => l.premiumGateTrialWeeks(trial.count),
      StoreTrialUnit.month => l.premiumGateTrialMonths(trial.count),
      StoreTrialUnit.year => l.premiumGateTrialYears(trial.count),
    };

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [c.brandSurface, c.brandSurfaceDeep],
        ),
        borderRadius: AppRadius.xlAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: c.onBrandSurface,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.premiumGateHeroTitle,
              style: AppTypography.of(
                context,
                AppTypography.headlineLg,
                color: c.onBrandSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.premiumGateHeroBody,
              style: AppTypography.of(
                context,
                AppTypography.bodyMd,
                color: c.onBrandSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <(IconData, String, String)>[
      (
        Icons.picture_as_pdf_outlined,
        l.premiumGateBenefitPdf,
        l.premiumGateBenefitPdfBody,
      ),
      (
        Icons.auto_awesome_outlined,
        l.premiumGateBenefitAi,
        l.premiumGateBenefitAiBody,
      ),
      (
        Icons.fact_check_outlined,
        l.premiumGateBenefitAts,
        l.premiumGateBenefitAtsBody,
      ),
      (
        Icons.work_outline_rounded,
        l.premiumGateBenefitJobMatch,
        l.premiumGateBenefitJobMatchBody,
      ),
      (
        Icons.all_inclusive_rounded,
        l.premiumGateBenefitLimits,
        l.premiumGateBenefitLimitsBody,
      ),
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.premiumGateBenefitsTitle,
            style: AppTypography.of(context, AppTypography.titleLg),
          ),
          for (final (icon, title, body) in items) ...[
            const SizedBox(height: AppSpacing.md),
            _BenefitRow(icon: icon, title: title, body: body),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon, size: 20, color: c.primaryInk),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.of(context, AppTypography.titleSm)),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                body,
                style: AppTypography.of(
                  context,
                  AppTypography.bodySm,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.plan,
    required this.english,
    this.storePrice,
    this.selected,
    this.onSelect,
  });

  final SubscriptionPlan plan;
  final bool english;

  /// The App Store price; when set the card is a purchase choice.
  final String? storePrice;

  /// Null for an informational card, else whether this plan is chosen.
  final bool? selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final currency = _currencyLabel(l, plan.currency);
    final badge = plan.badge(english: english);
    final period = _periodLabel(l, plan.periodMonths);
    final price =
        storePrice ?? l.premiumGatePrice(formatPlanPrice(plan.price), currency);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            Text(plan.name(english: english),
                style: AppTypography.of(context, AppTypography.titleMd)),
            if (badge != null) _Badge(badge),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '$price · $period',
          style: AppTypography.of(context, AppTypography.titleSm),
        ),
        // The per-month figure is in the catalogue currency, which may differ
        // from the store currency, so only informational cards show it.
        if (storePrice == null &&
            plan.pricePerMonth != null &&
            plan.periodMonths > 1) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l.premiumGatePerMonth(
                formatPlanPrice(plan.pricePerMonth!), currency),
            style: AppTypography.of(context, AppTypography.bodySm,
                color: c.textSecondary),
          ),
        ],
      ],
    );
    final isSelected = selected;
    if (isSelected == null) return _Card(child: details);
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: isSelected ? c.primary : c.textSecondary,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? c.primary : c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        child: Text(
          label,
          style: AppTypography.of(
            context,
            AppTypography.labelSm,
            color: c.primaryInk,
          ),
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.successLight,
        borderRadius: AppRadius.lgAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_rounded, color: c.onSuccessContainer),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l.premiumGateActiveTitle,
                    style: AppTypography.of(
                      context,
                      AppTypography.titleMd,
                      color: c.onSuccessContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.premiumGateActiveBody,
              style: AppTypography.of(
                context,
                AppTypography.bodySm,
                color: c.onSuccessContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: PremiumGateScreen.continueKey,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.onSuccessContainer,
                side: BorderSide(color: c.onSuccessContainer),
              ),
              onPressed: onContinue,
              child: Text(l.premiumGateContinue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onPrivacy, this.onTerms, this.onRestore});

  final VoidCallback onPrivacy;

  /// Set only when this build sells (Apple requires both links then).
  final VoidCallback? onTerms;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final selling = onTerms != null;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (selling) ...[
          TextButton(
            key: PremiumGateScreen.restoreKey,
            style: _footerButtonStyle(context),
            onPressed: onRestore,
            child: Text(l.premiumGateRestore),
          ),
          TextButton(
            key: PremiumGateScreen.termsKey,
            onPressed: onTerms,
            child: Text(l.premiumGateTerms),
          ),
        ] else
          Icon(Icons.lock_outline_rounded, size: 16, color: c.textSecondary),
        TextButton(
          key: PremiumGateScreen.privacyKey,
          onPressed: onPrivacy,
          child: Text(l.premiumGatePrivacy),
        ),
      ],
    );
  }
}

/// Disabled while a purchase runs, yet still legible (AA contrast).
ButtonStyle _footerButtonStyle(BuildContext context) =>
    TextButton.styleFrom(disabledForegroundColor: context.sirati.textSecondary);

class _BusyLabel extends StatelessWidget {
  const _BusyLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.primaryInk),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label)),
      ],
    );
  }
}

/// Shown after the store completed a purchase or restored one. Claims access
/// only once the server confirmed it; until then it says the payment was
/// received and offers a server re-check.
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.confirmed,
    required this.checking,
    required this.onCheckAgain,
    required this.onContinue,
  });

  /// False when the server has not seen the webhook yet.
  final bool confirmed;
  final bool checking;
  final VoidCallback onCheckAgain;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(
                confirmed ? Icons.check_rounded : Icons.hourglass_top_rounded,
                size: 48,
                color: c.primaryInk,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          confirmed ? l.premiumGateSuccessTitle : l.premiumGateSyncingTitle,
          textAlign: TextAlign.center,
          style: AppTypography.of(context, AppTypography.titleLg),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          confirmed ? l.premiumGateSuccessBody : l.premiumGateSuccessSyncing,
          textAlign: TextAlign.center,
          style: AppTypography.of(context, AppTypography.bodyMd,
              color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (confirmed)
          ElevatedButton(
            key: PremiumGateScreen.continueKey,
            onPressed: onContinue,
            child: Text(l.premiumGateContinue),
          )
        else ...[
          ElevatedButton(
            key: PremiumGateScreen.checkAgainKey,
            style: ElevatedButton.styleFrom(
              animationDuration: Duration.zero,
              disabledBackgroundColor: c.surface,
              disabledForegroundColor: c.textSecondary,
            ),
            onPressed: checking ? null : onCheckAgain,
            child: checking
                ? _BusyLabel(l.premiumGateRefreshing)
                : Text(l.premiumGateCheckAgain),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              key: PremiumGateScreen.continueKey,
              style: _footerButtonStyle(context),
              onPressed: checking ? null : onContinue,
              child: Text(l.premiumGateContinue),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.textSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

enum _Tone { info, warning, error }

class _Notice extends StatelessWidget {
  const _Notice({required this.tone, required this.message, this.action});

  final _Tone tone;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final (bg, fg, icon) = switch (tone) {
      _Tone.info => (c.infoLight, c.onInfoContainer, Icons.info_outline),
      _Tone.warning => (
          c.warningLight,
          c.onWarningContainer,
          Icons.hourglass_empty_rounded,
        ),
      _Tone.error => (c.errorLight, c.onErrorContainer, Icons.error_outline),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTypography.of(
                      context,
                      AppTypography.bodySm,
                      color: fg,
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
