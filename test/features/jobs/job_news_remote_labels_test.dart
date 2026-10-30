import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Labels the job news filter bar reads from the catalog.
const _filterBarKeys = [
  'jobsFilterAll',
  'jobsPresetMatched',
  'jobsPresetGov',
  'jobsPresetEnterprise',
  'jobsPresetTamheer',
  'jobsFilterRemote',
  'jobsSearchHint',
  'jobsRegionAll',
  'jobsRegionCentral',
  'jobsRegionEastern',
  'jobsRegionWestern',
  'jobsRegionNorthern',
  'jobsRegionSouthern',
];

RemoteL10nState _state(String code, Map<String, String> strings) =>
    RemoteL10nState(
      bundles: {
        code: RemoteStringBundle(code: code, version: 1, strings: strings),
      },
    );

Widget _app(RemoteL10nState state, String code, Widget child) => MaterialApp(
      theme: AppTheme.lightFor(arabic: code == 'ar'),
      locale: Locale(code),
      supportedLocales: appSupportedLocales(state),
      localizationsDelegates: appLocalizationsDelegates(state),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Widget _filterBar(bool english) => Column(
      children: [
        JobSearchBar(
          english: english,
          controller: TextEditingController(),
          onChanged: (_) {},
        ),
        PresetChips(
          english: english,
          selectedPreset: 'all',
          onSelected: (_) {},
        ),
        RegionChips(selectedRegion: 'all', onSelected: (_) {}),
      ],
    );

void main() {
  tearDown(() => AppLocale.languageCode.value = 'ar');

  for (final code in ['ar', 'en']) {
    testWidgets('every job news filter label shows its remote override ($code)',
        (tester) async {
      AppLocale.languageCode.value = code;
      final bundled = lookupAppLocalizations(Locale(code));
      final bundledText = _bundledTexts(bundled);
      final overrides = {
        for (final key in _filterBarKeys) key: 'remote:$code:$key',
      };

      await tester.pumpWidget(
        _app(_state(code, overrides), code, _filterBar(code == 'en')),
      );

      for (final entry in overrides.entries) {
        expect(find.text(entry.value), findsWidgets, reason: entry.key);
        expect(find.text(bundledText[entry.key]!), findsNothing,
            reason: '${entry.key} still shows the bundled text');
      }
    });

    testWidgets('a remote apply-host label formats its placeholder ($code)',
        (tester) async {
      AppLocale.languageCode.value = code;
      for (final host in ['jadarat.sa', 'careers.acme.example', 'forms.gle']) {
        final job = JobNews.fromJson({
          'id': host.length,
          'title': 'Data Analyst',
          'body': 'SQL',
          'apply_method': 'url',
          'apply_url': 'https://www.$host/jobs/1',
        });
        await tester.pumpWidget(_app(
          _state(code, {'jobsApplyOpensHost': '[{host}] site'}),
          code,
          FeaturedJobCard(item: job, english: code == 'en', onTap: () {}),
        ));
        expect(find.text('[${ltrIsolate(host)}] site'), findsOneWidget,
            reason: host);
      }
    });
  }
}

/// Bundled text of each migrated key, read through the generated getters so
/// the test fails if a key is renamed or removed from the catalog.

Map<String, String> _bundledTexts(AppLocalizations l) => {
      'jobsFilterAll': l.jobsFilterAll,
      'jobsPresetMatched': l.jobsPresetMatched,
      'jobsPresetGov': l.jobsPresetGov,
      'jobsPresetEnterprise': l.jobsPresetEnterprise,
      'jobsPresetTamheer': l.jobsPresetTamheer,
      'jobsFilterRemote': l.jobsFilterRemote,
      'jobsSearchHint': l.jobsSearchHint,
      'jobsRegionAll': l.jobsRegionAll,
      'jobsRegionCentral': l.jobsRegionCentral,
      'jobsRegionEastern': l.jobsRegionEastern,
      'jobsRegionWestern': l.jobsRegionWestern,
      'jobsRegionNorthern': l.jobsRegionNorthern,
      'jobsRegionSouthern': l.jobsRegionSouthern,
    };
