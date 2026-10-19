import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/dashboard/data/subscription_plans_repository.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';

/// Single injection point for [SubscriptionPlansRepository]; tests override it.
final subscriptionPlansRepositoryProvider =
    Provider<SubscriptionPlansRepository>(
  (ref) => SubscriptionPlansRepository(),
);

/// Plans + current access. The gate has its own Retry, so errors surface at
/// once instead of being retried silently.
final subscriptionOfferProvider =
    FutureProvider.autoDispose<SubscriptionOffer>(
  (ref) => ref.read(subscriptionPlansRepositoryProvider).load(),
  retry: (_, __) => null,
);
