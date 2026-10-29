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

/// The Google OAuth **web** client id (project sirati-98cef). Android needs
/// it as the server client id to receive an ID token; the API accepts it as
/// the token audience. Client ids are public, not secrets.
const googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '723811480072-j8rsac3g417452bamo4bn0eoddvvupb2.apps.googleusercontent.com',
);

/// The Google OAuth iOS client id. Its reversed form is the URL scheme in
/// ios/Runner/Info.plist; change both together.
const googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue:
      '723811480072-3msig0tm47r7n0hohvtmv5r7rm74mmd7.apps.googleusercontent.com',
);

/// The Apple **Services ID** used by Sign in with Apple's web flow on
/// Android. iOS signs in natively with the bundle id and doesn't need it.
const appleServiceId = String.fromEnvironment(
  'APPLE_SERVICE_ID',
  defaultValue: 'com.sirati.signin',
);

/// Where Apple posts the web-flow result; the API forwards it to the app.
/// Must be listed as a Return URL on the Services ID.
const appleRedirectUri = String.fromEnvironment(
  'APPLE_REDIRECT_URI',
  defaultValue: 'https://siratie.com/api/auth/apple/callback',
);

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
