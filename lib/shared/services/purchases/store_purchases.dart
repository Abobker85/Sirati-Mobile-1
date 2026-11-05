import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/shared/services/purchases/revenuecat_store_purchases.dart';

/// Calendar unit of a store free trial, as the store states it (a one-month
/// trial is a calendar month, never "30 days").
enum StoreTrialUnit { day, week, month, year }

/// A free trial the signed-in customer is confirmed eligible for.
class StoreTrial {
  const StoreTrial({required this.unit, required this.count});

  final StoreTrialUnit unit;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is StoreTrial && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);
}

/// What the App Store sells for one server plan (matched by period).
class StoreOffer {
  const StoreOffer({
    required this.planKey,
    required this.priceString,
    this.trial,
  });

  final String planKey;

  /// Localized store price, e.g. "SAR 99.00". Apple requires showing this
  /// rather than our own catalogue price.
  final String priceString;

  /// Set only when the product starts with a free trial AND the store
  /// confirmed this customer is eligible; never assumed.
  final StoreTrial? trial;
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

/// The Apple ID's subscription belongs to another Siratie account. Policy:
/// a subscription stays with the account that bought it (RevenueCat restore
/// behaviour "Keep with original App User ID"); it is never transferred.
final class StorePurchaseOtherAccount extends StorePurchaseOutcome {
  const StorePurchaseOtherAccount();
}

final class StorePurchaseFailed extends StorePurchaseOutcome {
  const StorePurchaseFailed();
}

enum StoreRestoreOutcome {
  /// The store reports an active entitlement for this account.
  active,

  /// Nothing to restore for this Apple ID.
  none,

  /// The Apple ID's subscription belongs to another Siratie account.
  otherAccount,
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

  /// Buys [planKey] for [userId]. Fails when the offers were last loaded for
  /// another account, or when [isCurrent] (checked right before the store
  /// sheet opens, after any queued call) says [userId] is no longer signed in.
  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
    required bool Function() isCurrent,
  });

  /// Works without loaded offers, so a subscriber can recover access even
  /// when the sales catalogue is unavailable. Throws [StoreAccountChanged]
  /// when [isCurrent] turns false before the store is asked.
  Future<StoreRestoreOutcome> restore({
    required int userId,
    required bool Function() isCurrent,
  });
}

/// The signed-in account changed before the store call started.
class StoreAccountChanged implements Exception {
  const StoreAccountChanged();
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
    required bool Function() isCurrent,
  }) async =>
      const StorePurchaseFailed();

  @override
  Future<StoreRestoreOutcome> restore({
    required int userId,
    required bool Function() isCurrent,
  }) async =>
      StoreRestoreOutcome.none;
}

/// Single injection point; tests override it with a fake.
final storePurchasesProvider = Provider<StorePurchases>(
  (ref) => RevenueCatStorePurchases.fromEnvironment(),
);
