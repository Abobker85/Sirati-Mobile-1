import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sirati/features/auth/domain/social_sign_in.dart';

/// Asks the user to pick a Google account and returns its ID token, which
/// the API verifies. Null means the user closed the picker.
abstract interface class GoogleIdTokenSource {
  Future<String?> idToken();
}

/// Null when this build has no Google server client id: the login screen
/// then explains that Google sign-in isn't set up instead of failing in
/// the SDK.
final googleIdTokenSourceProvider = Provider<GoogleIdTokenSource?>((ref) {
  if (googleServerClientId.isEmpty) return null;
  return GoogleSignInIdTokenSource(
    serverClientId: googleServerClientId,
    iosClientId: googleIosClientId.isEmpty ? null : googleIosClientId,
  );
});

class GoogleSignInIdTokenSource implements GoogleIdTokenSource {
  GoogleSignInIdTokenSource({
    required String serverClientId,
    String? iosClientId,
  }) : _google = GoogleSignIn(
          scopes: const ['email', 'profile'],
          serverClientId: serverClientId,
          clientId:
              defaultTargetPlatform == TargetPlatform.iOS ? iosClientId : null,
        );

  final GoogleSignIn _google;

  @override
  Future<String?> idToken() async {
    try {
      final account = await _google.signIn();
      if (account == null) return null;
      final token = (await account.authentication).idToken;
      if (token == null || token.isEmpty) {
        throw StateError('Google returned no ID token; check the server '
            'client id and the app SHA-1 in Google Cloud.');
      }
      return token;
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) return null;
      rethrow;
    } finally {
      // Forget the chosen account so the picker shows again next time
      // (e.g. after signing out to switch accounts).
      unawaited(_google.signOut().then((_) {}, onError: (_) {}));
    }
  }
}
