import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sirati/features/auth/domain/social_sign_in.dart';

/// What the API needs from one Sign in with Apple attempt.
@immutable
class AppleSignInResult {
  const AppleSignInResult({
    required this.idToken,
    required this.authorizationCode,
    required this.rawNonce,
    this.name,
  });

  final String idToken;

  /// One-time code the server exchanges for a refresh token it can revoke.
  final String authorizationCode;

  /// Sent to the server, which checks the token carries sha256(rawNonce).
  final String rawNonce;

  /// Apple shares the name on the first authorization only.
  final String? name;
}

/// Runs Sign in with Apple; null means the user cancelled.
abstract interface class AppleCredentialSource {
  Future<AppleSignInResult?> signIn();
}

/// Null when this build can't run Sign in with Apple: Android uses Apple's
/// web flow, which needs the Services ID.
final appleCredentialSourceProvider = Provider<AppleCredentialSource?>((ref) {
  final web = defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS;
  if (web && appleServiceId.isEmpty) return null;
  return SignInWithAppleCredentialSource(
    webAuthenticationOptions: web
        ? WebAuthenticationOptions(
            clientId: appleServiceId,
            redirectUri: Uri.parse(appleRedirectUri),
          )
        : null,
  );
});

class SignInWithAppleCredentialSource implements AppleCredentialSource {
  SignInWithAppleCredentialSource({this.webAuthenticationOptions});

  final WebAuthenticationOptions? webAuthenticationOptions;

  @override
  Future<AppleSignInResult?> signIn() async {
    final rawNonce = appleNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        webAuthenticationOptions: webAuthenticationOptions,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Apple returned no identity token.');
    }
    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    return AppleSignInResult(
      idToken: idToken,
      authorizationCode: credential.authorizationCode,
      rawNonce: rawNonce,
      name: name.isEmpty ? null : name,
    );
  }
}

/// A fresh, unguessable nonce for one sign-in attempt.
@visibleForTesting
String appleNonce([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => source.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
