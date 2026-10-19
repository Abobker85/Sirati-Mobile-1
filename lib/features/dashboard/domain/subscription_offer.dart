/// One paid plan from `GET /mobile/subscription-plans`.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.key,
    required this.periodMonths,
    required this.price,
    required this.currency,
    required this.nameAr,
    required this.nameEn,
    this.badgeAr,
    this.badgeEn,
    this.isDefault = false,
    this.pricePerMonth,
  });

  final String key;
  final int periodMonths;
  final double price;
  final String currency;
  final String nameAr;
  final String nameEn;
  final String? badgeAr;
  final String? badgeEn;
  final bool isDefault;
  final double? pricePerMonth;

  String name({required bool english}) {
    final preferred = english ? nameEn : nameAr;
    return preferred.isNotEmpty ? preferred : (english ? nameAr : nameEn);
  }

  String? badge({required bool english}) => english ? badgeEn : badgeAr;

  /// Null when the plan is missing a key, price or period: such a plan
  /// cannot be shown honestly, so it is dropped rather than guessed.
  static SubscriptionPlan? tryParse(Object? json, {required String currency}) {
    if (json is! Map) return null;
    final key = _string(json['key']);
    final months = _int(json['period_months']);
    final price = _double(json['price']);
    if (key == null || months == null || months <= 0) return null;
    if (price == null || price <= 0) return null;
    final perMonth = _double(json['price_per_month']);
    return SubscriptionPlan(
      key: key,
      periodMonths: months,
      price: price,
      currency: _string(json['currency']) ?? currency,
      nameAr: _string(json['name_ar']) ?? '',
      nameEn: _string(json['name_en']) ?? '',
      badgeAr: _string(json['badge_ar']),
      badgeEn: _string(json['badge_en']),
      isDefault: json['is_default'] == true,
      pricePerMonth: perMonth != null && perMonth > 0 ? perMonth : null,
    );
  }
}

/// Plans plus the caller's current access, as one server snapshot.
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.plans,
    this.currency = '',
    this.trialDays = 0,
    this.subscribed = false,
  });

  final List<SubscriptionPlan> plans;
  final String currency;
  final int trialDays;

  /// True only when the server explicitly says so (fails closed).
  final bool subscribed;

  SubscriptionPlan? get defaultPlan {
    if (plans.isEmpty) return null;
    for (final plan in plans) {
      if (plan.isDefault) return plan;
    }
    return plans.first;
  }

  factory SubscriptionOffer.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final data = raw is Map ? raw : const {};
    final currency = _string(data['currency']) ?? '';
    final rawPlans = data['plans'];
    final seen = <String>{};
    final plans = <SubscriptionPlan>[
      if (rawPlans is List)
        for (final item in rawPlans)
          if (SubscriptionPlan.tryParse(item, currency: currency)
              case final plan? when seen.add(plan.key))
            plan,
    ];
    final trial = _int(data['trial_days']) ?? 0;
    final access = data['access'];
    return SubscriptionOffer(
      plans: plans,
      currency: currency,
      trialDays: trial < 0 ? 0 : trial,
      subscribed: access is Map && access['is_subscribed'] == true,
    );
  }
}

/// Whether `/auth/me` → `subscription` reports an active subscription.
/// Anything but an explicit `is_subscribed: true` counts as not active.
bool isSubscriptionActive(Map<String, dynamic>? subscription) =>
    subscription != null && subscription['is_subscribed'] == true;

String? _string(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

double? _double(Object? value) {
  if (value is num) return value.isFinite ? value.toDouble() : null;
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : null;
}
