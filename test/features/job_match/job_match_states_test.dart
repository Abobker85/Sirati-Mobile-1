import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/dashboard/application/premium_gate_controller.dart';
import 'package:sirati/features/dashboard/domain/subscription_offer.dart';
import 'package:sirati/features/dashboard/presentation/premium_gate_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_result_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';
import '../../support/non_text_contrast.dart';
import 'job_match_test_support.dart';

void main() {
  testWidgets('plans return rechecks can_job_match before showing the form',
      (tester) async {
    usePhoneViewAtTextScale(tester);
    final auth = FakeAuth(subscription(subscribed: false, canJobMatch: false));
    final api = FakeJobMatchApi();
    await pumpJobMatch(tester, api: api, auth: auth, routes: _PlansRoute());
    await tapVisible(tester, find.byKey(const ValueKey('jm-gate-plans')));
    await settle(tester);
    expect(find.byType(PremiumGateScreen), findsOneWidget);
    auth.subscriptionState = subscription();
    await tapVisible(tester, find.byKey(PremiumGateScreen.refreshKey));
    await settle(tester);
    await tapVisible(tester, find.byKey(PremiumGateScreen.continueKey));
    await settle(tester);
    expect(auth.calls, 3);
    expect(find.byKey(JobMatchScreen.descriptionFieldKey), findsOneWidget);
    expect(api.createCalls, isEmpty);
  });

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final status in ['processing', 'failed', 'completed']) {
        testWidgets('$language/$dark/$status: phone at 2x, state and contrast',
            (tester) async {
          usePhoneViewAtTextScale(tester);
          final api = FakeJobMatchApi()
            ..createResponses.add(matchJson(
                aiStatus: status, applied: status == 'completed' ? ['s3'] : []))
            ..retryResponses.add(matchJson(aiStatus: 'processing'));
          final retry = Completer<Map<String, dynamic>>();
          if (status == 'failed') api.retryOverride = (_) => retry.future;
          await pumpJobMatch(
            tester,
            api: api,
            auth: FakeAuth(subscription()),
            language: language,
            theme: dark
                ? AppTheme.darkFor(arabic: language == 'ar')
                : AppTheme.lightFor(arabic: language == 'ar'),
            schedule: const [Duration(minutes: 5)],
          );
          await enterJob(tester);
          await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
          await settle(tester);
          expect(find.byType(JobMatchResultScreen), findsOneWidget);
          final context = tester.element(find.byType(JobMatchResultScreen));
          expect(Directionality.of(context),
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          await inspectPhoneScreen(tester, '$language/$dark/$status');
          await revealPhoneWidget(tester, find.byType(JobMatchScoreRing));
          await revealPhoneWidget(
              tester, find.byKey(const ValueKey('jm-keywords-matched')));
          await revealPhoneWidget(
              tester, find.byKey(const ValueKey('jm-keywords-missing')));
          final l = l10n(tester);

          switch (status) {
            case 'processing':
              await revealPhoneWidget(tester,
                  find.byKey(const ValueKey('jm-suggestions-skeleton')));
              expect(find.byKey(const ValueKey('jm-suggestions-skeleton')),
                  findsOneWidget);
              expect(find.byType(JobMatchSuggestionCard), findsNothing);
              expect(
                  tester
                      .widget<ElevatedButton>(
                          find.byKey(const ValueKey('jm-apply')))
                      .enabled,
                  isFalse);
            case 'failed':
              await revealPhoneWidget(
                  tester, find.byKey(const ValueKey('jm-retry-advice')));
              final retryButton = find.byKey(const ValueKey('jm-retry-advice'));
              expect(
                  tester.widget<ElevatedButton>(retryButton).enabled, isTrue);
              expect(
                  tester.getSize(retryButton).width,
                  tester
                          .getSize(
                              find.byKey(const ValueKey('jm-advice-failed')))
                          .width -
                      2 * AppSpacing.md);
              expect(find.byKey(const ValueKey('jm-advice-failed')),
                  findsOneWidget);
              expect(find.text(l.jobMatchFailedTitle), findsOneWidget);
              expect(find.text(l.jobMatchRetrySuggestions), findsOneWidget);
              expect(find.byKey(const ValueKey('jm-suggestions-skeleton')),
                  findsNothing);
            case 'completed':
              await revealPhoneWidget(tester,
                  find.byKey(JobMatchSuggestionCard.confirmationKey('s2')));
              expect(find.byType(JobMatchSuggestionCard), findsNWidgets(3));
              expect(find.text(l.jobMatchBefore), findsWidgets);
              expect(find.text(l.jobMatchAfter), findsWidgets);
              final confirm =
                  find.byKey(JobMatchSuggestionCard.confirmationKey('s2'));
              final select =
                  find.byKey(JobMatchSuggestionCard.checkboxKey('s2'));
              expect(tester.widget<Checkbox>(select).onChanged, isNull);
              await tapVisible(tester, confirm);
              await tapVisible(tester, select);
              await settle(tester);
              expect(tester.widget<Checkbox>(select).value, isTrue);
              expectPaintedControlsAa('$language/$dark confirmed and selected');
              await expectRenderedControlsAa(
                  tester, '$language/$dark confirmed and selected');
              expect(
                  tester
                      .widget<ElevatedButton>(
                          find.byKey(const ValueKey('jm-apply')))
                      .enabled,
                  isTrue);
              // Revoking the fact must also revoke selection and apply.
              await tapVisible(tester, confirm);
              await settle(tester);
              expect(tester.widget<Checkbox>(select).value, isFalse);
              expect(
                  tester
                      .widget<ElevatedButton>(
                          find.byKey(const ValueKey('jm-apply')))
                      .enabled,
                  isFalse);
          }

          expect(tester.takeException(), isNull);
          final label = '$language/$dark/$status at 2x';
          expectAllTextAa(label);
          expectAllIconsNonTextAa(label);
          expectPaintedControlsAa(label);
          // The score arc is meaningful, the track is decoration.
          final c = context.sirati;
          expect(AppContrast.ratio(c.primaryInk, c.surface),
              greaterThanOrEqualTo(3));
          // Fact confirmation paints on the warning container.
          expect(AppContrast.ratio(c.onWarningContainer, c.warningLight),
              greaterThanOrEqualTo(4.5));

          if (status == 'failed') {
            await tapVisible(tester, find.text(l.jobMatchRetrySuggestions));
            await tester.pump();
            final retryButton = find.byKey(const ValueKey('jm-retry-advice'));
            expect(tester.widget<ElevatedButton>(retryButton).enabled, isFalse);
            expectAllTextAa('$label retry busy first frame');
            expectAllIconsNonTextAa('$label retry busy first frame');
            expectPaintedControlsAa('$label retry busy first frame');
            await expectRenderedControlsAa(
                tester, '$label retry busy first frame');
            await inspectPhoneScreen(tester, '$label retry busy');
            retry.complete(matchJson(aiStatus: 'processing'));
            await settle(tester);
            expect(api.retryCalls, [7]);
            await revealPhoneWidget(
                tester, find.byKey(const ValueKey('jm-suggestions-skeleton')));
            expect(find.byKey(const ValueKey('jm-suggestions-skeleton')),
                findsOneWidget);
            await revealPhoneWidget(tester, find.byType(JobMatchScoreRing));
            expect(find.byType(JobMatchScoreRing), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}

class _PlansRoute extends FakeGeneratorRoute {
  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name != AppRoutes.premium) {
      return super.onGenerateRoute(settings);
    }
    return MaterialPageRoute<void>(
      builder: (_) => ProviderScope(
        overrides: [
          subscriptionOfferProvider.overrideWith(
            (_) async => const SubscriptionOffer(plans: []),
          ),
        ],
        child: const PremiumGateScreen(),
      ),
    );
  }
}
