import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/presentation/settings/settings_widgets.dart';
import 'package:sirati/features/settings/presentation/settings_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/subscription_status.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/profile_photo.dart';

import '../../support/contrast_probe.dart';

class _Gateway extends NotificationPrefsGateway {
  @override
  Future<bool?> fetchServer() async => true;
  @override
  Future<bool> readLocal() async => true;
  @override
  Future<void> saveLocal(bool enabled) async {}
  @override
  Future<void> syncServer(bool enabled) async {}
  @override
  Future<void> enableDevicePush() async {}
  @override
  Future<void> disableDevicePush() async {}
}

class _Auth extends AuthApiService {
  _Auth(this.user);

  AuthUser user;
  int meCalls = 0;

  @override
  Future<AuthUser?> me() async {
    meCalls++;
    return user;
  }
}

AuthUser _user({
  Map<String, dynamic>? subscription,
  String? avatarUrl,
  String name = 'Sara Ali',
}) =>
    AuthUser(
      id: 7,
      name: name,
      email: 'sara@x.io',
      avatarUrl: avatarUrl,
      subscription: subscription,
    );

Map<String, dynamic> _state({
  required Object? subscribed,
  Object? planId,
  Object? expiresAt,
}) =>
    {
      'is_subscribed': subscribed,
      'plan_id': planId,
      'expires_at': expiresAt,
    };

void main() {
  group('SubscriptionStatus', () {
    test('only an explicit is_subscribed: true is Premium', () {
      for (final value in <Object?>[
        null,
        false,
        'true',
        1,
        'yes',
        <String, dynamic>{},
        const [true],
      ]) {
        expect(
          SubscriptionStatus.fromSubscription(_state(subscribed: value))
              .isPremium,
          isFalse,
          reason: 'is_subscribed=$value',
        );
      }
      expect(SubscriptionStatus.fromSubscription(null).isPremium, isFalse);
      expect(
        SubscriptionStatus.fromSubscription(_state(subscribed: true)).isPremium,
        isTrue,
      );
    });

    test('the plan comes from the last part of any product id', () {
      const kinds = {
        'monthly': SubscriptionPlanKind.monthly,
        'semiannual': SubscriptionPlanKind.semiannual,
        'annual': SubscriptionPlanKind.annual,
      };
      for (final prefix in ['com.sirati.pro.', 'com.other.app.', 'x.', '']) {
        for (final MapEntry(key: suffix, value: kind) in kinds.entries) {
          for (final id in [
            '$prefix$suffix',
            '$prefix${suffix.toUpperCase()}'
          ]) {
            expect(
              SubscriptionStatus.fromSubscription(
                      _state(subscribed: true, planId: ' $id '))
                  .plan,
              kind,
              reason: id,
            );
          }
        }
      }
      for (final id in <Object?>[
        null,
        '',
        '   ',
        'com.sirati.pro.weekly',
        'com.sirati.pro.annual2',
        'monthly.plan',
        42,
      ]) {
        expect(
          SubscriptionStatus.fromSubscription(
                  _state(subscribed: true, planId: id))
              .plan,
          isNull,
          reason: 'plan_id=$id',
        );
      }
    });

    test('a missing or malformed end date is no end date', () {
      for (final value in <Object?>[null, '', 'soon', 20261111, true]) {
        expect(
          SubscriptionStatus.fromSubscription(
                  _state(subscribed: true, expiresAt: value))
              .expiresAt,
          isNull,
          reason: 'expires_at=$value',
        );
      }
      final at = DateTime.utc(2027, 2, 28, 23, 59);
      expect(
        SubscriptionStatus.fromSubscription(
                _state(subscribed: true, expiresAt: at.toIso8601String()))
            .expiresAt,
        at,
      );
    });
  });

  group('Settings shows the subscription and the real photo', () {
    const secureStorage =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

    setUp(() {
      SessionCache.instance.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, (_) async => null);
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      SessionCache.instance.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, null);
    });

    Widget app(_Auth auth, {String language = 'en', ThemeData? theme}) =>
        ProviderScope(
          overrides: [
            authApiServiceProvider.overrideWithValue(auth),
            notificationPrefsGatewayProvider.overrideWithValue(_Gateway()),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightFor(arabic: language == 'ar'),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen(),
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => Scaffold(body: Text('route:${settings.name}')),
            ),
          ),
        );

    Future<void> pump(WidgetTester tester, Widget widget) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }

    Finder inTile(Key key, String text) => find.descendant(
        of: find.byKey(key), matching: find.textContaining(text));

    Finder cardBadge() => find.descendant(
        of: find.byType(ProfileSummaryCard),
        matching: find.byKey(ProfilePhoto.premiumBadgeKey));

    final expiry = DateTime.utc(2027, 3, 14, 12);
    final cases =
        <(String, Map<String, dynamic>?, String? Function(AppLocalizations))>[
      ('no subscription data', null, (_) => null),
      ('free', _state(subscribed: false), (_) => null),
      (
        'monthly with an end date',
        _state(
            subscribed: true,
            planId: 'com.sirati.pro.monthly',
            expiresAt: expiry.toIso8601String()),
        (l) => l.serverPlanMonthlyName,
      ),
      (
        'semiannual with an end date',
        _state(
            subscribed: true,
            planId: 'com.sirati.pro.semiannual',
            expiresAt: expiry.toIso8601String()),
        (l) => l.serverPlanSixMonthsName,
      ),
      (
        'annual without an end date',
        _state(subscribed: true, planId: 'com.sirati.pro.annual'),
        (l) => l.serverPlanAnnualName,
      ),
      (
        'granted by hand with an unknown plan',
        _state(
            subscribed: true,
            planId: 'manual-grant',
            expiresAt: expiry.toIso8601String()),
        (_) => null,
      ),
    ];

    for (final language in ['en', 'ar']) {
      for (final ios in [true, false]) {
        for (final (label, state, planName) in cases) {
          testWidgets('$label ($language, iOS=$ios)', (tester) async {
            AppLocale.languageCode.value = language;
            debugDefaultTargetPlatformOverride =
                ios ? TargetPlatform.iOS : TargetPlatform.android;
            final l10n = await AppLocalizations.delegate.load(Locale(language));
            final status = SubscriptionStatus.fromSubscription(state);
            await pump(tester,
                app(_Auth(_user(subscription: state)), language: language));

            final premium = status.isPremium;
            expect(
                inTile(
                    SettingsScreen.subscriptionKey,
                    premium
                        ? l10n.premiumGateAppBar
                        : l10n.subscriptionFreePlan),
                findsOneWidget);
            if (!premium) {
              expect(
                  inTile(SettingsScreen.subscriptionKey,
                      l10n.premiumGateJobMatchSeePlans),
                  findsOneWidget);
            }
            final plan = planName(l10n);
            if (plan != null) {
              expect(
                  inTile(SettingsScreen.subscriptionKey, plan), findsOneWidget);
            }
            final end = status.expiresAt;
            if (premium) {
              final context = tester.element(find.byType(SettingsScreen));
              final stateText = end == null
                  ? l10n.subscriptionActive
                  : l10n.subscriptionActiveUntil(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(end.toLocal()));
              expect(inTile(SettingsScreen.subscriptionKey, stateText),
                  findsOneWidget);
            }

            expect(cardBadge(), premium ? findsOneWidget : findsNothing);
            expect(find.byKey(SettingsScreen.manageSubscriptionKey),
                premium && ios ? findsOneWidget : findsNothing);
            debugDefaultTargetPlatformOverride = null;
          });
        }
      }
    }

    testWidgets('Manage subscription only for App Store access',
        (tester) async {
      AppLocale.languageCode.value = 'en';
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      for (final (source, shown) in <(Object?, bool)>[
        ('store', true),
        ('admin', false),
        (null, true), // older server: keep Apple's page
      ]) {
        SessionCache.instance.clear();
        final state = {
          ..._state(subscribed: true, planId: 'com.sirati.pro.monthly'),
          'source': source,
        };
        await pump(tester, app(_Auth(_user(subscription: state))));
        expect(find.byKey(SettingsScreen.manageSubscriptionKey),
            shown ? findsOneWidget : findsNothing,
            reason: 'source=$source');
        await tester.pumpWidget(const SizedBox());
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the card shows the photo, newest upload first',
        (tester) async {
      AppLocale.languageCode.value = 'en';
      for (final (server, cached) in <(String?, String?)>[
        ('https://x.test/a.png', null),
        (null, 'https://x.test/new.png'),
        ('https://x.test/old.png', 'https://x.test/new.png'),
        (null, null),
      ]) {
        SessionCache.instance.clear();
        if (cached != null) {
          SessionCache.instance.setUser(_user(avatarUrl: cached));
        }
        await pump(tester, app(_Auth(_user(avatarUrl: server))));
        // me() refreshes the cache with the server copy; the cache is what
        // an upload writes, so whatever it holds is shown.
        final shown = SessionCache.instance.user.value?.avatarUrl ?? server;
        final photo = tester.widget<ProfilePhoto>(find.descendant(
            of: find.byType(ProfileSummaryCard),
            matching: find.byType(ProfilePhoto)));
        expect(photo.url, shown, reason: 'server=$server cached=$cached');
        expect(
            find.descendant(
                of: find.byType(ProfileSummaryCard),
                matching: find.byKey(ProfilePhoto.imageKey)),
            shown == null ? findsNothing : findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the tile opens the Premium screen and re-reads the account',
        (tester) async {
      AppLocale.languageCode.value = 'en';
      final auth = _Auth(_user(subscription: _state(subscribed: false)));
      await pump(tester, app(auth));
      final before = auth.meCalls;
      await tester.tap(find.byKey(SettingsScreen.subscriptionKey));
      await tester.pumpAndSettle();
      expect(find.text('route:${AppRoutes.premium}'), findsOneWidget);

      auth.user = _user(
          subscription:
              _state(subscribed: true, planId: 'com.sirati.pro.annual'));
      Navigator.of(tester.element(find.text('route:${AppRoutes.premium}')))
          .pop();
      await tester.pumpAndSettle();
      expect(auth.meCalls, greaterThan(before));
      expect(cardBadge(), findsOneWidget);
    });

    for (final (mode, theme) in [
      ('light', AppTheme.lightFor(arabic: false)),
      ('dark', AppTheme.darkFor(arabic: false)),
    ]) {
      testWidgets('Premium settings stay readable in $mode mode',
          (tester) async {
        AppLocale.languageCode.value = 'en';
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await pump(
            tester,
            app(
                _Auth(_user(
                    subscription: _state(
                        subscribed: true,
                        planId: 'com.sirati.pro.monthly',
                        expiresAt: expiry.toIso8601String()))),
                theme: theme));
        expectAllTextAa('premium settings $mode');

        final badge = tester.widget<Container>(cardBadge());
        final fill = (badge.decoration! as BoxDecoration).color!;
        final icon = tester.widget<Icon>(
            find.descendant(of: cardBadge(), matching: find.byType(Icon)));
        expect(AppContrast.ratio(icon.color!, fill), greaterThanOrEqualTo(3.0),
            reason: 'badge icon vs badge ($mode)');
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });

  group('Home header', () {
    tearDown(SessionCache.instance.clear);

    for (final premium in [true, false]) {
      testWidgets('shows the Premium badge only for Premium (premium=$premium)',
          (tester) async {
        SessionCache.instance.setUser(_user(
            avatarUrl: 'https://x.test/a.png',
            subscription: _state(subscribed: premium)));
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: DashboardHomeHeader(
              name: 'Sara',
              subtitle: 'hi',
              unreadCount: 0,
              onNotifications: () {},
              onAvatarTap: () {},
            ),
          ),
        ));
        await tester.pump();
        expect(find.byKey(ProfilePhoto.premiumBadgeKey),
            premium ? findsOneWidget : findsNothing);
        expect(find.byKey(ProfilePhoto.imageKey), findsOneWidget);
      });
    }
  });
}
