import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';

RemoteL10nState _state(Map<String, Map<String, String>> strings) =>
    RemoteL10nState(
      languages: const RemoteLanguageList(languages: []),
      bundles: {
        for (final e in strings.entries)
          e.key: RemoteStringBundle(code: e.key, version: 1, strings: e.value),
      },
    );

/// Catalog key behind the default title of each error class. Every class
/// must be listed, so a new [ApiErrorType] without a remote label fails here.
const _titleKeys = {
  // Network errors show the full-screen OfflineView.
  ApiErrorType.network: 'sharedOfflineTitle',
  ApiErrorType.timeout: 'sharedErrorTitleTimeout',
  ApiErrorType.auth: 'sharedErrorTitleAuth',
  ApiErrorType.notFound: 'sharedErrorTitleNotFound',
  ApiErrorType.server: 'sharedErrorTitleServer',
  ApiErrorType.rateLimited: 'sharedErrorTitleRateLimited',
  ApiErrorType.validation: 'sharedErrorTitleUnknown',
  ApiErrorType.unknown: 'sharedErrorTitleUnknown',
};

String _randomLabel(Random random) {
  const pool = ['a', 'Z', ' ', 'سارة', '7', '—', 'é', '!'];
  return 'L${List.generate(1 + random.nextInt(10), (_) => pool[random.nextInt(pool.length)]).join()}';
}

void main() {
  final random = Random(9071);

  Widget app(
    ValueNotifier<RemoteL10nState> state,
    Locale locale,
    Widget child,
  ) =>
      ValueListenableBuilder<RemoteL10nState>(
        valueListenable: state,
        builder: (context, value, _) => MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: appSupportedLocales(value),
          localizationsDelegates: appLocalizationsDelegates(value),
          home: Scaffold(body: child),
        ),
      );

  test('every error class maps to a catalog key', () {
    expect(_titleKeys.keys.toSet(), ApiErrorType.values.toSet());
  });

  for (final code in bundledLanguageCodes) {
    for (final type in ApiErrorType.values) {
      testWidgets(
          '$code/${type.name}: AppErrorState shows remote overrides of its '
          'migrated labels and follows live updates', (tester) async {
        final title = _randomLabel(random);
        final retry = _randomLabel(random);
        final state = ValueNotifier(_state({
          code: {_titleKeys[type]!: title, 'retry': retry},
        }));
        await tester.pumpWidget(app(
          state,
          Locale(code),
          AppErrorState(
            message: 'server message',
            english: code == 'en',
            errorType: type,
            onRetry: () {},
          ),
        ));

        expect(find.text(title), findsOneWidget);
        expect(find.text(retry), findsOneWidget);
        final bundled = lookupAppLocalizations(Locale(code));
        expect(find.text(bundled.retry), findsNothing);

        // Clearing the override falls back to the bundled ARB text.
        state.value = _state(const {});
        await tester.pump();
        expect(find.text(title), findsNothing);
        expect(find.text(bundled.retry), findsOneWidget);
      });
    }
  }
}
