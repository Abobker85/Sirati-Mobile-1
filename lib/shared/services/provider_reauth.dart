import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A fresh provider ID token: how a Google/Apple-only account (no password)
/// proves it's the account holder before a sensitive action.
@immutable
class ProviderProof {
  const ProviderProof({
    required this.provider,
    required this.idToken,
    this.nonce,
  });

  final String provider;
  final String idToken;

  /// Apple's raw nonce; the server checks the token carries its sha256.
  final String? nonce;
}

/// This build has no client config for the provider.
class ProviderNotConfigured implements Exception {
  const ProviderNotConfigured(this.provider);
  final String provider;
}

/// Signs in with a provider again. Implemented by the auth feature and
/// bound in the app's composition root (`appProviderOverrides`), so other
/// features can ask for proof without importing auth.
abstract interface class ProviderReauth {
  /// Null = the user cancelled.
  Future<ProviderProof?> prove(String provider);
}

final providerReauthProvider = Provider<ProviderReauth>(
  (ref) => throw StateError(
    'providerReauthProvider is not bound: add appProviderOverrides to the '
    'ProviderScope',
  ),
);
