class AuthSession {
  final String token;
  final String tokenType;
  final AuthUser user;

  const AuthSession(
      {required this.token, required this.tokenType, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return AuthSession(
      token: data['token']?.toString() ?? '',
      tokenType: data['token_type']?.toString() ?? 'Bearer',
      user:
          AuthUser.fromJson(data['user'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? location;

  /// Public URL of the profile photo; null without one.
  final String? avatarUrl;
  final int? jobTitleId;
  final String? jobTitleOther;
  final Map<String, dynamic>? jobTitle;
  final bool emailVerified;

  /// Server-computed entitlement state (`SubscriptionGate::stateFor`); null
  /// when the payload did not include it.
  final Map<String, dynamic>? subscription;

  /// False for Google/Apple accounts that never set a password: they
  /// confirm sensitive actions by signing in with the provider again.
  /// Assumed true when the server doesn't say (older API).
  final bool hasPassword;

  /// Linked sign-in providers, e.g. `['apple', 'google']`.
  final List<String> socialProviders;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
    this.avatarUrl,
    this.jobTitleId,
    this.jobTitleOther,
    this.jobTitle,
    this.emailVerified = false,
    this.subscription,
    this.hasPassword = true,
    this.socialProviders = const [],
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['job_title'];
    return AuthUser(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      location: json['location']?.toString(),
      avatarUrl: _nullable(json['avatar_url']),
      jobTitleId: _asNullableInt(json['job_title_id']),
      jobTitleOther: _nullable(json['job_title_other']),
      jobTitle: rawTitle is Map ? Map<String, dynamic>.from(rawTitle) : null,
      emailVerified:
          _asBool(json['email_verified'] ?? json['email_verified_at']),
      subscription: json['subscription'] is Map
          ? Map<String, dynamic>.from(json['subscription'] as Map)
          : null,
      hasPassword:
          json['has_password'] == null ? true : _asBool(json['has_password']),
      socialProviders: json['social_providers'] is List
          ? [
              for (final p in json['social_providers'] as List)
                if (p is String && p.isNotEmpty) p,
            ]
          : const [],
    );
  }

  AuthUser copyWith({
    String? name,
    String? phone,
    String? location,
    int? jobTitleId,
    String? jobTitleOther,
    Map<String, dynamic>? jobTitle,
    bool? emailVerified,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      avatarUrl: avatarUrl,
      jobTitleId: jobTitleId ?? this.jobTitleId,
      jobTitleOther: jobTitleOther ?? this.jobTitleOther,
      jobTitle: jobTitle ?? this.jobTitle,
      emailVerified: emailVerified ?? this.emailVerified,
      subscription: subscription,
      hasPassword: hasPassword,
      socialProviders: socialProviders,
    );
  }

  String? displayJobTitle({required bool english}) {
    if (jobTitleOther != null && jobTitleOther!.trim().isNotEmpty) {
      return jobTitleOther!.trim();
    }
    if (jobTitle != null) {
      final ar = jobTitle!['name_ar']?.toString().trim();
      final en = jobTitle!['name_en']?.toString().trim();
      if (english && en != null && en.isNotEmpty) return en;
      if (ar != null && ar.isNotEmpty) return ar;
      if (en != null && en.isNotEmpty) return en;
    }
    return null;
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

String? _nullable(dynamic value) {
  final str = value?.toString();
  if (str == null || str.isEmpty) return null;
  return str;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    // Non-empty ISO datetime from email_verified_at means verified.
    if (value.isNotEmpty && lower != 'false' && lower != 'null') return true;
  }
  if (value is num) return value != 0;
  return false;
}
