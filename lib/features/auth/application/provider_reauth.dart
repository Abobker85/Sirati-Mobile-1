import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/auth/data/apple_credential_source.dart';
import 'package:sirati/features/auth/data/google_id_token_source.dart';

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

/// Display name of a provider id (`google` -> `Google`).
String providerLabel(String provider) => switch (provider) {
      'google' => 'Google',
      'apple' => 'Apple',
      _ => provider,
    };

final providerReauthProvider = Provider<ProviderReauth>(ProviderReauth.new);

class ProviderReauth {
  ProviderReauth(this._ref);
  final Ref _ref;

  /// Signs in with [provider] again. Null = the user cancelled.
  Future<ProviderProof?> prove(String provider) async {
    switch (provider) {
      case 'google':
        final google = _ref.read(googleIdTokenSourceProvider);
        if (google == null) throw const ProviderNotConfigured('google');
        final token = await google.idToken();
        return token == null
            ? null
            : ProviderProof(provider: 'google', idToken: token);
      case 'apple':
        final apple = _ref.read(appleCredentialSourceProvider);
        if (apple == null) throw const ProviderNotConfigured('apple');
        final result = await apple.signIn();
        return result == null
            ? null
            : ProviderProof(
                provider: 'apple',
                idToken: result.idToken,
                nonce: result.rawNonce,
              );
      default:
        throw ProviderNotConfigured(provider);
    }
  }
}
