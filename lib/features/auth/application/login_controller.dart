import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/features/auth/data/apple_credential_source.dart';
import 'package:sirati/features/auth/data/google_id_token_source.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';

sealed class LoginOutcome {
  const LoginOutcome();
}

/// Signed in; [emailVerified] decides between Home and the OTP screen.
final class LoginSucceeded extends LoginOutcome {
  const LoginSucceeded({required this.email, required this.emailVerified});
  final String email;
  final bool emailVerified;
}

final class LoginRejected extends LoginOutcome {
  const LoginRejected(this.error);
  final ApiException error;
}

final class LoginFailedUnexpectedly extends LoginOutcome {
  const LoginFailedUnexpectedly();
}

/// Dropped because a sign-in was already running, or the user closed the
/// provider's account picker.
final class LoginIgnored extends LoginOutcome {
  const LoginIgnored();
}

/// This build has no client id for the provider, so it can't be used.
final class LoginProviderNotConfigured extends LoginOutcome {
  const LoginProviderNotConfigured();
}

/// Login form rule: the server only requires a password to be present, so
/// the client must not impose a length that could lock out valid accounts.
String? loginPasswordError(String? value) =>
    (value == null || value.isEmpty) ? 'required' : null;

/// Whether a sign-in request is in flight.
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, bool>(LoginController.new);

class LoginController extends Notifier<bool> {
  @override
  bool build() => false;

  /// One request at a time: keyboard Send, the button, and the snackbar
  /// Retry can all fire while a sign-in is running.
  Future<LoginOutcome> signIn({
    required String email,
    required String password,
  }) =>
      _run(() => ref
          .read(authApiServiceProvider)
          .login(email: email.trim(), password: password));

  /// Google account picker, then the server checks the ID token. Shares the
  /// busy flag with [signIn], so neither runs while the other does.
  Future<LoginOutcome> signInWithGoogle() async {
    if (state) return const LoginIgnored();
    final google = ref.read(googleIdTokenSourceProvider);
    if (google == null) return const LoginProviderNotConfigured();
    return _run(() async {
      final idToken = await google.idToken();
      if (idToken == null) return null;
      return ref
          .read(authApiServiceProvider)
          .socialSignIn(provider: 'google', idToken: idToken);
    });
  }

  /// Sign in with Apple, then the server checks the token, its nonce and
  /// the authorization code.
  Future<LoginOutcome> signInWithApple() async {
    if (state) return const LoginIgnored();
    final apple = ref.read(appleCredentialSourceProvider);
    if (apple == null) return const LoginProviderNotConfigured();
    return _run(() async {
      final result = await apple.signIn();
      if (result == null) return null;
      return ref.read(authApiServiceProvider).socialSignIn(
            provider: 'apple',
            idToken: result.idToken,
            nonce: result.rawNonce,
            authorizationCode: result.authorizationCode,
            name: result.name,
          );
    });
  }

  /// Runs [attempt] unless a sign-in is already in flight; a null session
  /// means the user cancelled.
  Future<LoginOutcome> _run(Future<AuthSession?> Function() attempt) async {
    if (state) return const LoginIgnored();
    state = true;
    try {
      final session = await attempt();
      if (session == null) return const LoginIgnored();
      return LoginSucceeded(
        email: session.user.email,
        emailVerified: session.user.emailVerified,
      );
    } on ApiException catch (e) {
      return LoginRejected(e);
    } catch (_) {
      return const LoginFailedUnexpectedly();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
