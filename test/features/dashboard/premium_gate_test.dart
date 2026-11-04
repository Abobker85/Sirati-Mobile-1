import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/dashboard/application/premium_gate_controller.dart';
import 'package:sirati/features/dashboard/data/subscription_plans_repository.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/non_text_contrast.dart';

Map<String, dynamic> planJson(
  String key, {
  Object? months = 1,
  Object? price = 19.99,
  Object? perMonth,
  bool isDefault = false,
  String? badgeEn,
  String? badgeAr,
}) =>
    {
      'key': key,
      'product_id': 'sirati_$key',
      'period_months': months,
      'price': price,
      'price_per_month': perMonth,
      'name_ar': 'خطة $key',
      'name_en': 'Plan $key',
      'badge_ar': badgeAr,
      'badge_en': badgeEn,
      'is_default': isDefault,
      'currency': 'SAR',
    };

Map<String, dynamic> offerJson({
  List<Map<String, dynamic>>? plans,
  int trialDays = 3,
  Object? access = const {'is_subscribed': false},
}) =>
    {
      'data': {
        'plans': plans ??
            [
              planJson('monthly'),
              planJson(
                'semiannual',
                months: 6,
                price: 99,
                perMonth: 16.5,
                isDefault: true,
                badgeEn: 'Most popular',
                badgeAr: 'الأكثر شيوعاً',
              ),
              planJson('annual', months: 12, price: 179, perMonth: 14.92),
            ],
        'currency': 'SAR',
        'trial_days': trialDays,
        'access': access,
      },
    };

class _FakePlans extends SubscriptionPlansRepository {
  _FakePlans(this.responses);

  /// Each load consumes the head (the last entry repeats): an offer JSON map
  /// or an error to throw.
  final List<Object> responses;
  int loads = 0;

  @override
  Future<SubscriptionOffer> load() async {
    loads++;
    final next =
        responses.length == 1 ? responses.first : responses.removeAt(0);
    if (next is Map<String, dynamic>) return SubscriptionOffer.fromJson(next);
    throw next;
  }
}

class _FakeAuth extends AuthApiService {
  _FakeAuth([this.subscription]);

  Map<String, dynamic>? subscription;
  Object? error;
  Future<AuthUser?>? pending;
  int calls = 0;

  /// The account signed in right now; tests switch it mid-screen.
  int id = 1;

  @override
  Future<AuthUser?> me() async {
    calls++;
    if (pending != null) return pending!;
    if (error != null) throw error!;
    return AuthUser(
      id: id,
      name: 'Sara',
      email: 'sara@x.io',
      subscription: subscription,
    );
  }
}

/// Store fake: offers per plan key, a scripted purchase outcome (or error),
/// and a record of what was bought for which account.
class _FakeStore implements StorePurchases {
  _FakeStore({
    Map<String, StoreOffer>? offers,
    this.outcome = const StorePurchaseCompleted(),
    this.restoreOutcome = StoreRestoreOutcome.none,
  }) : offers = offers ?? _storeOffers();

  Map<String, StoreOffer> offers;
  Object outcome;
  Object restoreOutcome;
  Object? offersError;
  Completer<StorePurchaseOutcome>? pendingPurchase;
  final purchases = <(int, String)>[];
  final offerRequests = <(int, Map<String, int>)>[];
  final restores = <int>[];

  @override
  bool get isAvailable => true;

  @override
  Future<Map<String, StoreOffer>> offersFor({
    required int userId,
    required Map<String, int> planMonths,
  }) async {
    offerRequests.add((userId, planMonths));
    if (offersError != null) throw offersError!;
    return offers;
  }

  @override
  Future<StorePurchaseOutcome> purchase({
    required int userId,
    required String planKey,
  }) async {
    purchases.add((userId, planKey));
    if (pendingPurchase != null) return pendingPurchase!.future;
    final next = outcome;
    if (next is StorePurchaseOutcome) return next;
    throw next;
  }

  @override
  Future<StoreRestoreOutcome> restore({required int userId}) async {
    restores.add(userId);
    final next = restoreOutcome;
    if (next is StoreRestoreOutcome) return next;
    throw next;
  }
}

Map<String, StoreOffer> _storeOffers({
  Iterable<String> keys = const ['monthly', 'semiannual', 'annual'],
  bool withTrial = true,
  StoreTrial trial = _threeDays,
}) =>
    {
      for (final key in keys)
        key: StoreOffer(
          planKey: key,
          priceString: 'SAR $key.price',
          trial: withTrial ? trial : null,
        ),
    };

const _threeDays = StoreTrial(unit: StoreTrialUnit.day, count: 3);

const _fastScreen = PremiumGateScreen(
  confirmDelay: Duration.zero,
  confirmAttempts: 3,
);

ButtonStyleButton _button(WidgetTester tester, Key key) =>
    tester.widget<ButtonStyleButton>(find.byKey(key));

class _Routes {
  final opened = <String>[];

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    opened.add(settings.name ?? '');
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(body: Text('route ${settings.name}')),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakePlans plans,
  _FakeAuth? auth,
  String language = 'en',
  ThemeData? theme,
  _Routes? routes,
  bool pushed = false,
  bool keepView = false,
  StorePurchases store = const UnavailableStorePurchases(),
  Widget screen = const PremiumGateScreen(),
}) async {
  if (!keepView) {
    usePhoneViewAtTextScale(tester);
  }
  final arabic = language == 'ar';
  await tester.pumpWidget(ProviderScope(
    // A fresh scope (and screen state) per pump.
    key: UniqueKey(),
    overrides: [
      subscriptionPlansRepositoryProvider.overrideWithValue(plans),
      authApiServiceProvider.overrideWithValue(auth ?? _FakeAuth()),
      storePurchasesProvider.overrideWithValue(store),
    ],
    child: MaterialApp(
      builder: (_, child) => RepaintBoundary(key: phonePaintKey, child: child!),
      theme: theme ?? AppTheme.lightFor(arabic: arabic),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateRoute: (routes ?? _Routes()).onGenerateRoute,
      home: pushed
          ? Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => screen,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            )
          : screen,
    ),
  ));
  await tester.pump();
  if (pushed) {
    await tester.tap(find.text('open'));
  }
  await tester.pumpAndSettle();
}

AppLocalizations _l(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PremiumGateScreen)));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await revealPhoneWidget(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('Screen catalogues preserve translations and the same message keys', () {
    final catalogues = [
      for (final language in ['ar', 'en'])
        (jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
                as Map)
            .entries
            .where((entry) => ['premiumGate', 'cvHub', 'jobMatchFailed']
                .any((prefix) => (entry.key as String).startsWith(prefix))),
    ];
    expect(catalogues.first.map((entry) => entry.key).toSet(),
        catalogues.last.map((entry) => entry.key).toSet());
    for (final catalogue in catalogues) {
      for (final entry in catalogue) {
        expect(entry.value, isA<String>());
        expect((entry.value as String).trim(), isNotEmpty);
        // Reject encoding-loss markers, regardless of the message content.
        expect(entry.value, isNot(contains('\uFFFD')), reason: '${entry.key}');
        expect(entry.value, isNot(matches(RegExp(r'\?{2,}'))),
            reason: '${entry.key}');
      }
    }
  });

  group('SubscriptionOffer.fromJson', () {
    test('keeps exactly the well-formed plans, once each, in order', () {
      final rng = Random(7);
      for (var round = 0; round < 200; round++) {
        final raw = <Map<String, dynamic>>[];
        final expected = <String>[];
        final seen = <String>{};
        for (var i = 0; i < rng.nextInt(8); i++) {
          final key = ['a', 'b', 'c', 'd', '', '  '][rng.nextInt(6)];
          final months = [1, 6, 12, 0, -3, null, '6', 'x'][rng.nextInt(8)];
          final price = [19.99, 99, '179', 0, -1, null, 'free'][rng.nextInt(7)];
          raw.add(planJson(key, months: months, price: price));
          final monthsValue = months is int ? months : int.tryParse('$months');
          final monthsOk = monthsValue != null && monthsValue > 0;
          final priceValue = price is num ? price : double.tryParse('$price');
          final valid = key.trim().isNotEmpty &&
              monthsOk &&
              priceValue != null &&
              priceValue > 0;
          if (valid && seen.add(key)) expected.add(key);
        }
        final offer = SubscriptionOffer.fromJson(offerJson(plans: raw));
        expect(
          [for (final p in offer.plans) p.key],
          expected,
          reason: 'round $round: $raw',
        );
        for (final plan in offer.plans) {
          expect(plan.price, greaterThan(0));
          expect(plan.periodMonths, greaterThan(0));
        }
      }
    });

    test('access is granted only by an explicit is_subscribed: true', () {
      for (final access in <Object?>[
        null,
        const {},
        'true',
        true,
        const {'is_subscribed': 'true'},
        const {'is_subscribed': 1},
        const {'is_subscribed': null},
        const {'is_subscribed': false},
        const {'is_subscribed': true},
      ]) {
        final explicit =
            access is Map && identical(access['is_subscribed'], true);
        expect(
          SubscriptionOffer.fromJson(offerJson(access: access)).subscribed,
          explicit,
          reason: '$access',
        );
        expect(
          isSubscriptionActive(
            access is Map<String, dynamic> ? access : null,
          ),
          explicit,
          reason: '$access',
        );
      }
    });

    test('malformed payloads never throw and yield no plans', () {
      for (final json in <Map<String, dynamic>>[
        const {},
        const {'data': null},
        const {'data': 'x'},
        const {
          'data': {'plans': 'x'},
        },
        const {
          'data': {
            'plans': [1, 'a', null],
          },
        },
      ]) {
        final offer = SubscriptionOffer.fromJson(json);
        expect(offer.plans, isEmpty, reason: '$json');
        expect(offer.subscribed, isFalse);
        expect(offer.defaultPlan, isNull);
      }
    });

    test('default plan is the flagged one, else the first', () {
      for (var flagged = -1; flagged < 3; flagged++) {
        final offer = SubscriptionOffer.fromJson(offerJson(plans: [
          for (var i = 0; i < 3; i++) planJson('p$i', isDefault: i == flagged),
        ]));
        expect(offer.defaultPlan!.key, flagged < 0 ? 'p0' : 'p$flagged');
      }
    });

    test('negative trial days clamp to zero', () {
      for (final days in [-30, -1, 0, 1, 14]) {
        expect(
          SubscriptionOffer.fromJson(offerJson(trialDays: days)).trialDays,
          max(0, days),
        );
      }
    });
  });

  test('formatPlanPrice round-trips cents with Latin digits', () {
    final rng = Random(11);
    for (var i = 0; i < 2000; i++) {
      final cents = rng.nextInt(10000000) + 1;
      final text = formatPlanPrice(cents / 100);
      expect(text, matches(RegExp(r'^[0-9]+(\.[0-9]{2})?$')), reason: text);
      expect((double.parse(text) * 100).round(), cents, reason: text);
      expect(text.contains('.'), cents % 100 != 0, reason: text);
    }
  });

  group('PremiumGateScreen', () {
    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final arabic = language == 'ar';
        final theme = dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic);
        final label = '$language/${dark ? 'dark' : 'light'}';

        testWidgets(
            '$label: informational plans and honest actions on a 2x phone',
            (tester) async {
          final auth = _FakeAuth();
          await _pump(tester,
              plans: _FakePlans([offerJson()]),
              auth: auth,
              language: language,
              theme: theme);
          final l = _l(tester);
          expect(
              Directionality.of(tester.element(find.byType(PremiumGateScreen))),
              arabic ? TextDirection.rtl : TextDirection.ltr);
          await inspectPhoneScreen(tester, label);
          for (final key in ['monthly', 'semiannual', 'annual']) {
            final plan = find.byKey(PremiumGateScreen.planKey(key));
            await revealPhoneWidget(tester, plan);
            expect(find.descendant(of: plan, matching: find.byType(InkWell)),
                findsNothing,
                reason: 'Plans are information, not purchase choices');
            expect(find.descendant(of: plan, matching: find.byType(Checkbox)),
                findsNothing);
            expect(
                find.byIcon(Icons.radio_button_checked_rounded), findsNothing);
            await tester.tap(plan);
            await tester.pump();
          }
          expect(auth.calls, 0);
          await revealPhoneWidget(
              tester, find.textContaining(l.premiumGateAvailabilityNote));
          expect(find.textContaining(l.premiumGatePriceNote), findsOneWidget);
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.refreshKey));
          expect(
              tester
                  .widget<ElevatedButton>(
                      find.byKey(PremiumGateScreen.refreshKey))
                  .enabled,
              isTrue);
          // Every action belongs to the supported refresh/navigation set.
          // No catalog wording is used as a heuristic to infer a purchase.
          final allowed = {
            l.premiumGateRefresh,
            l.premiumGateRefreshing,
            l.premiumGateRetry,
            l.premiumGateNotNow,
            l.premiumGatePrivacy,
            l.premiumGateContinue
          };
          for (final button in find
              .byWidgetPredicate((widget) => widget is ButtonStyleButton)
              .evaluate()) {
            for (final text in find
                .descendant(
                    of: find.byWidget(button.widget),
                    matching: find.byType(Text))
                .evaluate()) {
              expect(allowed, contains((text.widget as Text).data));
            }
          }
          await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
          expect(auth.calls, 1);
          await revealPhoneWidget(tester, find.text(l.premiumGateNotFound));
          expect(find.byKey(PremiumGateScreen.continueKey), findsNothing);
          await inspectPhoneScreen(tester, '$label refreshed');
        });

        testWidgets(
            '$label: pending refresh remains legible and cannot be submitted twice',
            (tester) async {
          final completer = Completer<AuthUser?>();
          final auth = _FakeAuth()..pending = completer.future;
          await _pump(tester,
              plans: _FakePlans([offerJson()]),
              auth: auth,
              language: language,
              theme: theme);
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.refreshKey));
          await tester.tap(find.byKey(PremiumGateScreen.refreshKey));
          await tester.pump();
          expect(
              tester
                  .widget<ElevatedButton>(
                      find.byKey(PremiumGateScreen.refreshKey))
                  .enabled,
              isFalse);
          await tester.tap(find.byKey(PremiumGateScreen.refreshKey));
          await tester.pump();
          expect(auth.calls, 1);
          await inspectPhoneScreen(tester, '$label checking access');
          completer.complete(const AuthUser(
              id: 1,
              name: 'Sara',
              email: 'sara@example.test',
              subscription: {'is_subscribed': true}));
          await tester.pumpAndSettle();
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.continueKey));
          expect(auth.calls, 1);
        });

        testWidgets('$label: retry and active actions are reachable at 2x',
            (tester) async {
          final plans = _FakePlans([Exception('offline'), offerJson()]);
          final auth = _FakeAuth(const {'is_subscribed': true});
          await _pump(tester,
              plans: plans,
              auth: auth,
              language: language,
              theme: theme,
              pushed: true);
          await _tap(tester, find.byKey(PremiumGateScreen.retryKey));
          expect(plans.loads, 2);
          await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
          expect(auth.calls, 1);
          await inspectPhoneScreen(tester, '$label active');
          await _tap(tester, find.byKey(PremiumGateScreen.continueKey));
          expect(find.byType(PremiumGateScreen), findsNothing);
        });
      }
    }

    testWidgets('each refresh re-reads entitlement, including revocation',
        (tester) async {
      final auth = _FakeAuth();
      await _pump(tester, plans: _FakePlans([offerJson()]), auth: auth);
      for (final (subscription, active) in <(Map<String, dynamic>?, bool)>[
        (null, false),
        (const {}, false),
        (const {'is_subscribed': 'true'}, false),
        (const {'is_subscribed': 1}, false),
        (const {'is_subscribed': false, 'can_job_match': true}, false),
        (const {'is_subscribed': true}, true),
        (const {'is_subscribed': false}, false),
      ]) {
        final calls = auth.calls;
        auth.subscription = subscription;
        await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
        expect(auth.calls, calls + 1);
        await revealPhoneWidget(
            tester, find.byKey(PremiumGateScreen.refreshKey));
        if (active) {
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.continueKey));
          expect(find.byKey(PremiumGateScreen.continueKey), findsOneWidget);
        } else {
          expect(find.byKey(PremiumGateScreen.continueKey), findsNothing);
          await revealPhoneWidget(
              tester, find.text(_l(tester).premiumGateNotFound));
        }
      }
    });

    testWidgets('refresh failure stays locked and can be retried',
        (tester) async {
      final auth = _FakeAuth()..error = Exception('offline');
      await _pump(tester, plans: _FakePlans([offerJson()]), auth: auth);
      await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
      await revealPhoneWidget(
          tester, find.text(_l(tester).premiumGateRefreshFailed));
      expect(find.byKey(PremiumGateScreen.continueKey), findsNothing);
      auth.error = null;
      auth.subscription = const {'is_subscribed': true};
      await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
      expect(auth.calls, 2);
      await revealPhoneWidget(
          tester, find.byKey(PremiumGateScreen.continueKey));
    });

    testWidgets('empty plans, Privacy and Not now remain reachable',
        (tester) async {
      final routes = _Routes();
      await _pump(tester,
          plans: _FakePlans([offerJson(plans: [])]), routes: routes);
      await revealPhoneWidget(tester, find.text(_l(tester).premiumGateNoPlans));
      await _tap(tester, find.byKey(PremiumGateScreen.privacyKey));
      expect(routes.opened, [AppRoutes.privacy]);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(PremiumGateScreen.notNowKey));
      expect(routes.opened.last, AppRoutes.home);
    });
  });

  group('PremiumGateScreen selling through the store', () {
    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final arabic = language == 'ar';
        final theme = dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic);
        final label = '$language/${dark ? 'dark' : 'light'}';

        testWidgets('$label: store plans, purchase states and contrast',
            (tester) async {
          final store = _FakeStore()
            ..pendingPurchase = Completer<StorePurchaseOutcome>();
          final auth = _FakeAuth();
          await _pump(tester,
              plans: _FakePlans([offerJson()]),
              auth: auth,
              store: store,
              language: language,
              theme: theme,
              screen: _fastScreen);
          final l = _l(tester);
          expect(store.offerRequests.single.$1, 1,
              reason: 'Store user is the signed-in account');
          // Informational copy is gone once the build can sell.
          expect(
              find.textContaining(l.premiumGateAvailabilityNote), findsNothing);
          expect(find.byKey(PremiumGateScreen.refreshKey), findsNothing);
          for (final key in ['monthly', 'semiannual', 'annual']) {
            await revealPhoneWidget(
                tester, find.byKey(PremiumGateScreen.planKey(key)));
            expect(
                find.descendant(
                    of: find.byKey(PremiumGateScreen.planKey(key)),
                    matching: find.textContaining('SAR $key.price')),
                findsOneWidget);
          }
          await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
          expect(find.text(l.premiumGateStartTrial), findsOneWidget);
          expect(find.text(l.premiumGateTrial(l.premiumGateTrialDays(3))),
              findsOneWidget);
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.termsKey));
          expect(find.byKey(PremiumGateScreen.restoreKey), findsOneWidget);
          expect(find.byKey(PremiumGateScreen.privacyKey), findsOneWidget);
          await inspectPhoneScreen(tester, '$label store');

          // The spinner never settles while the store sheet is open.
          await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(PremiumGateScreen.buyKey));
          await tester.pump();
          expect(find.text(l.premiumGatePurchasing), findsOneWidget);
          expect(_button(tester, PremiumGateScreen.buyKey).enabled, isFalse);
          await tester.tap(find.byKey(PremiumGateScreen.buyKey));
          await tester.pump();
          expect(store.purchases, hasLength(1), reason: 'No double purchase');
          await inspectPhoneScreen(tester, '$label purchasing');

          auth.subscription = const {'is_subscribed': true};
          store.pendingPurchase!.complete(const StorePurchaseCompleted());
          await tester.pumpAndSettle();
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.successKey));
          expect(find.text(l.premiumGateSuccessTitle), findsOneWidget);
          expect(find.text(l.premiumGateSuccessSyncing), findsNothing);
          await inspectPhoneScreen(tester, '$label success');
        });
      }
    }

    testWidgets('buys exactly the chosen plan for the signed-in account',
        (tester) async {
      for (final key in ['monthly', 'semiannual', 'annual']) {
        final store = _FakeStore(outcome: const StorePurchaseCancelled());
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            store: store,
            screen: _fastScreen);
        await _tap(tester, find.byKey(PremiumGateScreen.planKey(key)));
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(store.purchases, [(1, key)]);
      }
    });

    testWidgets('default selection is the flagged plan the store sells',
        (tester) async {
      // semiannual is flagged default; when the store lacks it, the first
      // plan the store sells is preselected instead.
      for (final (keys, expected) in [
        (['monthly', 'semiannual', 'annual'], 'semiannual'),
        (['monthly', 'annual'], 'monthly'),
        (['annual'], 'annual'),
      ]) {
        final store = _FakeStore(
            offers: _storeOffers(keys: keys),
            outcome: const StorePurchaseCancelled());
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            store: store,
            screen: _fastScreen);
        // All plan cards share one list item with the buy button.
        await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
        for (final key in ['monthly', 'semiannual', 'annual']) {
          expect(
              find.byKey(PremiumGateScreen.planKey(key), skipOffstage: false),
              keys.contains(key) ? findsOneWidget : findsNothing,
              reason: 'Only plans the store sells are choices');
        }
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(store.purchases.single.$2, expected);
      }
    });

    testWidgets('without a free trial the button and notice say so',
        (tester) async {
      await _pump(tester,
          plans: _FakePlans([offerJson()]),
          store: _FakeStore(offers: _storeOffers(withTrial: false)),
          screen: _fastScreen);
      final l = _l(tester);
      await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
      expect(find.text(l.premiumGateSubscribe), findsOneWidget);
      expect(find.text(l.premiumGateStartTrial), findsNothing);
      expect(find.text(l.premiumGateTrial(l.premiumGateTrialDays(3))),
          findsNothing);
    });

    // Literal copy (not recomputed from the code): the store's own unit is
    // shown, so a one-month trial never reads as "30 days".
    for (final (trial, english) in [
      (_threeDays, 'Free trial for 3 days, then renews automatically'),
      (
        const StoreTrial(unit: StoreTrialUnit.day, count: 1),
        'Free trial for 1 day, then renews automatically'
      ),
      (
        const StoreTrial(unit: StoreTrialUnit.week, count: 2),
        'Free trial for 2 weeks, then renews automatically'
      ),
      (
        const StoreTrial(unit: StoreTrialUnit.month, count: 1),
        'Free trial for 1 month, then renews automatically'
      ),
      (
        const StoreTrial(unit: StoreTrialUnit.year, count: 1),
        'Free trial for 1 year, then renews automatically'
      ),
    ]) {
      testWidgets('trial wording keeps the store unit: $english',
          (tester) async {
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            store: _FakeStore(offers: _storeOffers(trial: trial)),
            screen: _fastScreen);
        await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(find.text(english), findsOneWidget);
      });
    }

    for (final (trial, arabic) in [
      (
        const StoreTrial(unit: StoreTrialUnit.month, count: 1),
        'تجربة مجانية لمدة شهر واحد، ثم يتجدد تلقائياً'
      ),
      (
        const StoreTrial(unit: StoreTrialUnit.week, count: 2),
        'تجربة مجانية لمدة أسبوعين، ثم يتجدد تلقائياً'
      ),
      (_threeDays, 'تجربة مجانية لمدة 3 أيام، ثم يتجدد تلقائياً'),
    ]) {
      testWidgets('Arabic trial wording keeps the store unit: $arabic',
          (tester) async {
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            store: _FakeStore(offers: _storeOffers(trial: trial)),
            language: 'ar',
            screen: _fastScreen);
        await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(find.text(arabic), findsOneWidget);
      });
    }

    testWidgets('an account switched while the gate is open never buys',
        (tester) async {
      final auth = _FakeAuth();
      final store = _FakeStore();
      await _pump(tester,
          plans: _FakePlans([offerJson()]),
          auth: auth,
          store: store,
          screen: _fastScreen);
      expect(store.offerRequests.last.$1, 1);
      auth.id = 2;
      await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
      expect(store.purchases, isEmpty,
          reason: 'Prices were loaded for account 1');
      await tester.pumpAndSettle();
      expect(store.offerRequests.last.$1, 2,
          reason: 'The catalogue reloads for the signed-in account');
      await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
      expect(store.purchases, [(2, 'semiannual')]);
    });

    for (final (name, outcome, expectedNotice) in [
      ('cancelled', const StorePurchaseCancelled() as Object, null),
      ('pending', const StorePurchasePending(), 'pending'),
      ('failed', const StorePurchaseFailed(), 'failed'),
      ('thrown', Exception('store down'), 'failed'),
      ('other account', const StorePurchaseOtherAccount(), 'otherAccount'),
    ]) {
      testWidgets('$name purchase stays locked and can be retried',
          (tester) async {
        final store = _FakeStore(outcome: outcome);
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            store: store,
            screen: _fastScreen);
        final l = _l(tester);
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(find.byKey(PremiumGateScreen.successKey), findsNothing);
        final message = switch (expectedNotice) {
          'pending' => l.premiumGatePurchasePending,
          'failed' => l.premiumGatePurchaseFailed,
          'otherAccount' => l.premiumGateOtherAccount,
          _ => null,
        };
        expect(find.byKey(PremiumGateScreen.noticeKey),
            message == null ? findsNothing : findsOneWidget);
        if (message != null) expect(find.text(message), findsOneWidget);
        expect(_button(tester, PremiumGateScreen.buyKey).enabled, isTrue);
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(store.purchases, hasLength(2));
      });
    }

    testWidgets('a purchase the server has not seen yet says so',
        (tester) async {
      final auth = _FakeAuth();
      await _pump(tester,
          plans: _FakePlans([offerJson()]),
          auth: auth,
          store: _FakeStore(),
          screen: _fastScreen);
      final l = _l(tester);
      final callsBefore = auth.calls;
      await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
      // One account check before buying, then the server polls.
      expect(auth.calls - callsBefore, 1 + _fastScreen.confirmAttempts);
      await revealPhoneWidget(tester, find.text(l.premiumGateSuccessSyncing));
      expect(find.byKey(PremiumGateScreen.successKey), findsOneWidget);
      // Never claims access the server has not confirmed.
      expect(find.text(l.premiumGateSyncingTitle), findsOneWidget);
      expect(find.text(l.premiumGateSuccessTitle), findsNothing);
      expect(find.text(l.premiumGateSuccessBody), findsNothing);

      // Still lagging: the re-check stays honest.
      await _tap(tester, find.byKey(PremiumGateScreen.checkAgainKey));
      expect(find.text(l.premiumGateSuccessTitle), findsNothing);

      auth.subscription = const {'is_subscribed': true};
      await _tap(tester, find.byKey(PremiumGateScreen.checkAgainKey));
      expect(find.text(l.premiumGateSuccessTitle), findsOneWidget);
      expect(find.byKey(PremiumGateScreen.checkAgainKey), findsNothing);
      await _tap(tester, find.byKey(PremiumGateScreen.continueKey));
    });

    for (final (name, restored, success, message) in [
      ('active', StoreRestoreOutcome.active as Object, true, null),
      ('nothing to restore', StoreRestoreOutcome.none, false, 'notFound'),
      ('restore error', Exception('offline'), false, 'refreshFailed'),
      (
        'belongs to another account',
        StoreRestoreOutcome.otherAccount,
        false,
        'otherAccount'
      ),
    ]) {
      testWidgets('restore: $name', (tester) async {
        final store = _FakeStore(restoreOutcome: restored);
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            auth: _FakeAuth(const {'is_subscribed': false}),
            store: store,
            screen: _fastScreen);
        final l = _l(tester);
        await _tap(tester, find.byKey(PremiumGateScreen.restoreKey));
        expect(store.restores, [1]);
        expect(find.byKey(PremiumGateScreen.successKey),
            success ? findsOneWidget : findsNothing);
        if (message != null) {
          await revealPhoneWidget(
              tester,
              find.text(switch (message) {
                'notFound' => l.premiumGateNotFound,
                'otherAccount' => l.premiumGateOtherAccount,
                _ => l.premiumGateRefreshFailed,
              }));
        }
      });
    }

    testWidgets('restore works while store prices fail to load',
        (tester) async {
      for (final broken in [
        (_FakeStore(restoreOutcome: StoreRestoreOutcome.active)
          ..offersError = Exception('offline')),
        _FakeStore(
            offers: const {}, restoreOutcome: StoreRestoreOutcome.active),
      ]) {
        final auth = _FakeAuth(const {'is_subscribed': false});
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            auth: auth,
            store: broken,
            screen: _fastScreen);
        await revealPhoneWidget(
            tester, find.text(_l(tester).premiumGateStorePricesFailed));
        auth.subscription = const {'is_subscribed': true};
        await _tap(tester, find.byKey(PremiumGateScreen.restoreKey));
        expect(broken.restores, [1]);
        expect(find.text(_l(tester).premiumGateSuccessTitle), findsOneWidget);
      }
    });

    testWidgets('restore uses the account signed in now', (tester) async {
      final auth = _FakeAuth();
      final store = _FakeStore();
      await _pump(tester,
          plans: _FakePlans([offerJson()]),
          auth: auth,
          store: store,
          screen: _fastScreen);
      auth.id = 7;
      await _tap(tester, find.byKey(PremiumGateScreen.restoreKey));
      expect(store.restores, [7]);
    });

    testWidgets('store prices that fail to load offer Retry, never a buy',
        (tester) async {
      for (final broken in [
        (_FakeStore()..offersError = Exception('offline')),
        _FakeStore(offers: const {}),
      ]) {
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            store: broken,
            screen: _fastScreen);
        final l = _l(tester);
        await revealPhoneWidget(
            tester, find.text(l.premiumGateStorePricesFailed));
        expect(find.byKey(PremiumGateScreen.buyKey), findsNothing);
        broken
          ..offersError = null
          ..offers = _storeOffers();
        await _tap(tester, find.byKey(PremiumGateScreen.storeRetryKey));
        await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
      }
    });
  });
}
