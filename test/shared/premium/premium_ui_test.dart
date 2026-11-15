import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/recommendations_tab.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/dashboard/presentation/home/home_premium_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/premium/premium_feature.dart';
import 'package:sirati/shared/premium/premium_ui.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';

import '../../support/contrast_probe.dart';

/// `/auth/me` → `subscription` for a free account with the limits on, or
/// for Premium. Flags follow `SubscriptionGate::stateFor`.
Map<String, dynamic> _state({
  bool premium = false,
  bool enforced = true,
  int cvUsed = 0,
  int analysisUsed = 0,
}) {
  final full = !enforced || premium;
  return {
    'enforced': enforced,
    'is_subscribed': premium,
    'can_download': full,
    'can_enhance': full,
    'can_view_full_analysis': full,
    'quota': {
      'cv': {'limit': full ? null : 1, 'used': full ? 0 : cvUsed},
      'analysis': {'limit': full ? null : 2, 'used': full ? 0 : analysisUsed},
    },
  };
}

void _signIn(Map<String, dynamic>? subscription) =>
    SessionCache.instance.setUser(AuthUser(
        id: 3, name: 'Sara', email: 's@x.io', subscription: subscription));

/// Records named routes; [onPremium] runs when the Premium page opens (a
/// purchase made there).
class _Routes {
  _Routes({this.onPremium});

  final VoidCallback? onPremium;
  final opened = <(String?, Object?)>[];

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    opened.add((settings.name, settings.arguments));
    if (settings.name == AppRoutes.premium) onPremium?.call();
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('route ${settings.name}'),
        ),
      ),
    );
  }
}

Widget _app(Widget home,
        {String language = 'en', ThemeData? theme, _Routes? routes}) =>
    MaterialApp(
      theme: theme ?? AppTheme.lightFor(arabic: language == 'ar'),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateRoute: (routes ?? _Routes()).onGenerateRoute,
      home: Scaffold(body: home),
    );

/// For screens with a never-ending animation (the AI progress overlay):
/// let routes and sheets finish their transitions.
Future<void> _settleBriefly(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(SessionCache.instance.clear);
  tearDown(SessionCache.instance.clear);

  group('PremiumFeature', () {
    test('every server feature maps to its own prompt; unknown is general', () {
      expect(PremiumFeature.fromServer('cv_download'), PremiumFeature.download);
      expect(PremiumFeature.fromServer('ai_enhancement'),
          PremiumFeature.aiWriting);
      expect(PremiumFeature.fromServer('daily_cv_quota'),
          PremiumFeature.dailyCvLimit);
      expect(PremiumFeature.fromServer('daily_analysis_quota'),
          PremiumFeature.dailyAnalysisLimit);
      for (final f in ['job_match', 'job_match_quota', 'job_match_x']) {
        expect(PremiumFeature.fromServer(f), PremiumFeature.jobMatch,
            reason: f);
      }
      for (final f in [null, '', 'CV_DOWNLOAD', 'new_feature', 'match_job']) {
        expect(PremiumFeature.fromServer(f), PremiumFeature.general,
            reason: '$f');
      }
    });

    for (final language in ['en', 'ar']) {
      test('every feature has its own headline ($language)', () async {
        final l = await AppLocalizations.delegate.load(Locale(language));
        final titles = PremiumFeature.values.map((f) => f.title(l)).toList();
        final bodies = PremiumFeature.values.map((f) => f.body(l)).toList();
        expect(titles.every((t) => t.trim().isNotEmpty), isTrue);
        expect(bodies.every((t) => t.trim().isNotEmpty), isTrue);
        expect(titles.toSet().length, titles.length);
        expect(bodies.toSet().length, bodies.length);
      });
    }
  });

  group('ApiClient', () {
    test('a 402 carries the refused feature; other statuses never do',
        () async {
      for (final (status, feature, expected) in <(int, Object?, String?)>[
        (402, 'cv_download', 'cv_download'),
        (402, 'daily_analysis_quota', 'daily_analysis_quota'),
        (402, null, null),
        (402, 42, null),
        (403, 'cv_download', null),
        (422, 'ai_enhancement', null),
      ]) {
        final client = ApiClient(
          httpClient: MockClient((_) async => http.Response(
                jsonEncode({'message': 'no', 'feature': feature}),
                status,
                headers: {'content-type': 'application/json'},
              )),
        );
        try {
          await client.postJson('/generated-cvs', {});
          fail('expected an ApiException');
        } on ApiException catch (e) {
          expect(e.feature, expected, reason: '$status $feature');
          expect(e.requiresSubscription, status == 402);
        }
      }
    });
  });

  group('a refused Premium request offers Premium', () {
    Future<void> fail402(WidgetTester tester, String? feature,
        {required void Function() onRetry}) async {
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    Widget trigger(ApiException error, {required VoidCallback onRetry}) =>
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                AppSnackBar.fromException(context, error, onRetry: onRetry),
            child: const Text('go'),
          ),
        );

    for (final language in ['en', 'ar']) {
      for (final server in [
        'cv_download',
        'ai_enhancement',
        'daily_cv_quota',
        'daily_analysis_quota',
        'job_match',
        'something_new',
      ]) {
        testWidgets('$server ($language): see plans, buy, the action resumes',
            (tester) async {
          _tallView(tester);
          _signIn(_state());
          final feature = PremiumFeature.fromServer(server);
          final routes =
              _Routes(onPremium: () => _signIn(_state(premium: true)));
          var retries = 0;
          await tester.pumpWidget(_app(
            trigger(
              ApiException('x', statusCode: 402, feature: server),
              onRetry: () => retries++,
            ),
            language: language,
            routes: routes,
          ));
          await fail402(tester, server, onRetry: () {});
          final l = await AppLocalizations.delegate.load(Locale(language));

          expect(find.byType(PremiumPromptSheet), findsOneWidget);
          expect(find.text(feature.title(l)), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);

          await tester.tap(find.byKey(PremiumPromptSheet.seePlansKey));
          await tester.pumpAndSettle();
          expect(routes.opened.single, (AppRoutes.premium, feature));
          expect(retries, 0, reason: 'nothing resumes before they come back');

          await tester.tap(find.text('route ${AppRoutes.premium}'));
          await tester.pumpAndSettle();
          expect(retries, 1);
        });
      }
    }

    testWidgets('coming back without buying resumes nothing', (tester) async {
      _tallView(tester);
      _signIn(_state());
      final routes = _Routes();
      var retries = 0;
      await tester.pumpWidget(_app(
        trigger(
            const ApiException('x', statusCode: 402, feature: 'cv_download'),
            onRetry: () => retries++),
        routes: routes,
      ));
      await fail402(tester, 'cv_download', onRetry: () {});
      await tester.tap(find.byKey(PremiumPromptSheet.seePlansKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('route ${AppRoutes.premium}'));
      await tester.pumpAndSettle();
      expect(retries, 0);
    });

    testWidgets('"Not now" closes the prompt and opens nothing',
        (tester) async {
      _tallView(tester);
      _signIn(_state());
      final routes = _Routes();
      var retries = 0;
      await tester.pumpWidget(_app(
        trigger(
            const ApiException('x', statusCode: 402, feature: 'cv_download'),
            onRetry: () => retries++),
        routes: routes,
      ));
      await fail402(tester, 'cv_download', onRetry: () {});
      await tester.tap(find.byKey(PremiumPromptSheet.notNowKey));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumPromptSheet), findsNothing);
      expect(routes.opened, isEmpty);
      expect(retries, 0);
    });

    testWidgets('any other error is still a snackbar', (tester) async {
      for (final status in [400, 403, 404, 422, 429, 500]) {
        await tester.pumpWidget(_app(trigger(
            ApiException('failed $status',
                statusCode: status, feature: 'cv_download'),
            onRetry: () {})));
        await tester.tap(find.text('go'));
        await tester.pump();
        expect(find.byType(PremiumPromptSheet), findsNothing,
            reason: '$status');
        expect(find.text('failed $status'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('Premium markers follow the server flags', () {
    testWidgets('My CVs: download is tappable, with the chip only when locked',
        (tester) async {
      for (final (language, canDownload) in [
        ('en', true),
        ('en', false),
        ('ar', true),
        ('ar', false),
      ]) {
        await tester.pumpWidget(_app(
            language: language,
            CvDocumentCard(
              item: CvListItem.fromJson({
                'id': 1,
                'title': 'CV',
                'is_draft': false,
                'can_download': canDownload,
              }),
              onOpen: () {},
              onEdit: () {},
              onDelete: () {},
              onDownload: () {},
              onScan: () {},
            )));
        final l = await AppLocalizations.delegate.load(Locale(language));
        await tester.tap(find.byTooltip(l.cvCardMore));
        await tester.pumpAndSettle();
        final item = find.ancestor(
            of: find.text(l.cvCardDownload),
            matching: find.byWidgetPredicate((w) => w is PopupMenuItem));
        expect(tester.widget<PopupMenuItem<Object?>>(item).enabled, isTrue,
            reason: 'canDownload=$canDownload');
        expect(find.descendant(of: item, matching: find.byType(PremiumChip)),
            canDownload ? findsNothing : findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('AI rewrite shows the chip only while AI writing is locked',
        (tester) async {
      final controller = TextEditingController(text: 'x' * 80);
      addTearDown(controller.dispose);
      for (final (state, chip) in [
        (_state(), true),
        (_state(premium: true), false),
        (_state(enforced: false), false),
        (null, false),
      ]) {
        SessionCache.instance.clear();
        if (state != null) _signIn(state);
        await tester.pumpWidget(_app(AiCvField(
          field: 'summary',
          controller: controller,
          english: true,
          isLoading: false,
          helperText: 'h',
          onEnhance: () {},
          onDismissResult: () {},
          child: AppTextFormField(controller: controller),
        )));
        expect(find.byType(PremiumChip), chip ? findsOneWidget : findsNothing,
            reason: '$state');
      }
    });

    for (final language in ['en', 'ar']) {
      testWidgets('hidden analysis items offer the full analysis ($language)',
          (tester) async {
        _tallView(tester);
        await tester.pumpWidget(
            _app(const HiddenItemsNote(count: 4), language: language));
        final l = await AppLocalizations.delegate.load(Locale(language));
        expect(find.text(l.atsHiddenMore(4)), findsOneWidget);
        expect(find.byType(PremiumChip), findsOneWidget);
        await tester.tap(find.byKey(HiddenItemsNote.unlockKey));
        await tester.pumpAndSettle();
        expect(find.text(PremiumFeature.fullAnalysis.title(l)), findsOneWidget);
      });
    }
  });

  group('Home Premium card', () {
    for (final language in ['en', 'ar']) {
      testWidgets('only free accounts with limits see it ($language)',
          (tester) async {
        final l = await AppLocalizations.delegate.load(Locale(language));
        for (final (state, shown) in <(Map<String, dynamic>?, bool)>[
          (_state(), true),
          (_state(cvUsed: 1, analysisUsed: 2), true),
          (_state(premium: true), false),
          (_state(enforced: false), false),
          (null, false),
        ]) {
          SessionCache.instance.clear();
          if (state != null) _signIn(state);
          await tester
              .pumpWidget(_app(const HomePremiumCard(), language: language));
          expect(find.byKey(HomePremiumCard.cardKey),
              shown ? findsOneWidget : findsNothing,
              reason: '$state');
          if (shown) {
            final quota = state!['quota'] as Map;
            final cv = quota['cv'] as Map;
            final analysis = quota['analysis'] as Map;
            expect(
                find.text(l.premiumHomeCvsToday(
                    cv['used'] as int, cv['limit'] as int)),
                findsOneWidget);
            expect(
                find.text(l.premiumHomeAnalysesToday(
                    analysis['used'] as int, analysis['limit'] as int)),
                findsOneWidget);
          }
        }
      });
    }

    testWidgets('tapping it opens the Premium page', (tester) async {
      _signIn(_state());
      final routes = _Routes();
      await tester.pumpWidget(_app(const HomePremiumCard(), routes: routes));
      await tester.tap(find.byKey(HomePremiumCard.cardKey));
      await tester.pumpAndSettle();
      expect(routes.opened.single, (AppRoutes.premium, PremiumFeature.general));
    });

    testWidgets('it disappears as soon as the account becomes Premium',
        (tester) async {
      _signIn(_state());
      await tester.pumpWidget(_app(const HomePremiumCard()));
      expect(find.byKey(HomePremiumCard.cardKey), findsOneWidget);
      _signIn(_state(premium: true));
      await tester.pump();
      expect(find.byKey(HomePremiumCard.cardKey), findsNothing);
    });
  });

  for (final (mode, theme) in [
    ('light', AppTheme.lightFor(arabic: false)),
    ('dark', AppTheme.darkFor(arabic: false)),
  ]) {
    testWidgets('Premium prompt, chip and Home card are readable ($mode)',
        (tester) async {
      _tallView(tester);
      _signIn(_state(cvUsed: 1));
      await tester.pumpWidget(_app(
        const Column(children: [
          HomePremiumCard(),
          PremiumChip(),
          HiddenItemsNote(count: 3),
        ]),
        theme: theme,
      ));
      expectAllTextAa('premium card $mode');

      final context = tester.element(find.byType(HomePremiumCard));
      unawaited(PremiumPromptSheet.show(context, PremiumFeature.download));
      await tester.pumpAndSettle();
      expectAllTextAa('premium prompt $mode');

      // Every rendered crown is a graphic: 3:1 against the chip under it.
      final chips = find.byType(PremiumChip);
      expect(chips, findsWidgets);
      for (final chip in chips.evaluate()) {
        final box = tester.widget<Container>(find.descendant(
            of: find.byWidget(chip.widget),
            matching: find.byKey(PremiumChip.chipKey)));
        final icon = tester.widget<Icon>(find.descendant(
            of: find.byWidget(chip.widget), matching: find.byType(Icon)));
        expect(
            AppContrast.ratio(
                icon.color!, (box.decoration! as BoxDecoration).color!),
            greaterThanOrEqualTo(3.0),
            reason: 'crown vs chip ($mode)');
      }
    });
  }

  group('resuming after the Premium page', () {
    Future<bool> visit(WidgetTester tester, {VoidCallback? onPremium}) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(
        Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
        routes: _Routes(onPremium: onPremium),
      ));
      final result = openPremium(ctx);
      await tester.pumpAndSettle();
      await tester.tap(find.text('route ${AppRoutes.premium}'));
      await tester.pumpAndSettle();
      return result;
    }

    AuthUser user(int id, {required bool premium}) => AuthUser(
        id: id,
        name: 'U$id',
        email: 'u$id@x.io',
        subscription: _state(premium: premium));

    testWidgets('only the same account going from free to Premium resumes',
        (tester) async {
      for (final (label, start, end, expected)
          in <(String, AuthUser?, AuthUser?, bool)>[
        ('bought', user(1, premium: false), user(1, premium: true), true),
        (
          'left without buying',
          user(1, premium: false),
          user(1, premium: false),
          false
        ),
        (
          'was already Premium (stale cache)',
          user(1, premium: true),
          user(1, premium: true),
          false
        ),
        (
          'switched to a Premium account',
          user(1, premium: false),
          user(2, premium: true),
          false
        ),
        ('signed out meanwhile', user(1, premium: false), null, false),
        ('signed out before', null, user(1, premium: true), false),
      ]) {
        SessionCache.instance.clear();
        if (start != null) SessionCache.instance.setUser(start);
        final resumed = await visit(tester, onPremium: () {
          SessionCache.instance.clear();
          if (end != null) SessionCache.instance.setUser(end);
        });
        expect(resumed, expected, reason: label);
      }
    });
  });

  testWidgets('a progress overlay closing later leaves the Premium prompt open',
      (tester) async {
    _tallView(tester);
    _signIn(_state());
    late BuildContext ctx;
    await tester.pumpWidget(_app(Builder(builder: (c) {
      ctx = c;
      return TextButton(onPressed: () {}, child: const Text('base'));
    })));

    // The overlay closes after something opened above it, and when it is on
    // top; either way only the overlay goes.
    for (final promptAbove in [true, false]) {
      final shown = AiProgressOverlay.show(ctx,
          kind: AiProgressKind.analysis, english: true);
      await _settleBriefly(tester);
      final handle = await shown;
      if (promptAbove) {
        unawaited(
            PremiumPromptSheet.show(ctx, PremiumFeature.dailyAnalysisLimit));
        await _settleBriefly(tester);
      }
      final closing = handle.dismiss();
      await _settleBriefly(tester);
      await closing;
      expect(find.byType(PremiumPromptSheet),
          promptAbove ? findsOneWidget : findsNothing);
      if (promptAbove) {
        await tester.tap(find.byKey(PremiumPromptSheet.notNowKey));
        await _settleBriefly(tester);
      }
      expect(find.text('base').hitTestable(), findsOneWidget,
          reason:
              'nothing left covering the screen (promptAbove=$promptAbove)');
    }
  });

  testWidgets('My CVs: the account lock shows even when the CV says allowed',
      (tester) async {
    for (final (state, chip) in [
      (_state(), true),
      (_state(premium: true), false),
      (_state(enforced: false), false),
    ]) {
      SessionCache.instance.clear();
      _signIn(state);
      await tester.pumpWidget(_app(CvDocumentCard(
        item: CvListItem.fromJson(
            {'id': 1, 'title': 'CV', 'is_draft': false, 'can_download': true}),
        onOpen: () {},
        onEdit: () {},
        onDelete: () {},
        onDownload: () {},
        onScan: () {},
      )));
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.byTooltip(l.cvCardMore));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumChip), chip ? findsOneWidget : findsNothing,
          reason: '$state');
      await tester.pumpWidget(const SizedBox());
    }
  });

  for (final language in ['en', 'ar']) {
    testWidgets('AI rewrite: the chip never covers the label ($language)',
        (tester) async {
      for (final (width, scale) in [(320.0, 1.0), (320.0, 1.6), (412.0, 2.0)]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        _signIn(_state());
        final controller = TextEditingController(text: 'x' * 80);
        addTearDown(controller.dispose);
        await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(
              size: Size(width, 900), textScaler: TextScaler.linear(scale)),
          child: _app(
            AiCvField(
              field: 'summary',
              controller: controller,
              english: language == 'en',
              isLoading: false,
              helperText: 'h',
              onEnhance: () {},
              onDismissResult: () {},
              child: AppTextFormField(controller: controller),
            ),
            language: language,
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$width x$scale');
        final l = await AppLocalizations.delegate.load(Locale(language));
        final label = tester.getRect(find.text(l.sharedAiEnhance));
        final chip = tester.getRect(find.byType(PremiumChip));
        expect(label.overlaps(chip), isFalse, reason: '$width x$scale');
      }
    });
  }
}
