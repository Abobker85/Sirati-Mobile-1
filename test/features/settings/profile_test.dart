import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/domain/profile_update.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Call {
  _Call(this.name, this.jobTitleId, this.jobTitleOther, this.clear,
      this.location);
  final String name;
  final int? jobTitleId;
  final String? jobTitleOther;
  final bool clear;
  final String? location;

  /// Whether the request body mentions the job title at all — mirrors
  /// AuthApiService.updateProfile's body construction.
  bool get touchesJobTitle =>
      clear || jobTitleId != null || jobTitleOther != null;
}

class _FakeAuth extends AuthApiService {
  _FakeAuth({required this.user});

  AuthUser user;
  Completer<void>? meGate;
  Completer<void>? saveGate;
  final calls = <_Call>[];

  @override
  Future<AuthUser?> me() async {
    await meGate?.future;
    return user;
  }

  @override
  Future<AuthUser> updateProfile({
    required String name,
    int? jobTitleId,
    String? jobTitleOther,
    bool clearJobTitle = false,
    String? location,
  }) async {
    calls.add(_Call(name, jobTitleId, jobTitleOther, clearJobTitle, location));
    await saveGate?.future;
    return user;
  }
}

JobTitle _title(int id, String slug) => JobTitle.fromJson(
    {'id': id, 'slug': slug, 'name_en': slug, 'name_ar': slug});

const _user = AuthUser(
  id: 1,
  name: 'Sara',
  email: 'sara@x.io',
  jobTitleId: 5,
);

void main() {
  group('ProfileRules', () {
    test('name and other title: required, trimmed, bounded', () {
      for (final (rule, max) in <(ProfileFieldError? Function(String?), int)>[
        (ProfileRules.name, 255),
        ((v) => ProfileRules.jobTitleOther(v, isOther: true), 120),
      ]) {
        for (final blank in [null, '', '   ']) {
          expect(rule(blank), ProfileFieldError.required);
        }
        expect(rule('  ${'a' * max}  '), isNull);
        expect(rule('a' * (max + 1)), ProfileFieldError.tooLong);
      }
      expect(ProfileRules.jobTitleOther('', isOther: false), isNull);
    });

    test('location: optional, trimmed, bounded', () {
      for (final blank in [null, '', '   ']) {
        expect(ProfileRules.location(blank), isNull);
      }
      const max = ProfileRules.locationMax;
      expect(ProfileRules.location('  ${'a' * max}  '), isNull);
      expect(ProfileRules.location('a' * (max + 1)), ProfileFieldError.tooLong);
    });
  });

  group('ProfileSaveController', () {
    late _FakeAuth auth;
    late ProviderContainer container;
    setUp(() {
      auth = _FakeAuth(user: _user);
      container = ProviderContainer(
        overrides: [authApiServiceProvider.overrideWithValue(auth)],
      );
      container.listen(profileSaveProvider, (_, __) {});
    });
    tearDown(() => container.dispose());

    Future<ProfileSaveOutcome> save(JobTitleChange change) => container
        .read(profileSaveProvider.notifier)
        .save(ProfileUpdate(name: '  Sara  ', jobTitle: change));

    test('each job-title change maps to exactly its request shape', () async {
      await save(const JobTitleUnchanged());
      await save(const JobTitleCleared());
      await save(const JobTitleSelected(3));
      await save(const JobTitleSelected(9, otherText: ' Chef '));

      expect(auth.calls.map((c) => c.name).toSet(), {'Sara'});
      expect(auth.calls[0].touchesJobTitle, isFalse,
          reason: 'unchanged must not mention the job title');
      expect(auth.calls[1].clear, isTrue);
      expect(auth.calls[2].jobTitleId, 3);
      expect(auth.calls[2].jobTitleOther, isNull);
      expect(auth.calls[3].jobTitleId, 9);
      expect(auth.calls[3].jobTitleOther, 'Chef');
    });

    test('location reaches the request for every job-title change', () async {
      const changes = <JobTitleChange>[
        JobTitleUnchanged(),
        JobTitleCleared(),
        JobTitleSelected(3),
        JobTitleSelected(9, otherText: 'Chef'),
      ];
      for (final location in [null, '', '  Jeddah  ', 'الخبر، السعودية']) {
        auth.calls.clear();
        for (final change in changes) {
          await container.read(profileSaveProvider.notifier).save(
              ProfileUpdate(name: 'Sara', jobTitle: change, location: location));
        }
        expect(auth.calls.map((c) => c.location).toSet(), {location?.trim()},
            reason: 'location "$location" must pass through unchanged');
      }
    });

    test('a second save while one is running is ignored', () async {
      auth.saveGate = Completer<void>();
      final first = save(const JobTitleUnchanged());
      expect(await save(const JobTitleUnchanged()), isA<ProfileSaveIgnored>());
      auth.saveGate!.complete();
      expect(await first, isA<ProfileSaved>());
      expect(auth.calls, hasLength(1));
      expect(container.read(profileSaveProvider), isFalse);
    });
  });

  group('ProfileScreen', () {
    setUp(() {
      AppLocale.languageCode.value = 'en';
      SessionCache.instance.clear();
    });

    Future<void> pump(
      WidgetTester tester,
      _FakeAuth auth, {
      required Future<List<JobTitle>> Function() titles,
      String language = 'en',
      bool dark = false,
    }) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authApiServiceProvider.overrideWithValue(auth),
          jobTitlesProvider.overrideWith((ref) => titles()),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkFor(arabic: language == 'ar')
              : AppTheme.lightFor(arabic: language == 'ar'),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ProfileScreen(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    for (final (label, titles) in <(String, Future<List<JobTitle>> Function())>[
      ('catalogue failed to load', () async => throw StateError('offline')),
      ('title was retired', () async => [_title(1, 'dev'), _title(2, 'other')]),
      ('title is listed', () async => [_title(5, 'pm'), _title(2, 'other')]),
    ]) {
      testWidgets('saving a name change keeps the job title ($label)',
          (tester) async {
        final auth = _FakeAuth(user: _user);
        await pump(tester, auth, titles: titles);

        await tester.enterText(find.byType(TextField).first, 'Sara Ahmed');
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();

        expect(auth.calls, hasLength(1));
        expect(auth.calls.single.name, 'Sara Ahmed');
        expect(auth.calls.single.touchesJobTitle, isFalse,
            reason: 'the saved job title must survive ($label)');
      });
    }

    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        testWidgets('title catalogue retry is actionable ($language, dark=$dark)', (tester) async {
          AppLocale.languageCode.value = language;
          var requests = 0;
          await pump(tester, _FakeAuth(user: _user), language: language, dark: dark,
              titles: () async {
                requests++;
                if (requests == 1) throw StateError('offline');
                return [_title(5, 'Platform engineer')];
              });
          final retry = find.widgetWithText(TextButton,
              language == 'en' ? 'Retry' : 'إعادة المحاولة');
          expect(retry, findsOneWidget);
          final size = tester.getSize(retry);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(requests, 2);
          expect(retry, findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    String fieldText(WidgetTester tester, String id) => tester
        .widget<TextField>(find.descendant(
          of: find.byKey(ValueKey('profile-$id')),
          matching: find.byType(TextField),
        ))
        .controller!
        .text;

    // Rows appear and disappear above the contact fields (the "Other" title
    // row shows once the catalogue loads; phone only when set). Whatever the
    // order of arrival, each field must show its own value.
    for (final cached in [false, true]) {
      for (final other in [false, true]) {
        for (final phone in [null, '+966 55 123 4567']) {
          for (final location in [null, 'Dammam', 'الدمام']) {
            testWidgets(
                'contact fields keep their own values '
                '(cached=$cached, other=$other, phone=$phone, '
                'location=$location)', (tester) async {
              final user = AuthUser(
                id: 1,
                name: 'Salem',
                email: 'salem@x.io',
                phone: phone,
                location: location,
                jobTitleId: other ? 2 : 5,
                jobTitleOther: other ? 'E-Commerce specialist' : null,
              );
              if (cached) SessionCache.instance.setUser(user);
              final catalogue = Completer<List<JobTitle>>();
              final auth = _FakeAuth(user: user);
              tester.view.physicalSize = const Size(1080, 3000);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(ProviderScope(
                overrides: [
                  authApiServiceProvider.overrideWithValue(auth),
                  jobTitlesProvider.overrideWith((ref) => catalogue.future),
                ],
                child: MaterialApp(
                  theme: AppTheme.lightFor(arabic: false),
                  locale: const Locale('en'),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  home: const ProfileScreen(),
                ),
              ));
              await tester.pump();
              catalogue.complete([_title(5, 'pm'), _title(2, 'other')]);
              await tester.pumpAndSettle();

              expect(fieldText(tester, 'email'), 'salem@x.io');
              if (phone == null) {
                expect(find.byKey(const ValueKey('profile-phone')),
                    findsNothing);
              } else {
                expect(fieldText(tester, 'phone'), phone);
              }
              expect(fieldText(tester, 'location'), location ?? '');
            });
          }
        }
      }
    }

    for (final typed in [null, 'Riyadh', '  الرياض  ', '']) {
      testWidgets('location is sent only when edited (typed=$typed)',
          (tester) async {
        final auth = _FakeAuth(
          user: const AuthUser(
              id: 1, name: 'Sara', email: 'sara@x.io', location: 'Dammam'),
        );
        await pump(tester, auth, titles: () async => [_title(5, 'pm')]);

        if (typed != null) {
          await tester.enterText(
              find.descendant(
                of: find.byKey(const ValueKey('profile-location')),
                matching: find.byType(TextField),
              ),
              typed);
        }
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(auth.calls.single.location, typed?.trim(),
            reason: 'untouched location must not be sent; edits are trimmed');
      });
    }

    testWidgets('a late profile response does not overwrite typed edits',
        (tester) async {
      SessionCache.instance.setUser(_user);
      final auth = _FakeAuth(user: _user)..meGate = Completer<void>();
      await pump(tester, auth, titles: () async => [_title(5, 'pm')]);

      await tester.enterText(find.byType(TextField).first, 'Typed Name');
      auth.user = const AuthUser(id: 1, name: 'Server Name', email: 'a@b.c');
      auth.meGate!.complete();
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, 'Typed Name');
    });
  });
}
