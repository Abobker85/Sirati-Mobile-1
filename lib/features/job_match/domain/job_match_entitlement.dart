/// What the server allows right now, from `/auth/me` → `subscription`.
enum JobMatchAccess {
  allowed,

  /// Not subscribed: show the paywall.
  subscriptionRequired,

  /// Subscribed, but today's Job Match quota is used up.
  quotaReached,

  /// The server did not grant access for another reason (feature disabled or
  /// misconfigured, or no entitlement data). Fails closed.
  unavailable,
}

class JobMatchEntitlement {
  const JobMatchEntitlement({
    required this.access,
    this.limit,
    this.used,
    this.resetsAt,
    this.trialDays = 0,
  });

  final JobMatchAccess access;
  final int? limit;
  final int? used;
  final DateTime? resetsAt;
  final int trialDays;

  int? get remaining {
    final l = limit;
    final u = used;
    if (l == null || u == null) return null;
    return (l - u).clamp(0, l);
  }

  /// Interprets `SubscriptionGate::stateFor`. Only an explicit
  /// `can_job_match: true` grants access; anything missing or malformed is
  /// treated as locked.
  factory JobMatchEntitlement.fromSubscription(Map<String, dynamic>? state) {
    if (state == null) {
      return const JobMatchEntitlement(access: JobMatchAccess.unavailable);
    }
    final quota = state['quota'];
    final jobMatch = quota is Map ? quota['job_match'] : null;
    final limit = jobMatch is Map ? _int(jobMatch['limit']) : null;
    final used = jobMatch is Map ? _int(jobMatch['used']) : null;
    final resetsAt = jobMatch is Map
        ? DateTime.tryParse(jobMatch['resets_at']?.toString() ?? '')
        : null;
    final trialDays = _int(state['trial_days']) ?? 0;

    final JobMatchAccess access;
    if (state['is_subscribed'] != true) {
      access = JobMatchAccess.subscriptionRequired;
    } else if (state['can_job_match'] == true) {
      access = JobMatchAccess.allowed;
    } else if (limit != null && limit > 0 && used != null && used >= limit) {
      access = JobMatchAccess.quotaReached;
    } else {
      access = JobMatchAccess.unavailable;
    }

    return JobMatchEntitlement(
      access: access,
      limit: limit,
      used: used,
      resetsAt: resetsAt,
      trialDays: trialDays < 0 ? 0 : trialDays,
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}
