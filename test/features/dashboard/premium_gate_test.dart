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
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';
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
  int calls = 0;

  @override
  Future<AuthUser?> me() async {
    calls++;
    if (error != null) throw error!;
    return AuthUser(
      id: 1,
      name: 'Sara',
      email: 'sara@x.io',
      subscription: subscription,
    );
  }
}

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
}) async {
  if (!keepView) {
    // Tall enough that the lazy ListView builds every section.
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final arabic = language == 'ar';
  await tester.pumpWidget(ProviderScope(
    // A fresh scope (and screen state) per pump.
    key: UniqueKey(),
    overrides: [
      subscriptionPlansRepositoryProvider.overrideWithValue(plans),
      authApiServiceProvider.overrideWithValue(auth ?? _FakeAuth()),
    ],
    child: MaterialApp(
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
                      builder: (_) => const PremiumGateScreen(),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            )
          : const PremiumGateScreen(),
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
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _isSelected(WidgetTester tester, String key) => find
    .descendant(
      of: find.byKey(PremiumGateScreen.planKey(key)),
      matching: find.byIcon(Icons.radio_button_checked_rounded),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  test('Screen catalogues preserve translations and the same message keys', () {
    final catalogues = [
      for (final language in ['ar', 'en'])
        (jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map)
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
        final explicit = access is Map && identical(access['is_subscribed'], true);
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
          for (var i = 0; i < 3; i++)
            planJson('p$i', isDefault: i == flagged),
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

        testWidgets('$label: benefits first, server plans, default selected',
            (tester) async {
          tester.view.physicalSize = const Size(1080, 5000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await _pump(
            tester,
            plans: _FakePlans([offerJson()]),
            language: language,
            theme: theme,
          );
          final l = _l(tester);
          expect(
            Directionality.of(tester.element(find.text(l.premiumGateHeroTitle))),
            arabic ? TextDirection.rtl : TextDirection.ltr,
          );
          final benefits = tester.getTopLeft(
            find.text(l.premiumGateBenefitsTitle),
          );
          final plansTitle = tester.getTopLeft(
            find.text(l.premiumGatePlansTitle),
          );
          expect(benefits.dy, lessThan(plansTitle.dy));
          for (final key in ['monthly', 'semiannual', 'annual']) {
            expect(find.byKey(PremiumGateScreen.planKey(key)), findsOneWidget);
            expect(
              find.text(arabic ? 'خطة $key' : 'Plan $key'),
              findsOneWidget,
            );
          }
          expect(find.text(arabic ? 'الأكثر شيوعاً' : 'Most popular'),
              findsOneWidget);
          expect(find.text(l.premiumGateTrial(3)), findsOneWidget);
          expect(_isSelected(tester, 'semiannual'), isTrue);
          expectAllTextAa('premium $label');
          expectAllIconsNonTextAa('premium $label');

          await _tap(tester, find.byKey(PremiumGateScreen.planKey('annual')));
          expect(_isSelected(tester, 'annual'), isTrue);
          expect(_isSelected(tester, 'semiannual'), isFalse);
          expectAllIconsNonTextAa('premium $label annual');
        });

        for (final (state, setUp) in <(String, Future<void> Function(WidgetTester))>[
          ('loaded', (tester) async {}),
          (
            'subscribe notice',
            (tester) => _tap(tester, find.byKey(PremiumGateScreen.subscribeKey)),
          ),
          (
            'refresh not found',
            (tester) => _tap(tester, find.byKey(PremiumGateScreen.refreshKey)),
          ),
        ]) {
          testWidgets('$label: $state fits at 2.0 text scale', (tester) async {
            usePhoneViewAtTextScale(tester);
            await _pump(
              tester,
              plans: _FakePlans([offerJson()]),
              auth: _FakeAuth(const {'is_subscribed': false}),
              language: language,
              theme: theme,
              keepView: true,
            );
            await setUp(tester);
            expect(tester.takeException(), isNull);
            expectAllTextAa('premium $label $state 2x');
            expectAllIconsNonTextAa('premium $label $state 2x');
          });
        }

        testWidgets('$label: load failure and active states fit at 2.0',
            (tester) async {
          usePhoneViewAtTextScale(tester);
          await _pump(
            tester,
            plans: _FakePlans([Exception('offline')]),
            language: language,
            theme: theme,
            keepView: true,
          );
          expect(find.byKey(PremiumGateScreen.retryKey), findsOneWidget);
          expect(tester.takeException(), isNull);
          expectAllTextAa('premium $label failed 2x');
          expectAllIconsNonTextAa('premium $label failed 2x');

          await _pump(
            tester,
            plans: _FakePlans([
              offerJson(access: const {'is_subscribed': true}),
            ]),
            language: language,
            theme: theme,
            keepView: true,
          );
          expect(find.byKey(PremiumGateScreen.continueKey), findsOneWidget);
          expect(tester.takeException(), isNull);
          expectAllTextAa('premium $label active 2x');
          expectAllIconsNonTextAa('premium $label active 2x');
        });
      }
    }

    testWidgets('Subscribe explains and never calls the server',
        (tester) async {
      final auth = _FakeAuth(const {'is_subscribed': false});
      final plans = _FakePlans([offerJson()]);
      await _pump(tester, plans: plans, auth: auth);
      await _tap(tester, find.byKey(PremiumGateScreen.subscribeKey));
      final l = _l(tester);
      expect(find.text(l.premiumGatePurchaseUnavailable), findsOneWidget);
      expect(auth.calls, 0);
      expect(plans.loads, 1);
      expect(find.byKey(PremiumGateScreen.continueKey), findsNothing);
    });

    testWidgets('refresh grants access only on an explicit server yes',
        (tester) async {
      for (final (subscription, active) in <(Map<String, dynamic>?, bool)>[
        (null, false),
        (const {}, false),
        (const {'is_subscribed': 'true'}, false),
        (const {'is_subscribed': 1}, false),
        (const {'is_subscribed': false, 'can_job_match': true}, false),
        (const {'is_subscribed': true}, true),
      ]) {
        final auth = _FakeAuth(subscription);
        await _pump(tester, plans: _FakePlans([offerJson()]), auth: auth);
        await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
        final l = _l(tester);
        expect(auth.calls, 1, reason: '$subscription');
        expect(
          find.byKey(PremiumGateScreen.continueKey),
          active ? findsOneWidget : findsNothing,
          reason: '$subscription',
        );
        expect(
          find.text(l.premiumGateNotFound),
          active ? findsNothing : findsOneWidget,
          reason: '$subscription',
        );
        expect(
          find.byKey(PremiumGateScreen.subscribeKey),
          active ? findsNothing : findsOneWidget,
        );
      }
    });

    testWidgets('refresh failure says so and stays locked', (tester) async {
      final auth = _FakeAuth()..error = Exception('offline');
      await _pump(tester, plans: _FakePlans([offerJson()]), auth: auth);
      await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
      expect(find.text(_l(tester).premiumGateRefreshFailed), findsOneWidget);
      expect(find.byKey(PremiumGateScreen.continueKey), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(PremiumGateScreen.refreshKey))
            .enabled,
        isTrue,
      );
    });

    testWidgets('plans retry reloads from the server', (tester) async {
      final plans = _FakePlans([Exception('offline'), offerJson()]);
      await _pump(tester, plans: plans);
      expect(find.text(_l(tester).premiumGatePlansFailed), findsOneWidget);
      await _tap(tester, find.byKey(PremiumGateScreen.retryKey));
      expect(plans.loads, 2);
      expect(find.byKey(PremiumGateScreen.planKey('monthly')), findsOneWidget);
    });

    testWidgets('an empty catalogue says so', (tester) async {
      await _pump(tester, plans: _FakePlans([offerJson(plans: const [])]));
      expect(find.text(_l(tester).premiumGateNoPlans), findsOneWidget);
    });

    testWidgets('Not now and Continue return to the caller', (tester) async {
      await _pump(
        tester,
        plans: _FakePlans([offerJson()]),
        auth: _FakeAuth(const {'is_subscribed': true}),
        pushed: true,
      );
      await _tap(tester, find.byKey(PremiumGateScreen.notNowKey));
      expect(find.byType(PremiumGateScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(PremiumGateScreen.refreshKey));
      await _tap(tester, find.byKey(PremiumGateScreen.continueKey));
      expect(find.byType(PremiumGateScreen), findsNothing);
    });

    testWidgets('Not now from a deep link goes home; privacy opens policy',
        (tester) async {
      final routes = _Routes();
      await _pump(tester, plans: _FakePlans([offerJson()]), routes: routes);
      await _tap(tester, find.byKey(PremiumGateScreen.privacyKey));
      expect(routes.opened, [AppRoutes.privacy]);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(PremiumGateScreen.notNowKey));
      expect(routes.opened.last, AppRoutes.home);
      expect(find.byType(PremiumGateScreen), findsNothing);
    });
  });
}
