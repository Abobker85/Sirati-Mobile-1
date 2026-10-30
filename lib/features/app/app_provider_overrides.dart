import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sirati/features/auth/application/provider_reauth.dart';
import 'package:sirati/shared/services/provider_reauth.dart';

/// Binds shared service interfaces to the features that implement them.
/// The app's root [ProviderScope] must use these.
final appProviderOverrides = <Override>[
  providerReauthProvider.overrideWith(SocialProviderReauth.new),
];
