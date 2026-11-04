import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/shared/services/purchases/revenuecat_store_purchases.dart';

/// What the App Store sells for one server plan (matched by period).
class StoreOffer {
  const StoreOffer({
    required this.planKey,
    required this.priceString,
    this.freeTrialDays,
  });

  final String planKey;

  /// Localized store price, e.g. "SAR 99.00". Apple requires showing this
  /// rather than our own catalogue price.
  final String priceString;

  /// Set only when the store product starts with a free trial.
  final int? freeTrialDays;
}

sealed class StorePurchaseOutcome {
  const StorePurchaseOutcome();
}

/// The store charged the user. Access is still granted only by the server,
/// which hears about it through the RevenueCat webhook.
final class StorePurchaseCompleted extends StorePurchaseOutcome {
  const StorePurchaseCompleted();
}

final class StorePurchaseCancelled extends StorePurchaseOutcome {
  const StorePurchaseCancelled();
}

/// e.g. Ask to Buy: Apple holds the purchase until a parent approves it.
final class StorePurchasePending extends StorePurchaseOutcome {
  const StorePurchasePending();
}

final class StorePurchaseFailed extends StorePurchaseOutcome {
  const StorePurchaseFailed();
}

/// In-app subscription store. The store user id is always the Siratie user
/// id, so the RevenueCat webhook can find the account on the server.
abstract interface class StorePurchases {
  /// False when this build cannot sell (no store key, unsupported platform).
  /// The paywall then stays informational.
  bool get isAvailable;

  /// Store offers keyed by plan key; plans without a store product are absent.
  Future<Map<String, StoreOffer>> offersFor({
    required int userId,
    required Map<String, int> planMonths,
  });

  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
  });

  /// True when the store reports an active entitlement after restoring.
  Future<bool> restore({required int userId});
}

class UnavailableStorePurchases implements StorePurchases {
  const UnavailableStorePurchases();

  @override
  bool get isAvailable => false;

  @override
  Future<Map<String, StoreOffer>> offersFor({
    required int userId,
    required Map<String, int> planMonths,
  }) async =>
      const {};

  @override
  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
  }) async =>
      const StorePurchaseFailed();

  @override
  Future<bool> restore({required int userId}) async => false;
}

/// Single injection point; tests override it with a fake.
final storePurchasesProvider = Provider<StorePurchases>(
  (ref) => RevenueCatStorePurchases.fromEnvironment(),
);
