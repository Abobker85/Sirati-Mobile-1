import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';

/// Reads the plan catalogue. The endpoint is public but receives the bearer
/// token when one exists, so `access` reflects the signed-in user.
class SubscriptionPlansRepository {
  SubscriptionPlansRepository({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient(tokenProvider: const AuthTokenStore().readToken);

  final ApiClient _apiClient;

  Future<SubscriptionOffer> load() async => SubscriptionOffer.fromJson(
        await _apiClient.getJson('/mobile/subscription-plans'),
      );
}
