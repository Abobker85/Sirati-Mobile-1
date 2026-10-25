import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/presentation/avatar_crop_screen.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _Auth extends AuthApiService {
  final uploads = <List<int>>[];
  int deletes = 0;
  AuthUser user = const AuthUser(id: 1, name: 'Salem', email: 's@x.io');

  @override
  Future<AuthUser?> me() async => user;

  @override
  Future<AuthUser> uploadAvatar(List<int> pngBytes) async {
    uploads.add(pngBytes);
    user = const AuthUser(
        id: 1, name: 'Salem', email: 's@x.io', avatarUrl: 'https://x.test/a.png');
    SessionCache.instance.setUser(user);
    return user;
  }

  @override
  Future<AuthUser> deleteAvatar() async {
    deletes++;
    user = const AuthUser(id: 1, name: 'Salem', email: 's@x.io');
    SessionCache.instance.setUser(user);
    return user;
  }
}

/// A [width]x[height] PNG whose left half is red and right half blue.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
      Paint()..color = const Color(0xFFFF0000));
  canvas.drawRect(Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
      Paint()..color = const Color(0xFF0000FF));
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Image decode and encode finish in real time, not fake test time: let
/// them run between frames until the screen settles.
Future<void> _engineWork(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)));
  }
  await tester.pumpAndSettle();
}

void main() {  group('avatarSourceRect', () {
    // Whatever the image shape, zoom and pan, the crop is a square inside
    // the image showing exactly what the round window shows.
    for (final (w, h) in [(1000.0, 600.0), (600.0, 1000.0), (512.0, 512.0), (3000.0, 4000.0)]) {
      for (final zoom in [1.0, 1.7, 5.0]) {
        for (final (dx, dy) in [(0.0, 0.0), (-80.0, -40.0), (500.0, 500.0), (-9999.0, -9999.0)]) {
          test('${w}x$h zoom=$zoom pan=($dx,$dy)', () {
            const viewport = 320.0;
            final base = viewport / (w < h ? w : h);
            final transform = Matrix4.identity()
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(zoom, zoom, 1, 1);
            final rect = avatarSourceRect(
              image: Size(w, h),
              viewport: viewport,
              baseScale: base,
              transform: transform,
            );
            expect(rect.width, closeTo(rect.height, 1e-9));
            expect(rect.width, closeTo(viewport / (base * zoom), 1e-6));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(w + 1e-9));
            expect(rect.bottom, lessThanOrEqualTo(h + 1e-9));
          });
        }
      }
    }
  });

  testWidgets('the crop screen hands back a square PNG of the window',
      (tester) async {
    final source = await tester.runAsync(() => _png(800, 400));
    Uint8List? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Uint8List>(
              MaterialPageRoute(
                builder: (_) => AvatarCropScreen(bytes: source!, english: true),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await _engineWork(tester);
    await tester.tap(find.byKey(AvatarCropScreen.doneKey));
    await _engineWork(tester);

    expect(result, isNotNull);
    final decoded = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(result!);
      return (await codec.getNextFrame()).image;
    });
    expect(decoded!.width, avatarOutputSize);
    expect(decoded.height, avatarOutputSize);
    // Centred on a wide red|blue image: both halves show, red on the left.
    final pixels = await tester.runAsync(
        () => decoded.toByteData(format: ui.ImageByteFormat.rawRgba));
    int red(int x) => pixels!.getUint8((256 * avatarOutputSize + x) * 4);
    expect(red(20), greaterThan(200));
    expect(red(avatarOutputSize - 20), lessThan(50));
  });

  for (final language in ['ar', 'en']) {
    testWidgets('$language: gallery → crop → upload, then remove', (tester) async {
      AppLocale.languageCode.value = language;
      SessionCache.instance.clear();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final auth = _Auth();
      final picked = <ImageSource>[];
      final source = await tester.runAsync(() => _png(600, 900));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authApiServiceProvider.overrideWithValue(auth),
          jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
          profilePhotoPickerProvider.overrideWithValue((s) async {
            picked.add(s);
            return source;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: language == 'ar'),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ProfileScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profile-photo-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-photo-remove')), findsNothing,
          reason: 'nothing to remove yet');
      await tester.tap(find.byKey(const ValueKey('profile-photo-gallery')));
      await _engineWork(tester);
      await tester.tap(find.byKey(AvatarCropScreen.doneKey));
      await _engineWork(tester);

      expect(picked, [ImageSource.gallery]);
      expect(auth.uploads, hasLength(1));
      final uploaded = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(auth.uploads.single));
        return (await codec.getNextFrame()).image;
      });
      expect((uploaded!.width, uploaded.height), (avatarOutputSize, avatarOutputSize));
      expect(SessionCache.instance.user.value?.avatarUrl, 'https://x.test/a.png');

      await tester.tap(find.byKey(const ValueKey('profile-photo-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-photo-remove')));
      await tester.pumpAndSettle();
      expect(auth.deletes, 1);
      expect(SessionCache.instance.user.value?.avatarUrl, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancelling the picker or the crop uploads nothing', (tester) async {
    AppLocale.languageCode.value = 'en';
    final auth = _Auth();
    var pick = 0;
    final source = await tester.runAsync(() => _png(300, 300));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authApiServiceProvider.overrideWithValue(auth),
        jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
        profilePhotoPickerProvider.overrideWithValue((_) async => pick++ == 0 ? null : source),
      ],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ProfileScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('profile-photo-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-photo-camera')));
      await _engineWork(tester);
      if (find.text('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
    expect(pick, 2);
    expect(auth.uploads, isEmpty);
  });
}
