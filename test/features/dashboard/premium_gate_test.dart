import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/network/api_config.dart';
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
import 'package:sirati/shared/services/session_cache.dart';
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
  int syncs = 0;

  /// Runs on each server sync (e.g. the server repairs access).
  void Function()? onSync;
  Object? syncError;

  @override
  Future<void> syncWithStore() async {
    syncs++;
    onSync?.call();
    if (syncError != null) throw syncError!;
  }

  @override
  Future<SubscriptionOffer> load() async {
    loads++;
    final next =
        responses.length == 1 ? responses.first : responses.removeAt(0);
    if (next is Map<String, dynamic>) return SubscriptionOffer.fromJson(next);
    throw next;
  }
}

/// Scripted `/auth/me`. Each reply is for the account the token belonged to
/// when the request started, like the real server.
class _MeApi extends ApiClient {
  Map<String, dynamic>? subscription;
  Object? error;
  Future<AuthUser?>? pending;
  int calls = 0;
  int id = 1;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    calls++;
    final askedFor = id;
    final wait = pending;
    if (wait != null) {
      final user = await wait;
      return {
        'data': {
          'id': user?.id ?? askedFor,
          'name': user?.name ?? 'Sara',
          'email': user?.email ?? 'sara@x.io',
          if (user?.subscription != null) 'subscription': user!.subscription,
        },
      };
    }
    if (error != null) throw error!;
    return {
      'data': {
        'id': askedFor,
        'name': 'Sara',
        'email': 'sara@x.io',
        if (subscription != null) 'subscription': subscription,
      },
    };
  }
}

/// The real [AuthApiService.me] over [_MeApi], so the session cache behaves
/// as in the app: a late reply never replaces a newer session.
class _FakeAuth extends AuthApiService {
  _FakeAuth._(this.api) : super(apiClient: api);

  factory _FakeAuth([Map<String, dynamic>? subscription]) =>
      _FakeAuth._(_MeApi()..subscription = subscription);

  final _MeApi api;

  Map<String, dynamic>? get subscription => api.subscription;
  set subscription(Map<String, dynamic>? value) => api.subscription = value;
  Object? get error => api.error;
  set error(Object? value) => api.error = value;
  Future<AuthUser?>? get pending => api.pending;
  set pending(Future<AuthUser?>? value) => api.pending = value;
  int get calls => api.calls;

  /// The account the server answers for (the token's account).
  int get id => api.id;
  set id(int value) => api.id = value;

  /// Another account signs in on this device, as after a real sign-in.
  void signIn(int userId) {
    api.id = userId;
    SessionCache.instance
        .setUser(AuthUser(id: userId, name: 'Other', email: 'other@x.io'));
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

  /// The "still this account" check the gate passed with the last call.
  bool Function()? lastIsCurrent;

  /// Runs when a purchase starts (e.g. the server's account changes).
  void Function()? onPurchase;
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
    required bool Function() isCurrent,
  }) async {
    lastIsCurrent = isCurrent;
    expect(isCurrent(), isTrue, reason: 'Gate only buys for the session');
    purchases.add((userId, planKey));
    onPurchase?.call();
    if (pendingPurchase != null) return pendingPurchase!.future;
    final next = outcome;
    if (next is StorePurchaseOutcome) return next;
    throw next;
  }

  @override
  Future<StoreRestoreOutcome> restore({
    required int userId,
    required bool Function() isCurrent,
  }) async {
    lastIsCurrent = isCurrent;
    expect(isCurrent(), isTrue, reason: 'Gate only restores for the session');
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
  // As in the app, startup has already put the signed-in account (1) in the
  // session cache before the gate opens.
  setUp(() => SessionCache.instance
      .setUser(const AuthUser(id: 1, name: 'Sara', email: 'sara@x.io')));
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

    testWidgets('a late refresh reply for the previous account is never shown',
        (tester) async {
      // Subscribed or not, that answer is another account's: no active card,
      // no notice, and the next refresh answers for the account signed in now.
      for (final late in <Map<String, dynamic>>[
        const {'is_subscribed': true},
        const {'is_subscribed': false},
      ]) {
        SessionCache.instance
            .setUser(const AuthUser(id: 1, name: 'Sara', email: 'sara@x.io'));
        final auth = _FakeAuth();
        await _pump(tester, plans: _FakePlans([offerJson()]), auth: auth);
        final reply = Completer<AuthUser?>();
        auth.pending = reply.future;
        await revealPhoneWidget(
            tester, find.byKey(PremiumGateScreen.refreshKey));
        await tester.tap(find.byKey(PremiumGateScreen.refreshKey));
        await tester.pump();
        auth.pending = null;
        auth.signIn(2);
        reply.complete(AuthUser(
            id: 1, name: 'Sara', email: 'sara@x.io', subscription: late));
        await tester.pumpAndSettle();

        // The active card sits at the top of a lazily built list: go there and
        // count off-screen widgets too.
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(find.byKey(PremiumGateScreen.continueKey, skipOffstage: false),
            findsNothing,
            reason: 'late reply $late');
        await revealPhoneWidget(
            tester, find.byKey(PremiumGateScreen.refreshKey));
        expect(find.byKey(PremiumGateScreen.noticeKey), findsNothing,
            reason: 'late reply $late');

        auth.subscription = const {'is_subscribed': true};
        await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
        await revealPhoneWidget(
            tester, find.byKey(PremiumGateScreen.continueKey));
      }
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
          'otherAccount' => l.premiumGateOtherAccount(ApiConfig.supportEmail),
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
                'otherAccount' =>
                  l.premiumGateOtherAccount(ApiConfig.supportEmail),
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

    group('one account per flow', () {
      testWidgets('a sign-in while the account check is in flight never buys',
          (tester) async {
        final auth = _FakeAuth();
        final store = _FakeStore();
        await _pump(tester,
            plans: _FakePlans([offerJson()]),
            auth: auth,
            store: store,
            screen: _fastScreen);
        final reply = Completer<AuthUser?>();
        auth.pending = reply.future;
        await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
        await tester.tap(find.byKey(PremiumGateScreen.buyKey));
        await tester.pump();
        auth.pending = null;
        auth.signIn(2);
        // The late reply is for account 1, which is no longer signed in.
        reply.complete(const AuthUser(id: 1, name: 'Sara', email: 's@x.io'));
        await tester.pumpAndSettle();
        expect(store.purchases, isEmpty);
        expect(SessionCache.instance.user.value?.id, 2,
            reason: 'A late reply never replaces the newer session');
        expect(store.offerRequests.last.$1, 2);
      });

      testWidgets('a session change while the store sheet is open drops it',
          (tester) async {
        final auth = _FakeAuth();
        final plans = _FakePlans([offerJson()]);
        final store = _FakeStore()
          ..pendingPurchase = Completer<StorePurchaseOutcome>();
        await _pump(tester,
            plans: plans, auth: auth, store: store, screen: _fastScreen);
        await revealPhoneWidget(tester, find.byKey(PremiumGateScreen.buyKey));
        await tester.tap(find.byKey(PremiumGateScreen.buyKey));
        await tester.pump();
        await tester.pump();
        expect(store.purchases, [(1, 'semiannual')]);
        expect(store.lastIsCurrent!(), isTrue);

        auth.signIn(2);
        await tester.pump();
        expect(store.lastIsCurrent!(), isFalse,
            reason: 'A queued store call sees the account is gone');

        auth.subscription = const {'is_subscribed': true};
        store.pendingPurchase!.complete(const StorePurchaseCompleted());
        await tester.pumpAndSettle();
        expect(find.byKey(PremiumGateScreen.successKey), findsNothing);
        expect(plans.syncs, 0, reason: 'Never syncs a different account');
        expect(store.offerRequests.last.$1, 2);
      });

      testWidgets('only the buying account confirms a purchase',
          (tester) async {
        final auth = _FakeAuth();
        final plans = _FakePlans([offerJson()]);
        // After the charge the token answers for another, subscribed account.
        final store = _FakeStore()
          ..onPurchase = () {
            auth.id = 2;
            auth.subscription = const {'is_subscribed': true};
          };
        await _pump(tester,
            plans: plans, auth: auth, store: store, screen: _fastScreen);
        final l = _l(tester);
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(store.purchases, [(1, 'semiannual')]);
        expect(find.text(l.premiumGateSuccessTitle), findsNothing);
        expect(find.byKey(PremiumGateScreen.successKey), findsNothing);
      });
    });

    group('server sync', () {
      testWidgets('a completed purchase asks the server to re-read the store',
          (tester) async {
        final auth = _FakeAuth();
        final plans = _FakePlans([offerJson()])
          ..onSync = () => auth.subscription = const {'is_subscribed': true};
        await _pump(tester,
            plans: plans, auth: auth, store: _FakeStore(), screen: _fastScreen);
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(plans.syncs, 1);
        expect(find.text(_l(tester).premiumGateSuccessTitle), findsOneWidget);
      });

      testWidgets('restore repairs access the webhook never granted',
          (tester) async {
        final auth = _FakeAuth(const {'is_subscribed': false});
        final plans = _FakePlans([offerJson()])
          ..onSync = () => auth.subscription = const {'is_subscribed': true};
        final store = _FakeStore(restoreOutcome: StoreRestoreOutcome.active);
        await _pump(tester,
            plans: plans, auth: auth, store: store, screen: _fastScreen);
        await _tap(tester, find.byKey(PremiumGateScreen.restoreKey));
        expect(plans.syncs, 1);
        expect(find.text(_l(tester).premiumGateSuccessTitle), findsOneWidget);

        // Check again syncs too, so a second try can still repair it.
        await _tap(tester, find.byKey(PremiumGateScreen.continueKey));
      });

      testWidgets('a failed sync still waits for the webhook, then confirms',
          (tester) async {
        final auth = _FakeAuth();
        final plans = _FakePlans([offerJson()])..syncError = Exception('503');
        await _pump(tester,
            plans: plans, auth: auth, store: _FakeStore(), screen: _fastScreen);
        final l = _l(tester);
        await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
        expect(find.text(l.premiumGateSyncingTitle), findsOneWidget);
        plans
          ..syncError = null
          ..onSync = () => auth.subscription = const {'is_subscribed': true};
        await _tap(tester, find.byKey(PremiumGateScreen.checkAgainKey));
        expect(plans.syncs, 2);
        expect(find.text(l.premiumGateSuccessTitle), findsOneWidget);
      });
    });

    for (final (name, outcome, message) in [
      ('nothing to restore', StoreRestoreOutcome.none, 'notFound'),
      ('another account', StoreRestoreOutcome.otherAccount, 'otherAccount'),
      ('restore error', Exception('offline') as Object, 'refreshFailed'),
    ]) {
      testWidgets('an active account sees the restore result: $name',
          (tester) async {
        final store = _FakeStore(restoreOutcome: outcome);
        await _pump(tester,
            plans: _FakePlans([
              offerJson(access: const {'is_subscribed': true})
            ]),
            auth: _FakeAuth(const {'is_subscribed': true}),
            store: store,
            screen: _fastScreen);
        final l = _l(tester);
        await _tap(tester, find.byKey(PremiumGateScreen.restoreKey));
        await revealPhoneWidget(
            tester,
            find.text(switch (message) {
              'notFound' => l.premiumGateNotFound,
              'otherAccount' =>
                l.premiumGateOtherAccount(ApiConfig.supportEmail),
              _ => l.premiumGateRefreshFailed,
            }));
      });
    }

    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final label = '$language/${dark ? 'dark' : 'light'}';
        testWidgets('$label: another account offers support, legibly',
            (tester) async {
          final arabic = language == 'ar';
          await _pump(tester,
              plans: _FakePlans([offerJson()]),
              store: _FakeStore(outcome: const StorePurchaseOtherAccount()),
              language: language,
              theme: dark
                  ? AppTheme.darkFor(arabic: arabic)
                  : AppTheme.lightFor(arabic: arabic),
              screen: _fastScreen);
          final l = _l(tester);
          await _tap(tester, find.byKey(PremiumGateScreen.buyKey));
          await revealPhoneWidget(
              tester, find.byKey(PremiumGateScreen.supportKey));
          expect(find.text(l.premiumGateOtherAccount(ApiConfig.supportEmail)),
              findsOneWidget);
          expect(find.text(l.premiumGateContactSupport), findsOneWidget);
          await inspectPhoneScreen(tester, '$label other account');
        });
      }
    }

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
