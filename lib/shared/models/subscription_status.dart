/// The account's Premium status as the server reports it in `/auth/me` →
/// `subscription` (`SubscriptionGate::stateFor`). Only an explicit
/// `is_subscribed: true` counts as Premium; anything missing or malformed is
/// the free plan.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPremium,
    this.planId,
    this.expiresAt,
  });

  const SubscriptionStatus.free()
      : isPremium = false,
        planId = null,
        expiresAt = null;

  factory SubscriptionStatus.fromSubscription(Map<String, dynamic>? state) {
    if (state == null) return const SubscriptionStatus.free();
    final plan = state['plan_id'];
    final expires = state['expires_at'];
    return SubscriptionStatus(
      isPremium: state['is_subscribed'] == true,
      planId: plan is String && plan.trim().isNotEmpty ? plan.trim() : null,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
    );
  }

  final bool isPremium;
  final String? planId;

  /// When the current paid period ends; null for access without an end date.
  final DateTime? expiresAt;

  /// Which paywall plan [planId] is, from its App Store product identifier.
  SubscriptionPlanKind? get plan {
    final id = planId?.toLowerCase();
    if (id == null) return null;
    final last = id.split('.').last;
    return switch (last) {
      'monthly' => SubscriptionPlanKind.monthly,
      'semiannual' => SubscriptionPlanKind.semiannual,
      'annual' => SubscriptionPlanKind.annual,
      _ => null,
    };
  }
}

enum SubscriptionPlanKind { monthly, semiannual, annual }
