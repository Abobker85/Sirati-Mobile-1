import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';

/// RevenueCat adapter for [StorePurchases].
///
/// The public iOS SDK key comes from `--dart-define=REVENUECAT_IOS_KEY=appl_...`.
/// Without it (or off iOS) the store is unavailable and nothing is sold.
class RevenueCatStorePurchases implements StorePurchases {
  RevenueCatStorePurchases(this._apiKey);

  factory RevenueCatStorePurchases.fromEnvironment() =>
      RevenueCatStorePurchases(
        const String.fromEnvironment('REVENUECAT_IOS_KEY'),
      );

  final String _apiKey;
  final Map<String, Package> _packages = {};

  @override
  bool get isAvailable =>
      !kIsWeb && Platform.isIOS && _apiKey.trim().startsWith('appl_');

  /// Configures once, then switches the store user whenever the signed-in
  /// account changes, so a purchase is never credited to the previous user.
  Future<void> _identify(int userId) async {
    final id = '$userId';
    if (!await Purchases.isConfigured) {
      await Purchases.configure(
        PurchasesConfiguration(_apiKey.trim())..appUserID = id,
      );
      return;
    }
    if (await Purchases.appUserID != id) {
      _packages.clear();
      await Purchases.logIn(id);
    }
  }

  static PackageType? _packageTypeFor(int months) => switch (months) {
        1 => PackageType.monthly,
        2 => PackageType.twoMonth,
        3 => PackageType.threeMonth,
        6 => PackageType.sixMonth,
        12 => PackageType.annual,
        _ => null,
      };

  static int? _freeTrialDays(StoreProduct product) {
    final intro = product.introductoryPrice;
    if (intro == null || intro.price != 0) return null;
    final units = intro.periodNumberOfUnits;
    return switch (intro.periodUnit) {
      PeriodUnit.day => units,
      PeriodUnit.week => units * 7,
      PeriodUnit.month => units * 30,
      PeriodUnit.year => units * 365,
      _ => null,
    };
  }

  @override
  Future<Map<String, StoreOffer>> offersFor({
    required int userId,
    required Map<String, int> planMonths,
  }) async {
    if (!isAvailable) return const {};
    await _identify(userId);
    final offering = (await Purchases.getOfferings()).current;
    _packages.clear();
    final offers = <String, StoreOffer>{};
    if (offering == null) return offers;
    for (final MapEntry(key: planKey, value: months) in planMonths.entries) {
      final type = _packageTypeFor(months);
      if (type == null) continue;
      for (final package in offering.availablePackages) {
        if (package.packageType != type) continue;
        _packages[planKey] = package;
        offers[planKey] = StoreOffer(
          planKey: planKey,
          priceString: package.storeProduct.priceString,
          freeTrialDays: _freeTrialDays(package.storeProduct),
        );
        break;
      }
    }
    return offers;
  }

  @override
  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
  }) async {
    if (!isAvailable) return const StorePurchaseFailed();
    try {
      await _identify(userId);
      final package = _packages[planKey];
      if (package == null) return const StorePurchaseFailed();
      await Purchases.purchase(PurchaseParams.package(package));
      return const StorePurchaseCompleted();
    } on PlatformException catch (e) {
      return switch (PurchasesErrorHelper.getErrorCode(e)) {
        PurchasesErrorCode.purchaseCancelledError =>
          const StorePurchaseCancelled(),
        PurchasesErrorCode.paymentPendingError => const StorePurchasePending(),
        _ => const StorePurchaseFailed(),
      };
    }
  }

  @override
  Future<bool> restore({required int userId}) async {
    if (!isAvailable) return false;
    await _identify(userId);
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.isNotEmpty;
  }
}
