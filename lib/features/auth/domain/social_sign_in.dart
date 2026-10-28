import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether each third-party sign-in is offered on the login screen.
///
/// On in debug builds so the providers can be tested; off in release and
/// profile builds unless switched on with
/// `--dart-define=SIRATI_GOOGLE_SIGN_IN=true` (and `SIRATI_APPLE_SIGN_IN`).
/// Keep them off for any store build that ships before both work end to
/// end: review rejects controls that don't work (App Store 2.1), and
/// offering Google sign-in makes Sign in with Apple mandatory (App Store
/// 4.8) — [SocialSignInOptions.fromBuild] enforces the latter on iOS.
const googleSignInEnabled =
    bool.fromEnvironment('SIRATI_GOOGLE_SIGN_IN', defaultValue: kDebugMode);
const appleSignInEnabled =
    bool.fromEnvironment('SIRATI_APPLE_SIGN_IN', defaultValue: kDebugMode);
const socialSignInEnabled = googleSignInEnabled || appleSignInEnabled;

/// The Google OAuth **web** client id. Android needs it as the server client
/// id to receive an ID token; the API accepts it as the token audience.
const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// The Google OAuth iOS client id (its reversed form is the URL scheme in
/// ios/Runner/Info.plist). Empty = taken from GoogleService-Info.plist.
const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// Which provider buttons the login screen shows.
@immutable
class SocialSignInOptions {
  const SocialSignInOptions({required this.google, required this.apple});

  /// The build's flags, with App Store 4.8 applied: a non-debug iOS build
  /// never offers Google without Apple.
  factory SocialSignInOptions.fromBuild({
    bool google = googleSignInEnabled,
    bool apple = appleSignInEnabled,
    TargetPlatform? platform,
    bool debug = kDebugMode,
  }) {
    final ios = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;
    return SocialSignInOptions(
      google: google && (apple || debug || !ios),
      apple: apple,
    );
  }

  final bool google;
  final bool apple;

  bool get any => google || apple;
}

final socialSignInOptionsProvider =
    Provider<SocialSignInOptions>((ref) => SocialSignInOptions.fromBuild());
