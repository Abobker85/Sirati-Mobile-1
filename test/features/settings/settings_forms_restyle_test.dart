import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/presentation/avatar_crop_screen.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/features/settings/presentation/delete_account_screen.dart';
import 'package:sirati/features/settings/presentation/deleted_account_cleanup_screen.dart';
import 'package:sirati/features/settings/presentation/privacy_policy_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

import '../../support/contrast_probe.dart';

/// iOS 26 restyle, ticket 18: the settings forms and the privacy policy sit
/// on the grouped page, in every language and theme, with AA copy and
/// destructive ink that stays AA.

class _GatedAuth extends AuthApiService {
  Completer<void>? gate;
  int deletes = 0;

  @override
  Future<void> deleteAccount({
    String? password,
    String? provider,
    String? idToken,
    String? nonce,
  }) async {
    deletes++;
    await gate?.future;
  }
}

AuthUser _user(
        {required bool hasPassword, List<String> providers = const []}) =>
    AuthUser(
      id: 1,
      name: 'S',
      email: 's@example.com',
      emailVerified: true,
      hasPassword: hasPassword,
      socialProviders: providers,
    );

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF3366AA),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Image decode runs in real time, not fake test time.
Future<void> _engineWork(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  }
  await tester.pumpAndSettle();
}

void main() {
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
    AppLocale.languageCode.value = 'en';
  });

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      final label = '$language ${dark ? 'dark' : 'light'}';
      final arabic = language == 'ar';
      final theme = dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic);

      Future<void> pump(WidgetTester tester, Widget screen,
          {AuthApiService? auth}) async {
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        AppLocale.languageCode.value = language;
        await tester.pumpWidget(ProviderScope(
          key: UniqueKey(),
          overrides: [
            authApiServiceProvider.overrideWithValue(auth ?? _GatedAuth()),
          ],
          child: MaterialApp(
            theme: theme,
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: screen,
          ),
        ));
        await tester.pumpAndSettle();
      }

      SiratiColors colors(WidgetTester tester) =>
          tester.element(find.byType(Scaffold).first).sirati;

      AppLocalizations l10n(WidgetTester tester) =>
          AppLocalizations.of(tester.element(find.byType(Scaffold).first));

      /// The grouped-page invariants every owned screen holds at rest.
      void expectGroupedPage(WidgetTester tester, String screen) {
        final c = colors(tester);
        final scaffold = find.byType(Scaffold).first;
        final scaffoldElement = tester.element(scaffold);
        expect(PageSurface.of(scaffoldElement), PageSurfaceKind.grouped,
            reason: '$screen $label');
        final body = tester.widget<Scaffold>(scaffold).body!;
        expect(paintedBackgroundsOf(tester.element(find.byWidget(body))),
            [c.groupedBackground],
            reason: 'page colour of $screen ($label)');
        for (final bar in find.byType(AppBar).evaluate()) {
          final title = (bar.widget as AppBar).title!;
          expect(paintedBackgroundsOf(tester.element(find.byWidget(title))),
              [c.groupedBackground],
              reason: 'app bar of $screen ($label)');
        }

        // Grouped content has no bordered boxes: fill carries the edge.
        for (final element in find
            .descendant(of: scaffold, matching: find.byType(DecoratedBox))
            .evaluate()) {
          final d = (element.widget as DecoratedBox).decoration;
          // The segmented control's thumb (e.g. the language toggle) is a
          // selection indicator, not a content box: on a grouped page fills
          // alone cannot give it a 3:1 shape (ticket 22), so its edge is
          // exempt here and held to the stricter rule instead: the edge
          // must stand 3:1 off the track it slides on.
          if (element.widget.key == SegmentedTrack.thumbKey) {
            final edge = ((d as BoxDecoration).border! as Border).top;
            expect(edge.style, BorderStyle.solid, reason: '$screen ($label)');
            final trackElement = find
                .ancestor(
                    of: find.byWidget(element.widget),
                    matching: find.byKey(SegmentedTrack.trackKey))
                .evaluate()
                .single;
            final trackFill = ((trackElement.widget as DecoratedBox).decoration
                    as BoxDecoration)
                .color!;
            for (final page in paintedBackgroundsOf(trackElement)) {
              final track = Color.alphaBlend(trackFill, page);
              expect(
                AppContrast.ratio(Color.alphaBlend(edge.color, track), track),
                greaterThanOrEqualTo(3),
                reason: 'segmented thumb edge on $screen ($label)',
              );
            }
            continue;
          }
          // A section's hairline separator is a Divider, not a box edge.
          var inDivider = false;
          element.visitAncestorElements((a) {
            inDivider = a.widget is Divider;
            return !inDivider;
          });
          final border = d is BoxDecoration ? d.border : null;
          if (border is Border && !inDivider) {
            // Any styled side paints: width 0 is a hairline, not nothing.
            for (final side in [
              border.top,
              border.right,
              border.bottom,
              border.left,
            ]) {
              expect(side.style == BorderStyle.none, isTrue,
                  reason: 'bordered box on $screen ($label): $d');
            }
          } else if (border != null && !inDivider) {
            fail('unexpected border type on $screen ($label): $d');
          }
        }

        // Every field is filled with the grouped card fill.
        for (final element in find.byType(InputDecorator).evaluate()) {
          final decorator = element.widget as InputDecorator;
          final decoration = decorator.decoration
              .applyDefaults(Theme.of(element).inputDecorationTheme);
          expect(decoration.filled, isTrue, reason: '$screen ($label)');
          expect(decoration.fillColor, c.groupedCard,
              reason: 'field fill on $screen ($label)');
        }

        // Every button is a capsule with no outline and a 48 dp target.
        for (final element in find
            .descendant(of: scaffold, matching: find.byType(ButtonStyleButton))
            .evaluate()) {
          final button = element.widget as ButtonStyleButton;
          final t = Theme.of(element);
          final themed = switch (button) {
            ElevatedButton() => t.elevatedButtonTheme.style,
            FilledButton() => t.filledButtonTheme.style,
            OutlinedButton() => t.outlinedButtonTheme.style,
            _ => null,
          };
          if (themed == null) continue;
          final shape = button.style?.shape?.resolve(const {}) ??
              themed.shape?.resolve(const {});
          expect(shape, isA<StadiumBorder>(),
              reason: '${button.runtimeType} on $screen ($label)');
          final side = button.style?.side?.resolve(const {}) ??
              themed.side?.resolve(const {});
          expect(side == null || side.style == BorderStyle.none, isTrue,
              reason: 'outlined ${button.runtimeType} on $screen ($label)');
          expect(tester.getSize(find.byWidget(button)).height,
              greaterThanOrEqualTo(48));
        }

        expectAllTextAa('$screen $label');
        expectAllIconsAa('$screen $label');
      }

      testWidgets('change password is a grouped form ($label)', (tester) async {
        await pump(tester, const ChangePasswordScreen());
        expectGroupedPage(tester, 'change password');

        // Field headers are announced as headings.
        final t = l10n(tester);
        for (final header in [
          t.settingsCurrentPasswordLabel,
          t.authNewPasswordLabel,
          t.settingsConfirmNewPasswordLabel,
        ]) {
          expect(
            tester.getSemantics(find.text(header)),
            isSemantics(isHeader: true),
            reason: header,
          );
        }

        // Validation is unchanged: an empty submit shows the banner and an
        // error on every field, all AA on what they are painted on.
        await tester.tap(find.text(t.settingsUpdatePassword));
        await tester.pumpAndSettle();
        expect(find.text(t.authFixHighlightedFields), findsOneWidget);
        expect(find.text(t.settingsCurrentPasswordRequired), findsOneWidget);
        expect(find.text(t.settingsNewPasswordRequired), findsOneWidget);
        expect(find.text(t.settingsConfirmNewPasswordRequired), findsOneWidget);
        expectAllTextAa('change password errors $label');
        expectAllIconsAa('change password errors $label');
      });

      testWidgets(
          'delete with password: grouped, destructive ink is AA, '
          'one confirmation ($label)', (tester) async {
        final auth = _GatedAuth()..gate = Completer<void>();
        await pump(
          tester,
          DeleteAccountScreen(user: _user(hasPassword: true)),
          auth: auth,
        );
        expectGroupedPage(tester, 'delete password');
        final c = colors(tester);
        final t = l10n(tester);

        // Warning and delete action keep onErrorContainer ink.
        expect(
            tester
                .widget<Text>(find.text(t.settingsDeleteWarning))
                .style!
                .color,
            c.onErrorContainer);
        final action = find.text(t.settingsDeleteMyAccount);
        expect(
          tester.renderObject<RenderParagraph>(action).text.style!.color,
          c.onErrorContainer,
        );

        // Validation unchanged: empty password opens no dialog.
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(t.settingsDeletePasswordRequired), findsOneWidget);
        expectAllTextAa('delete password error $label');

        await tester.enterText(find.byType(TextField), 'secret');
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        final forever = find.text(t.settingsDeleteForever);
        expect(
          tester.renderObject<RenderParagraph>(forever).text.style!.color,
          c.onErrorContainer,
        );
        expectAllTextAa('delete dialog $label');

        await tester.tap(forever);
        await tester.pump();
        // Let the dialog's exit fade finish (the spinner never settles).
        await tester.pump(const Duration(milliseconds: 500));
        expect(auth.deletes, 1);

        // In flight: the row shows the loading label and ignores taps.
        expect(find.text(t.settingsDeleting), findsOneWidget);
        expectAllTextAa('delete loading $label');
        expectAllProgressIndicatorsAa('delete loading $label');
        await tester.tap(find.text(t.settingsDeleting), warnIfMissed: false);
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);
        expect(auth.deletes, 1);
        auth.gate!.complete();
        await tester.pump();
      });

      testWidgets(
          'delete with providers: one destructive grouped row per '
          'provider ($label)', (tester) async {
        await pump(
          tester,
          DeleteAccountScreen(
            user: _user(hasPassword: false, providers: ['google', 'apple']),
          ),
        );
        expectGroupedPage(tester, 'delete providers');
        final c = colors(tester);
        final t = l10n(tester);
        expect(find.byType(TextField), findsNothing);
        final section = find.byKey(AppListSection.cardKey);
        expect(section, findsOneWidget);
        for (final name in [t.authSocialGoogle, t.authSocialApple]) {
          final row = find.descendant(
            of: section,
            matching: find.text(t.settingsDeleteWithProvider(name)),
          );
          expect(row, findsOneWidget, reason: name);
          expect(
            tester.renderObject<RenderParagraph>(row).text.style!.color,
            c.onErrorContainer,
          );
        }
        expect(
          tester.getSemantics(find.text(t.settingsDeleteConfirmWithProvider)),
          isSemantics(isHeader: true),
        );
      });

      testWidgets('deleted-account cleanup is grouped ($label)',
          (tester) async {
        await pump(
            tester, DeletedAccountCleanupScreen(retryCleanup: () async {}));
        expectGroupedPage(tester, 'cleanup');
        expect(
          find.ancestor(
            of: find.text(l10n(tester).settingsCleanupMessage),
            matching: find.byWidgetPredicate(
                (w) => w is Material && w.color == colors(tester).groupedCard),
          ),
          findsOneWidget,
        );
      });

      testWidgets('privacy policy parts are grouped sections ($label)',
          (tester) async {
        await pump(tester, const PrivacyPolicyScreen());
        // The language toggle's thumb is on this page, so the exemption's
        // stricter edge check in expectGroupedPage runs here.
        expect(find.byKey(SegmentedTrack.thumbKey), findsOneWidget);
        expectGroupedPage(tester, 'privacy');
        final t = l10n(tester);
        final parts = [
          (t.settingsPrivacyCollectTitle, t.settingsPrivacyCollectBody),
          (t.settingsPrivacyUseTitle, t.settingsPrivacyUseBody),
          (t.settingsPrivacyProcessorsTitle, t.settingsPrivacyProcessorsBody),
          (t.settingsPrivacyRetentionTitle, t.settingsPrivacyRetentionBody),
        ];
        expect(find.byKey(AppListSection.cardKey), findsNWidgets(5));
        for (final (title, body) in parts) {
          expect(tester.getSemantics(find.text(title)),
              isSemantics(isHeader: true),
              reason: title);
          // The body sits inside a grouped card, not on the bare page.
          expect(
            find.ancestor(
                of: find.text(body),
                matching: find.byKey(AppListSection.cardKey)),
            findsOneWidget,
            reason: title,
          );
        }
      });

      testWidgets('avatar crop is grouped with capsule actions ($label)',
          (tester) async {
        final bytes = await tester.runAsync(() => _png(400, 300));
        tester.view.physicalSize = const Size(1080, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        AppLocale.languageCode.value = language;
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AvatarCropScreen(bytes: bytes!),
        ));
        await _engineWork(tester);
        expect(find.byKey(AvatarCropScreen.doneKey), findsOneWidget);
        expectGroupedPage(tester, 'avatar crop');
      });
    }
  }
}
