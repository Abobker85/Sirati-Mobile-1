import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import 'non_text_contrast.dart';

enum _RingKind { hub, jobMatch }

enum _Fault {
  arcMatchesTrack,
  trackMatchesArc,
  arcMatchesCard,
  trackMatchesCard
}

void main() {
  for (final dark in [false, true]) {
    for (final kind in _RingKind.values) {
      testWidgets('$kind/$dark: raster probe samples every score on a 2x phone',
          (tester) async {
        usePhoneViewAtTextScale(tester);
        // Exhaust the bounded score domain, including empty/full and tiny arcs
        // or remainders. Repositioning also exercises fractional window offsets.
        for (var score = 0; score <= 100; score++) {
          await _pumpRing(tester, kind, dark, score);
          expect(
              await expectRenderedControlsAa(tester, '$kind/$dark/$score'), 1);
        }
      });

      for (final fault in _Fault.values) {
        testWidgets(
            '$kind/$dark: raster probe rejects $fault with colour decoys',
            (tester) async {
          usePhoneViewAtTextScale(tester);
          final random = math.Random(184);
          final scores = {
            1,
            50,
            99,
            for (var i = 0; i < 3; i++) 1 + random.nextInt(99)
          };
          for (final score in scores) {
            // The underlying widget still declares correct colours. Only its
            // rendered stroke is corrupted; correct-colour decoys are painted
            // outside the annulus inside the same bounding rectangle.
            await _pumpRing(tester, kind, dark, score, fault: fault);
            await expectLater(
              expectRenderedControlsAa(tester, '$kind/$dark/$score/$fault'),
              throwsA(isA<TestFailure>().having((error) => error.toString(),
                  'probe failure', contains('raster ring'))),
            );
          }
        });
      }
    }
  }
}

Future<void> _pumpRing(
    WidgetTester tester, _RingKind kind, bool dark, int score,
    {_Fault? fault}) async {
  final c = dark ? SiratiColors.dark : SiratiColors.light;
  await tester.pumpWidget(MaterialApp(
    theme:
        dark ? AppTheme.darkFor(arabic: true) : AppTheme.lightFor(arabic: true),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (_, child) => RepaintBoundary(key: phonePaintKey, child: child!),
    home: Scaffold(
      body: Align(
        alignment: Alignment((score - 50) / 100, -.29),
        child: ColoredBox(
          color: c.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox.square(
              dimension: kind == _RingKind.hub ? 128 : 224,
              child: Stack(fit: StackFit.expand, children: [
                if (kind == _RingKind.hub)
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    color: c.primaryInk,
                    backgroundColor: c.borderStrong,
                  )
                else
                  JobMatchScoreRing(score: score),
                if (fault != null)
                  CustomPaint(
                      painter: _FaultyRingPainter(kind, score, c, fault)),
              ]),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

class _FaultyRingPainter extends CustomPainter {
  _FaultyRingPainter(this.kind, this.score, this.colors, this.fault);

  final _RingKind kind;
  final int score;
  final SiratiColors colors;
  final _Fault fault;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = kind == _RingKind.hub ? 6.0 : 10.0;
    final rect =
        (Offset.zero & size).deflate(kind == _RingKind.hub ? 0 : stroke / 2);
    final arc = switch (fault) {
      _Fault.arcMatchesTrack => colors.borderStrong,
      _Fault.arcMatchesCard => colors.surface,
      _ => colors.primaryInk,
    };
    final track = switch (fault) {
      _Fault.trackMatchesArc => colors.primaryInk,
      _Fault.trackMatchesCard => colors.surface,
      _ => colors.borderStrong,
    };
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(rect.center, rect.width / 2, paint..color = track);
    final fullSweep = 2 * math.pi - (kind == _RingKind.hub ? .001 : 0);
    canvas.drawArc(
        rect, -math.pi / 2, score / 100 * fullSweep, false, paint..color = arc);
    final decoy = Paint()..color = colors.primaryInk;
    canvas.drawCircle(const Offset(8, 8), 3, decoy);
    canvas.drawCircle(Offset(size.width - 8, size.height - 8), 3,
        decoy..color = colors.borderStrong);
  }

  @override
  bool shouldRepaint(_FaultyRingPainter oldDelegate) => true;
}
