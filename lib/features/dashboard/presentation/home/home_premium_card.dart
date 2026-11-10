import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/subscription_status.dart';
import 'package:sirati/shared/premium/premium_ui.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';

/// The one Premium card on Home, only for free accounts the limits apply
/// to: what Premium adds and today's free usage, so a limit never comes as
/// a surprise. Hidden for Premium and while monetization is off.
class HomePremiumCard extends StatelessWidget {
  const HomePremiumCard({super.key, this.padding = EdgeInsets.zero});

  /// Applied only while the card shows, so Premium accounts get no gap.
  final EdgeInsetsGeometry padding;

  static const cardKey = ValueKey('home-premium-card');

  @override
  Widget build(BuildContext context) {
    return SubscriptionBuilder(
      builder: (context, status) => status.isFreeTier
          ? Padding(padding: padding, child: _Card(status: status))
          : const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final usage = [
      if (status.cvLimit case final limit?)
        l.premiumHomeCvsToday(status.cvUsed.clamp(0, limit), limit),
      if (status.analysisLimit case final limit?)
        l.premiumHomeAnalysesToday(status.analysisUsed.clamp(0, limit), limit),
    ];
    final radius = BorderRadius.circular(18);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.amberAccent),
      ),
      child: InkWell(
        key: HomePremiumCard.cardKey,
        borderRadius: radius,
        onTap: () => unawaited(openPremium(context)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.amberLight,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.workspace_premium_rounded,
                      size: 24, color: c.onWarningContainer),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.premiumHomeTitle,
                      style: AppTypography.of(context, AppTypography.titleMd),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.premiumHomeBody,
                      style: AppTypography.of(context, AppTypography.bodySm,
                          color: c.textSecondary),
                    ),
                    for (final line in usage) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.today_rounded,
                              size: 14, color: c.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              line,
                              style: AppTypography.of(
                                  context, AppTypography.bodySm,
                                  color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              DirectionalIcon(Icons.chevron_right_rounded,
                  color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
