import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/auth/data/apple_credential_source.dart';
import 'package:sirati/features/auth/data/google_id_token_source.dart';
import 'package:sirati/shared/services/provider_reauth.dart';

/// [ProviderReauth] through the Google and Apple sign-in sources.
class SocialProviderReauth implements ProviderReauth {
  SocialProviderReauth(this._ref);
  final Ref _ref;

  @override
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
