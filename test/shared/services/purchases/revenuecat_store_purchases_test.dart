import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/services/purchases/revenuecat_store_purchases.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';

/// Scripted SDK: one process-wide identity, like the real one, and a log of
/// every call so tests can check calls never interleave across accounts.
class _FakeClient implements RevenueCatClient {
  String? identity;
  final log = <String>[];
  List<RevenueCatProduct> products = const [
    RevenueCatProduct(
        productId: 'pro.month', periodMonths: 1, priceString: 'SAR 29'),
    RevenueCatProduct(
      productId: 'pro.half',
      periodMonths: 6,
      priceString: 'SAR 99',
      freeTrial: StoreTrial(unit: StoreTrialUnit.month, count: 1),
    ),
    RevenueCatProduct(
      productId: 'pro.year',
      periodMonths: 12,
      priceString: 'SAR 149',
      freeTrial: StoreTrial(unit: StoreTrialUnit.day, count: 3),
    ),
  ];

  /// Ids the store confirms eligible; an Exception makes the check fail.
  Object eligible = const <String>{};
  final eligibilityAsked = <List<String>>[];

  /// When set, the next product read waits on it (simulates a slow store).
  Completer<void>? gate;
  Object? identifyError;
  StorePurchaseOutcome purchaseOutcome = const StorePurchaseCompleted();
  StoreRestoreOutcome restoreOutcome = StoreRestoreOutcome.none;

  @override
  Future<void> identify(String appUserId) async {
    log.add('identify $appUserId');
    final error = identifyError;
    if (error != null) {
      identifyError = null;
      throw error;
    }
    identity = appUserId;
  }

  @override
  Future<List<RevenueCatProduct>> currentProducts() async {
    final asking = identity;
    final wait = gate;
    gate = null;
    if (wait != null) await wait.future;
    log.add('products $asking->$identity');
    return products;
  }

  @override
  Future<Set<String>> trialEligible(List<String> productIds) async {
    eligibilityAsked.add(productIds);
    final e = eligible;
    if (e is Set<String>) return e;
    throw e;
  }

  @override
  Future<StorePurchaseOutcome> purchase(String productId) async {
    log.add('purchase $productId as $identity');
    return purchaseOutcome;
  }

  @override
  Future<StoreRestoreOutcome> restore() async {
    log.add('restore as $identity');
    return restoreOutcome;
  }
}

const _plans = {'monthly': 1, 'semiannual': 6, 'annual': 12};

bool _always() => true;

void main() {
  late _FakeClient client;
  late RevenueCatStorePurchases store;

  setUp(() {
    client = _FakeClient();
    store = RevenueCatStorePurchases(available: true, client: client);
  });

  test('without a key or off iOS nothing reaches the SDK', () async {
    final off = RevenueCatStorePurchases(available: false, client: client);
    expect(await off.offersFor(userId: 1, planMonths: _plans), isEmpty);
    expect(
        await off.purchase(userId: 1, planKey: 'monthly', isCurrent: _always),
        isA<StorePurchaseFailed>());
    expect(await off.restore(userId: 1, isCurrent: _always),
        StoreRestoreOutcome.none);
    expect(client.log, isEmpty);
  });

  test('plans match store products by period; unknown periods are absent',
      () async {
    final offers = await store.offersFor(
        userId: 1, planMonths: {..._plans, 'quarterly': 3, 'weekly': 0});
    expect(offers.keys, unorderedEquals(['monthly', 'semiannual', 'annual']));
    expect(offers['semiannual']!.priceString, 'SAR 99');
    expect(offers['annual']!.planKey, 'annual');
  });

  group('free trial', () {
    test('only products the store confirms eligible show a trial', () async {
      client.eligible = {'pro.half'};
      final offers = await store.offersFor(userId: 1, planMonths: _plans);
      expect(offers['semiannual']!.trial,
          const StoreTrial(unit: StoreTrialUnit.month, count: 1));
      expect(offers['annual']!.trial, isNull, reason: 'Ineligible or unknown');
      expect(offers['monthly']!.trial, isNull, reason: 'No intro offer');
      expect(client.eligibilityAsked.single,
          unorderedEquals(['pro.half', 'pro.year']),
          reason: 'Only products with a free intro offer are checked');
    });

    test('a failed eligibility check never promises a trial', () async {
      client.eligible = Exception('store offline');
      final offers = await store.offersFor(userId: 1, planMonths: _plans);
      expect(offers.values.map((o) => o.trial), everyElement(isNull));
      expect(offers, hasLength(3), reason: 'Prices still load');
    });

    test('no intro offers means no eligibility call', () async {
      client.products = [
        for (final p in client.products)
          RevenueCatProduct(
              productId: p.productId,
              periodMonths: p.periodMonths,
              priceString: p.priceString),
      ];
      await store.offersFor(userId: 1, planMonths: _plans);
      expect(client.eligibilityAsked, isEmpty);
    });
  });

  group('identity', () {
    test('overlapping loads for two accounts never interleave', () async {
      final gate = client.gate = Completer<void>();
      final first = store.offersFor(userId: 1, planMonths: _plans);
      final second = store.offersFor(userId: 2, planMonths: _plans);
      await pumpEventQueue();
      expect(client.log, ['identify 1'],
          reason: 'Account 2 waits while account 1 reads the store');
      gate.complete();
      await Future.wait([first, second]);
      expect(client.log, [
        'identify 1',
        'products 1->1',
        'identify 2',
        'products 2->2',
      ]);
    });

    test('buys only for the account the offers were loaded for', () async {
      await store.offersFor(userId: 1, planMonths: _plans);
      await store.offersFor(userId: 2, planMonths: _plans);
      final stale = await store.purchase(
          userId: 1, planKey: 'monthly', isCurrent: _always);
      expect(stale, isA<StorePurchaseFailed>());
      expect(client.log.where((e) => e.startsWith('purchase')), isEmpty);

      final ok = await store.purchase(
          userId: 2, planKey: 'annual', isCurrent: _always);
      expect(ok, isA<StorePurchaseCompleted>());
      expect(client.log.last, 'purchase pro.year as 2');
    });

    test('a purchase queued behind another account load is refused', () async {
      await store.offersFor(userId: 1, planMonths: _plans);
      client.gate = Completer<void>();
      final reload = store.offersFor(userId: 2, planMonths: _plans);
      final buy =
          store.purchase(userId: 1, planKey: 'monthly', isCurrent: _always);
      client.gate!.complete();
      await reload;
      expect(await buy, isA<StorePurchaseFailed>());
      expect(client.log.where((e) => e.startsWith('purchase')), isEmpty);
    });

    test('a purchase before any offers, or for an unknown plan, fails',
        () async {
      expect(
          await store.purchase(
              userId: 1, planKey: 'monthly', isCurrent: _always),
          isA<StorePurchaseFailed>());
      await store.offersFor(userId: 1, planMonths: _plans);
      expect(
          await store.purchase(
              userId: 1, planKey: 'lifetime', isCurrent: _always),
          isA<StorePurchaseFailed>());
      expect(client.log.where((e) => e.startsWith('purchase')), isEmpty);
    });

    test('store outcomes pass through; a thrown SDK error is a failure',
        () async {
      await store.offersFor(userId: 1, planMonths: _plans);
      for (final outcome in const <StorePurchaseOutcome>[
        StorePurchaseCancelled(),
        StorePurchasePending(),
        StorePurchaseOtherAccount(),
      ]) {
        client.purchaseOutcome = outcome;
        expect(
            await store.purchase(
                userId: 1, planKey: 'monthly', isCurrent: _always),
            outcome);
      }
      client.identifyError = Exception('sdk');
      expect(
          await store.purchase(
              userId: 1, planKey: 'monthly', isCurrent: _always),
          isA<StorePurchaseFailed>());
    });

    test('restore needs no offers and runs as the given account', () async {
      for (final outcome in StoreRestoreOutcome.values) {
        client.restoreOutcome = outcome;
        expect(await store.restore(userId: 9, isCurrent: _always), outcome);
        expect(client.log.last, 'restore as 9');
      }
    });

    test('a session that ended before the store call never buys or restores',
        () async {
      await store.offersFor(userId: 1, planMonths: _plans);
      final calls = client.log.length;
      expect(
          await store.purchase(
              userId: 1, planKey: 'monthly', isCurrent: () => false),
          isA<StorePurchaseFailed>());
      await expectLater(store.restore(userId: 1, isCurrent: () => false),
          throwsA(isA<StoreAccountChanged>()));
      expect(client.log.length, calls, reason: 'The SDK is never asked');
    });

    test('a session that ends while queued or identifying never buys',
        () async {
      await store.offersFor(userId: 1, planMonths: _plans);
      var signedIn = true;
      // Queued behind a slow reload of the same account.
      final gate = client.gate = Completer<void>();
      final reload = store.offersFor(userId: 1, planMonths: _plans);
      final queued = store.purchase(
          userId: 1, planKey: 'monthly', isCurrent: () => signedIn);
      signedIn = false;
      gate.complete();
      await reload;
      expect(await queued, isA<StorePurchaseFailed>());

      // Ends during the async identify step, right before the sheet.
      var calls = 0;
      final ending = store.purchase(
          userId: 1, planKey: 'monthly', isCurrent: () => ++calls == 1);
      expect(await ending, isA<StorePurchaseFailed>());
      expect(client.log.where((e) => e.startsWith('purchase')), isEmpty);
    });

    test('restore checks the session again after identifying', () async {
      var calls = 0;
      await expectLater(store.restore(userId: 1, isCurrent: () => ++calls == 1),
          throwsA(isA<StoreAccountChanged>()));
      expect(client.log.where((e) => e.startsWith('restore')), isEmpty);
    });

    test('a failed call does not block the calls queued after it', () async {
      client.identifyError = Exception('offline');
      final failing = store.offersFor(userId: 1, planMonths: _plans);
      final next = store.restore(userId: 1, isCurrent: _always);
      await expectLater(failing, throwsException);
      expect(await next, StoreRestoreOutcome.none);
    });
  });
}
