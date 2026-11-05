import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/dashboard/data/subscription_plans_repository.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';
import 'package:sirati/shared/services/session_user_provider.dart';

/// Single injection point for [SubscriptionPlansRepository]; tests override it.
final subscriptionPlansRepositoryProvider =
    Provider<SubscriptionPlansRepository>(
  (ref) => SubscriptionPlansRepository(),
);

/// Plans + current access. The gate has its own Retry, so errors surface at
/// once instead of being retried silently.
final subscriptionOfferProvider = FutureProvider.autoDispose<SubscriptionOffer>(
  (ref) => ref.read(subscriptionPlansRepositoryProvider).load(),
  retry: (_, __) => null,
);

/// What the App Store sells to the signed-in user, keyed by plan key.
class StoreCatalog {
  const StoreCatalog({required this.userId, required this.offers});

  final int userId;
  final Map<String, StoreOffer> offers;
}

/// Null when this build cannot sell (the gate stays informational). Throws
/// when the store or the account could not be read, so the gate shows Retry.
/// Reloads when the signed-in account changes; the gate still re-checks the
/// account before buying.
final storeCatalogProvider = FutureProvider.autoDispose<StoreCatalog?>(
  (ref) async {
    final store = ref.watch(storePurchasesProvider);
    if (!store.isAvailable) return null;
    ref.watch(sessionUserIdProvider);
    final offer = await ref.watch(subscriptionOfferProvider.future);
    final user = await ref.read(authApiServiceProvider).me();
    if (user == null) throw StateError('No signed-in account');
    final offers = await store.offersFor(
      userId: user.id,
      planMonths: {for (final plan in offer.plans) plan.key: plan.periodMonths},
    );
    return StoreCatalog(userId: user.id, offers: offers);
  },
  retry: (_, __) => null,
);
