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
import 'package:sirati/shared/premium/premium_feature.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/purchases/store_purchases.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';

import '../support/card_chrome.dart';
import '../support/contrast_probe.dart';
import '../support/no_gradient.dart';
import '../support/non_text_contrast.dart';

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
  for (final (subscription, activeExpected) in <(Map<String, dynamic>?, bool)>[
    (const {'is_subscribed': true}, true),
    (const {'is_subscribed': false}, false),
  ]) {
    testWidgets(
        'C41: a refresh that first learns the session keeps its result '
        '($subscription)', (tester) async {
      // The session is not known yet when the gate opens (cold start).
      SessionCache.instance.setUser(null);
      final auth = _FakeAuth(subscription);
      await _pump(tester, plans: _FakePlans([offerJson()]), auth: auth);
      expect(SessionCache.instance.user.value, isNull);
      await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
      expect(auth.calls, 1);
      expect(SessionCache.instance.user.value?.id, 1);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      if (activeExpected) {
        expect(find.byKey(PremiumGateScreen.continueKey, skipOffstage: false),
            findsOneWidget,
            reason: 'the server said this account is subscribed');
      } else {
        await revealPhoneWidget(
            tester, find.byKey(PremiumGateScreen.refreshKey));
        expect(find.byKey(PremiumGateScreen.noticeKey),
            findsOneWidget,
            reason: 'the "not found" result of this refresh must stay');
      }
    });
  }
}
