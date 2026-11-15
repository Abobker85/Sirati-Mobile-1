/// The account's Premium status as the server reports it in `/auth/me` →
/// `subscription` (`SubscriptionGate::stateFor`). Only an explicit
/// `is_subscribed: true` counts as Premium; anything missing or malformed is
/// the free plan.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPremium,
    this.planId,
    this.expiresAt,
    this.enforced = false,
    this.downloadLocked = false,
    this.aiWritingLocked = false,
    this.fullAnalysisLocked = false,
    this.cvLimit,
    this.cvUsed = 0,
    this.analysisLimit,
    this.analysisUsed = 0,
    this.managedByStore = true,
  });

  const SubscriptionStatus.free()
      : isPremium = false,
        planId = null,
        expiresAt = null,
        enforced = false,
        downloadLocked = false,
        aiWritingLocked = false,
        fullAnalysisLocked = false,
        cvLimit = null,
        cvUsed = 0,
        analysisLimit = null,
        analysisUsed = 0,
        managedByStore = true;

  factory SubscriptionStatus.fromSubscription(Map<String, dynamic>? state) {
    if (state == null) return const SubscriptionStatus.free();
    final plan = state['plan_id'];
    final expires = state['expires_at'];
    final quota = state['quota'];
    final cv = quota is Map ? quota['cv'] : null;
    final analysis = quota is Map ? quota['analysis'] : null;
    return SubscriptionStatus(
      isPremium: state['is_subscribed'] == true,
      planId: plan is String && plan.trim().isNotEmpty ? plan.trim() : null,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
      enforced: state['enforced'] == true,
      // Marked locked only when the server says so explicitly: missing data
      // never shows a Premium marker on something the user may own.
      downloadLocked: state['can_download'] == false,
      aiWritingLocked: state['can_enhance'] == false,
      fullAnalysisLocked: state['can_view_full_analysis'] == false,
      cvLimit: _limit(cv),
      cvUsed: _used(cv),
      analysisLimit: _limit(analysis),
      analysisUsed: _used(analysis),
      // Older servers don't send `source`: keep offering Apple's page.
      managedByStore: state['source'] != 'admin',
    );
  }

  static int? _limit(Object? quota) {
    final v = quota is Map ? quota['limit'] : null;
    return v is int && v > 0 ? v : null;
  }

  static int _used(Object? quota) {
    final v = quota is Map ? quota['used'] : null;
    return v is int && v > 0 ? v : 0;
  }

  final bool isPremium;
  final String? planId;

  /// When the current paid period ends; null for access without an end date.
  final DateTime? expiresAt;

  /// The free limits apply to this account (monetization on, not Premium).
  final bool enforced;

  final bool downloadLocked;
  final bool aiWritingLocked;
  final bool fullAnalysisLocked;

  /// Free daily limits; null when there is none (Premium or switched off).
  final int? cvLimit;
  final int cvUsed;
  final int? analysisLimit;
  final int analysisUsed;

  /// False for Premium given by an admin: Apple has nothing to manage.
  final bool managedByStore;

  /// A free account the free-plan limits apply to: the one to offer Premium.
  bool get isFreeTier => enforced && !isPremium;

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
