import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/application/premium_gate_controller.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Premium gate: benefits, server plans and a server-verified refresh.
///
/// There is no in-app purchase integration yet, so Subscribe explains that
/// instead of starting a payment. Access is only ever granted by the server
/// (`/auth/me` → `subscription.is_subscribed`).
class PremiumGateScreen extends ConsumerStatefulWidget {
  const PremiumGateScreen({super.key});

  static const subscribeKey = ValueKey('premium-subscribe');
  static const refreshKey = ValueKey('premium-refresh');
  static const notNowKey = ValueKey('premium-not-now');
  static const privacyKey = ValueKey('premium-privacy');
  static const retryKey = ValueKey('premium-plans-retry');
  static const continueKey = ValueKey('premium-continue');
  static const noticeKey = ValueKey('premium-notice');
  static Key planKey(String key) => ValueKey('premium-plan-$key');

  @override
  ConsumerState<PremiumGateScreen> createState() => _PremiumGateScreenState();
}

enum _GateNotice { purchaseUnavailable, notFound, refreshFailed }

class _PremiumGateScreenState extends ConsumerState<PremiumGateScreen> {
  String? _selectedPlan;
  bool _refreshing = false;
  bool _activated = false;
  _GateNotice? _notice;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _notice = null;
    });
    _GateNotice? notice;
    var active = false;
    try {
      final user = await ref.read(authApiServiceProvider).me();
      active = isSubscriptionActive(user?.subscription);
      if (!active) notice = _GateNotice.notFound;
    } catch (_) {
      notice = _GateNotice.refreshFailed;
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _activated = active;
      _notice = notice;
    });
  }

  void _subscribe() =>
      setState(() => _notice = _GateNotice.purchaseUnavailable);

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
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final offer = ref.watch(subscriptionOfferProvider);
    final active = _activated || (offer.value?.subscribed ?? false);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(l.premiumGateAppBar)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const _Hero(),
            const SizedBox(height: AppSpacing.lg),
            if (active) ...[
              _ActiveCard(onContinue: _leave),
              const SizedBox(height: AppSpacing.lg),
            ],
            const _Benefits(),
            if (!active) ...[
              const SizedBox(height: AppSpacing.lg),
              _plans(context, offer),
              if (_notice != null) ...[
                const SizedBox(height: AppSpacing.md),
                _noticeFor(context, _notice!),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                key: PremiumGateScreen.subscribeKey,
                onPressed: _subscribe,
                child: Text(l.premiumGateSubscribe),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                key: PremiumGateScreen.refreshKey,
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: c.textSecondary,
                ),
                onPressed: _refreshing ? null : _refresh,
                child: _refreshing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primaryInk,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(child: Text(l.premiumGateRefreshing)),
                        ],
                      )
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
            ],
            const SizedBox(height: AppSpacing.md),
            _Footer(
              onPrivacy: () =>
                  Navigator.of(context).pushNamed(AppRoutes.privacy),
            ),
          ],
        ),
      ),
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

    final selected = data.plans.any((p) => p.key == _selectedPlan)
        ? _selectedPlan
        : data.defaultPlan?.key;
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
            selected: plan.key == selected,
            onTap: () => setState(() => _selectedPlan = plan.key),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (data.trialDays > 0) ...[
          Text(
            l.premiumGateTrial(data.trialDays),
            style: AppTypography.of(
              context,
              AppTypography.labelLg,
              color: c.primaryInk,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        Text(
          l.premiumGatePriceNote,
          style: AppTypography.of(
            context,
            AppTypography.bodySm,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _noticeFor(BuildContext context, _GateNotice notice) {
    final l = AppLocalizations.of(context);
    return KeyedSubtree(
      key: PremiumGateScreen.noticeKey,
      child: switch (notice) {
        _GateNotice.purchaseUnavailable => _Notice(
            tone: _Tone.info,
            message: l.premiumGatePurchaseUnavailable,
          ),
        _GateNotice.notFound => _Notice(
            tone: _Tone.warning,
            message: l.premiumGateNotFound,
          ),
        _GateNotice.refreshFailed => _Notice(
            tone: _Tone.error,
            message: l.premiumGateRefreshFailed,
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
              Text(title, style: AppTypography.of(context, AppTypography.titleSm)),
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
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool english;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final currency = _currencyLabel(l, plan.currency);
    final badge = plan.badge(english: english);
    final period = plan.periodMonths == 12
        ? l.premiumGatePeriodYear
        : l.premiumGatePeriod(plan.periodMonths);
    final perMonth = plan.pricePerMonth;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? c.primaryInk : c.borderStrong,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? c.primaryInk : c.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              plan.name(english: english),
                              style: AppTypography.of(
                                context,
                                AppTypography.titleMd,
                              ),
                            ),
                            if (badge != null) _Badge(badge),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${l.premiumGatePrice(formatPlanPrice(plan.price), currency)} · $period',
                          style: AppTypography.of(
                            context,
                            AppTypography.titleSm,
                            color: c.textPrimary,
                          ),
                        ),
                        if (perMonth != null && plan.periodMonths > 1) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l.premiumGatePerMonth(
                              formatPlanPrice(perMonth),
                              currency,
                            ),
                            style: AppTypography.of(
                              context,
                              AppTypography.bodySm,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
            ElevatedButton(
              key: PremiumGateScreen.continueKey,
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
  const _Footer({required this.onPrivacy});

  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
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
        border: Border.all(color: c.border),
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
