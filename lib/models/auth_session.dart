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

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      location: json['location']?.toString(),
    );
  }

  AuthUser copyWith({
    String? name,
    String? phone,
    String? location,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
