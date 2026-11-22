import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/features/dashboard/data/subscription_plans_repository.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/features/dashboard/application/premium_gate_controller.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Plans extends SubscriptionPlansRepository {
  @override
  Future<SubscriptionOffer> load() async => SubscriptionOffer.fromJson({
        'data': {
          'plans': [
            {
              'key': 'monthly',
              'product_id': 'sirati_monthly',
              'period_months': 1,
              'price': 19.99,
              'name_ar': 'شهري',
              'name_en': 'Monthly',
              'is_default': true,
              'currency': 'SAR',
            }
          ],
          'currency': 'SAR',
          'trial_days': 3,
          'access': {'is_subscribed': true},
        },
      });
}

class _OfflineApi extends ApiClient {
  @override
  Future<Map<String, dynamic>> getJson(String path) async =>
      throw Exception('offline');
}

void main() {
  setUp(() => SessionCache.instance
      .setUser(const AuthUser(id: 1, name: 'Sara', email: 'sara@x.io')));

  for (final error in <Object>[Exception('offline'), StateError('boom')]) {
    testWidgets('a failed refresh does not revoke known access ($error)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          subscriptionPlansRepositoryProvider.overrideWithValue(_Plans()),
          authApiServiceProvider
              .overrideWithValue(AuthApiService(apiClient: _OfflineApi())),
          storePurchasesProvider
              .overrideWithValue(const UnavailableStorePurchases()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const PremiumGateScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(PremiumGateScreen.continueKey), findsOneWidget,
          reason: 'server says the account is subscribed');

      await tester.tap(find.byKey(PremiumGateScreen.refreshKey));
      await tester.pumpAndSettle();
      expect(find.byKey(PremiumGateScreen.continueKey), findsOneWidget,
          reason: 'a refresh that could not reach the server proves nothing');
    });
  }
}
