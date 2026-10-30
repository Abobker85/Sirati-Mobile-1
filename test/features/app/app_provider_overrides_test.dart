import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/app/app_provider_overrides.dart';
import 'package:sirati/features/auth/application/provider_reauth.dart';
import 'package:sirati/shared/services/provider_reauth.dart';

void main() {
  test('the app root binds provider re-authentication to the auth feature', () {
    final container = ProviderContainer(overrides: appProviderOverrides);
    addTearDown(container.dispose);
    expect(container.read(providerReauthProvider), isA<SocialProviderReauth>());
  });

  test('an unbound scope fails loudly instead of skipping re-authentication',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(providerReauthProvider), throwsA(anything));
  });
}
