import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/utils/app_locale.dart';
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
  'jobsCategoryTech',
  'jobsCategoryFinance',
  'jobsCategoryHealth',
  'jobsCityAll',
  'jobsCityRiyadh',
  'jobsCityJeddah',
  'jobsCityDammam',
  'jobsCityKhobar',
  'jobsCityMecca',
  'jobsCityMedina',
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
        CategoryChips(
          english: english,
          selectedCategory: 'all',
          onSelected: (_) {},
        ),
        CityChips(english: english, selectedCity: 'all', onSelected: (_) {}),
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

    testWidgets('a remote match-score label formats its placeholder ($code)',
        (tester) async {
      AppLocale.languageCode.value = code;
      for (final score in [0, 1, 7, 88, 100]) {
        final job = JobNews.fromJson({
          'id': score + 1,
          'title': 'Data Analyst',
          'body': 'SQL',
          'match_score': score,
        });
        await tester.pumpWidget(_app(
          _state(code, {'jobsMatchScore': '[{score}] fit'}),
          code,
          FeaturedJobCard(item: job, english: code == 'en', onTap: () {}),
        ));
        expect(find.text('[$score] fit'), findsOneWidget, reason: '$score');
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
      'jobsCategoryTech': l.jobsCategoryTech,
      'jobsCategoryFinance': l.jobsCategoryFinance,
      'jobsCategoryHealth': l.jobsCategoryHealth,
      'jobsCityAll': l.jobsCityAll,
      'jobsCityRiyadh': l.jobsCityRiyadh,
      'jobsCityJeddah': l.jobsCityJeddah,
      'jobsCityDammam': l.jobsCityDammam,
      'jobsCityKhobar': l.jobsCityKhobar,
      'jobsCityMecca': l.jobsCityMecca,
      'jobsCityMedina': l.jobsCityMedina,
    };
