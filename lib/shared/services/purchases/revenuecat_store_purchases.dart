import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';

/// One App Store product in the current RevenueCat offering.
class RevenueCatProduct {
  const RevenueCatProduct({
    required this.productId,
    required this.periodMonths,
    required this.priceString,
    this.freeTrial,
  });

  final String productId;
  final int periodMonths;
  final String priceString;

  /// The product's free introductory offer; eligibility not yet checked.
  final StoreTrial? freeTrial;
}

/// The RevenueCat SDK calls the adapter makes; tests replace it.
abstract interface class RevenueCatClient {
  /// Configures on first use, then logs in as [appUserId] when it differs.
  Future<void> identify(String appUserId);

  /// Products of the current offering whose package has a known period.
  Future<List<RevenueCatProduct>> currentProducts();

  /// The ids, among [productIds], the store CONFIRMS the current customer is
  /// eligible to start a free trial for. Unknown counts as not eligible.
  Future<Set<String>> trialEligible(List<String> productIds);

  Future<StorePurchaseOutcome> purchase(String productId);

  Future<StoreRestoreOutcome> restore();
}

/// RevenueCat adapter for [StorePurchases].
///
/// The SDK holds one process-wide identity, so every call runs one at a
/// time: identify → read or buy. Offers remember the account they were
/// loaded for; a purchase for any other account fails instead of buying
/// under a stale identity.
///
/// The public iOS SDK key comes from `--dart-define=REVENUECAT_IOS_KEY=appl_...`.
/// Without it (or off iOS) the store is unavailable and nothing is sold.
class RevenueCatStorePurchases implements StorePurchases {
  RevenueCatStorePurchases({
    required bool available,
    required RevenueCatClient client,
  })  : _available = available,
        _client = client;

  factory RevenueCatStorePurchases.fromEnvironment() {
    const key = String.fromEnvironment('REVENUECAT_IOS_KEY');
    return RevenueCatStorePurchases(
      available: !kIsWeb && Platform.isIOS && key.trim().startsWith('appl_'),
      client: SdkRevenueCatClient(key.trim()),
    );
  }

  final bool _available;
  final RevenueCatClient _client;

  Future<void> _tail = Future<void>.value();

  /// Account the offers below were loaded for.
  int? _offersUser;
  Map<String, String> _productByPlan = const {};

  @override
  bool get isAvailable => _available;

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _identify(int userId) async {
    if (_offersUser != userId) {
      _offersUser = null;
      _productByPlan = const {};
    }
    await _client.identify('$userId');
  }

  @override
  Future<Map<String, StoreOffer>> offersFor({
    required int userId,
    required Map<String, int> planMonths,
  }) {
    if (!isAvailable) return Future.value(const {});
    return _serial(() async {
      await _identify(userId);
      final products = await _client.currentProducts();
      final chosen = <String, RevenueCatProduct>{};
      for (final MapEntry(key: planKey, value: months) in planMonths.entries) {
        for (final product in products) {
          if (product.periodMonths != months) continue;
          chosen[planKey] = product;
          break;
        }
      }
      final withTrial = [
        for (final p in chosen.values)
          if (p.freeTrial != null) p.productId,
      ];
      Set<String> eligible;
      try {
        eligible = withTrial.isEmpty
            ? const {}
            : await _client.trialEligible(withTrial);
      } catch (_) {
        eligible = const {}; // Unknown: never promise a trial.
      }
      _offersUser = userId;
      _productByPlan = {
        for (final e in chosen.entries) e.key: e.value.productId,
      };
      return {
        for (final MapEntry(key: planKey, value: p) in chosen.entries)
          planKey: StoreOffer(
            planKey: planKey,
            priceString: p.priceString,
            trial: eligible.contains(p.productId) ? p.freeTrial : null,
          ),
      };
    });
  }

  @override
  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
    required bool Function() isCurrent,
  }) {
    if (!isAvailable) return Future.value(const StorePurchaseFailed());
    return _serial(() async {
      final productId = _productByPlan[planKey];
      if (_offersUser != userId || productId == null || !isCurrent()) {
        return const StorePurchaseFailed();
      }
      try {
        await _identify(userId);
        // Identifying is async: check again right before the sheet opens.
        if (!isCurrent()) return const StorePurchaseFailed();
        return await _client.purchase(productId);
      } catch (_) {
        return const StorePurchaseFailed();
      }
    });
  }

  @override
  Future<StoreRestoreOutcome> restore({
    required int userId,
    required bool Function() isCurrent,
  }) {
    if (!isAvailable) return Future.value(StoreRestoreOutcome.none);
    return _serial(() async {
      if (!isCurrent()) throw const StoreAccountChanged();
      await _identify(userId);
      if (!isCurrent()) throw const StoreAccountChanged();
      return _client.restore();
    });
  }
}

/// The real SDK behind [RevenueCatClient].
class SdkRevenueCatClient implements RevenueCatClient {
  SdkRevenueCatClient(this._apiKey);

  final String _apiKey;
  final Map<String, Package> _packages = {};

  static const _otherAccountCodes = {
    PurchasesErrorCode.receiptAlreadyInUseError,
    PurchasesErrorCode.receiptInUseByOtherSubscriberError,
  };

  @override
  Future<void> identify(String appUserId) async {
    if (!await Purchases.isConfigured) {
      await Purchases.configure(
        PurchasesConfiguration(_apiKey)..appUserID = appUserId,
      );
      return;
    }
    if (await Purchases.appUserID != appUserId) {
      await Purchases.logIn(appUserId);
    }
  }

  static int? _months(PackageType type) => switch (type) {
        PackageType.monthly => 1,
        PackageType.twoMonth => 2,
        PackageType.threeMonth => 3,
        PackageType.sixMonth => 6,
        PackageType.annual => 12,
        _ => null,
      };

  static StoreTrial? _freeTrial(StoreProduct product) {
    final intro = product.introductoryPrice;
    if (intro == null || intro.price != 0 || intro.periodNumberOfUnits < 1) {
      return null;
    }
    final unit = switch (intro.periodUnit) {
      PeriodUnit.day => StoreTrialUnit.day,
      PeriodUnit.week => StoreTrialUnit.week,
      PeriodUnit.month => StoreTrialUnit.month,
      PeriodUnit.year => StoreTrialUnit.year,
      PeriodUnit.unknown => null,
    };
    if (unit == null) return null;
    return StoreTrial(unit: unit, count: intro.periodNumberOfUnits);
  }

  @override
  Future<List<RevenueCatProduct>> currentProducts() async {
    final offering = (await Purchases.getOfferings()).current;
    _packages.clear();
    if (offering == null) return const [];
    final products = <RevenueCatProduct>[];
    for (final package in offering.availablePackages) {
      final months = _months(package.packageType);
      if (months == null) continue;
      final product = package.storeProduct;
      _packages[product.identifier] = package;
      products.add(RevenueCatProduct(
        productId: product.identifier,
        periodMonths: months,
        priceString: product.priceString,
        freeTrial: _freeTrial(product),
      ));
    }
    return products;
  }

  @override
  Future<Set<String>> trialEligible(List<String> productIds) async {
    final statuses =
        await Purchases.checkTrialOrIntroductoryPriceEligibility(productIds);
    return {
      for (final MapEntry(key: id, value: e) in statuses.entries)
        if (e.status == IntroEligibilityStatus.introEligibilityStatusEligible)
          id,
    };
  }

  @override
  Future<StorePurchaseOutcome> purchase(String productId) async {
    final package = _packages[productId];
    if (package == null) return const StorePurchaseFailed();
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      return const StorePurchaseCompleted();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (_otherAccountCodes.contains(code)) {
        return const StorePurchaseOtherAccount();
      }
      return switch (code) {
        PurchasesErrorCode.purchaseCancelledError =>
          const StorePurchaseCancelled(),
        PurchasesErrorCode.paymentPendingError => const StorePurchasePending(),
        _ => const StorePurchaseFailed(),
      };
    }
  }

  @override
  Future<StoreRestoreOutcome> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty
          ? StoreRestoreOutcome.active
          : StoreRestoreOutcome.none;
    } on PlatformException catch (e) {
      if (_otherAccountCodes.contains(PurchasesErrorHelper.getErrorCode(e))) {
        return StoreRestoreOutcome.otherAccount;
      }
      rethrow;
    }
  }
}
