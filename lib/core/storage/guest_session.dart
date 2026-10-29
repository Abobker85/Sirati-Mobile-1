import 'package:flutter/foundation.dart';

/// Whether the app is being used without an account ("Continue without
/// account"). The Home shell sets it once the token store answers; the
/// route table reads it so account-only screens invite sign-in instead of
/// failing with a 401.
abstract final class GuestSession {
  static final active = ValueNotifier<bool>(false);
}
