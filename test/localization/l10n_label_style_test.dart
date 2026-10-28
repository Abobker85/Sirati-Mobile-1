import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/icu_lite.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';

import '../support/l10n_label_capture.dart';

/// Invariants of the repaint data the l10n screen capture adds per label
/// (text, value, args, style, bg), for arbitrary strings, styles, widths,
/// directions and colours.

const _rootKey = ValueKey('root');

final _catalogs = {
  for (final l in ['ar', 'en']) l: readArbCatalog(l)
};

const _alignNames = {'start', 'end', 'left', 'right', 'center', 'justify'};
const _latinLetters = 'abcdefghijklmnopqrstuvwxyzéü';
const _arabicLetters = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';

/// Random words, never repeated, so no generated value is a whole-word part
/// of another one.
class _Words {
  _Words(this.random, bool arabic)
      : letters = arabic ? _arabicLetters : _latinLetters;

  final Random random;
  final String letters;
  final _used = <String>{};

  String word() {
    while (true) {
      final w = String.fromCharCodes(List.generate(3 + random.nextInt(5),
          (_) => letters.codeUnitAt(random.nextInt(letters.length))));
      if (_used.add(w)) return w;
    }
  }

  String take(int count) => List.generate(count, (_) => word()).join(' ');
}

Widget _app(
  L10nLabelRecorder recorder,
  Map<String, Map<String, String>> catalogs,
  String language,
  Widget Function(AppLocalizations l) body, {
  Color background = Colors.white,
}) =>
    RepaintBoundary(
      key: _rootKey,
      child: MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          RecordingLocalizationsDelegate(
              recorder: recorder, catalogs: catalogs),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          backgroundColor: background,
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: body(AppLocalizations.of(context)),
            ),
          ),
        ),
      ),
    );

List<LabelHit> _hits(WidgetTester tester, L10nLabelRecorder recorder) =>
    findLabelHits(
        tester.renderObject(find.byKey(_rootKey)), recorder.keysByValue,
        args: recorder.argsByKeyValue);

/// Hits whose rect lies in the widget with [id].
List<LabelHit> _in(WidgetTester tester, List<LabelHit> hits, String id) {
  final r = tester.getRect(find.byKey(ValueKey(id)));
  return hits
      .where((h) =>
          h.rect.left >= r.left - 0.5 &&
          h.rect.right <= r.right + 0.5 &&
          h.rect.top >= r.top - 0.5 &&
          h.rect.bottom <= r.bottom + 0.5)
      .toList();
}

RenderParagraph _paragraph(WidgetTester tester, String id) =>
    tester.renderObject<RenderParagraph>(find.descendant(
        of: find.byKey(ValueKey(id)), matching: find.byType(RichText)));

/// [message] with each `{name}` replaced by [args], or null when the
/// message has plural/select parts.
String? _substitute(String message, Map<String, String> args) {
  final out = StringBuffer();
  for (final node in IcuLite.parse(message)) {
    switch (node) {
      case IcuText(:final text):
        out.write(text);
      case IcuArg(:final name):
        out.write(args[name]);
      case IcuChoice():
        return null;
    }
  }
  return out.toString();
}

void _expectValidStyle(LabelStyle s) {
  expect(s.fontSize, greaterThan(0));
  expect(s.fontWeight, inInclusiveRange(100, 900));
  expect(s.fontWeight % 100, 0);
  expect(s.color, inInclusiveRange(0, 0xFFFFFF));
  expect(s.opacity, inInclusiveRange(0.0, 1.0));
  expect(_alignNames, contains(s.align));
  expect({'rtl', 'ltr'}, contains(s.direction));
  expect(s.lineHeight, greaterThan(0));
  expect(s.lines, greaterThanOrEqualTo(1));
  if (s.maxLines case final m?) expect(s.lines, lessThanOrEqualTo(m));
  final json = s.toJson();
  expect(json['color'], matches(RegExp(r'^#[0-9A-F]{6}$')));
}

Color _randomColor(Random random, {double minAlpha = 1}) => Color.fromARGB(
      ((minAlpha + random.nextDouble() * (1 - minAlpha)) * 255).round(),
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );

Object _sampleArg(String type, Random random, _Words words) => switch (type) {
      'int' || 'num' => 2 + random.nextInt(9000),
      'double' => (random.nextInt(10000) + 1) / 100,
      'DateTime' => DateTime.utc(2020 + random.nextInt(8),
          1 + random.nextInt(12), 1 + random.nextInt(28)),
      _ => words.take(1),
    };

void main() {
  const placeholderTypes = RemoteAppLocalizations.debugPlaceholderTypes;
  final plainKeys = [
    for (final e in placeholderTypes.entries)
      if (e.value.isEmpty) e.key,
  ];
  final stringArgKeys = [
    for (final e in placeholderTypes.entries)
      if (e.value.isNotEmpty &&
          e.value.every((t) => t == 'String' || t == 'Object'))
        e.key,
  ];
  final random = Random(20261028);

  for (final language in ['ar', 'en']) {
    testWidgets(
        '$language: every call with placeholders records args whose '
        'substitution into the ARB message reproduces the value',
        (tester) async {
      final recorder = L10nLabelRecorder();
      final words = _Words(random, false);
      final values = <String, String>{};
      await tester.pumpWidget(_app(recorder, _catalogs, language, (l) {
        for (final e in placeholderTypes.entries) {
          if (e.value.isEmpty) continue;
          values[e.key] = RemoteAppLocalizations.debugInvoke(l, e.key,
              [for (final t in e.value) _sampleArg(t, random, words)]);
        }
        return const SizedBox();
      }));
      final recorded = recorder.argsByKeyValue;
      var simple = 0;
      for (final MapEntry(:key, :value) in values.entries) {
        final message = _catalogs[language]![key]!;
        final args = recorded[(key, value.trim())];
        expect(args, isNotNull, reason: '$key: no args recorded');
        expect(args!.keys.toSet(), IcuLite.argumentNames(message).toSet(),
            reason: key);
        if (_substitute(message, args) case final expected?) {
          simple++;
          expect(expected.trim(), value.trim(), reason: key);
        }
      }
      expect(simple, greaterThan(0));
      // Plain labels never carry args.
      for (final (key, _) in recorded.keys) {
        expect(placeholderTypes[key], isNotEmpty);
      }
    });
  }

  for (var trial = 0; trial < 20; trial++) {
    final language = trial.isEven ? 'ar' : 'en';
    testWidgets(
        'trial $trial ($language): value lies in text and style is the '
        'painted style of the span carrying the key', (tester) async {
      // Tall enough that no wrapped paragraph is scrolled out of view.
      tester.view.physicalSize =
          const Size(800, 3000) * tester.view.devicePixelRatio;
      addTearDown(tester.view.reset);
      final words = _Words(random, language == 'ar');
      final argWords = _Words(random, false);
      final keys = [...plainKeys]..shuffle(random);
      final catalogs = {
        for (final e in _catalogs.entries) e.key: {...e.value},
      };
      const count = 5;
      final specs = [
        for (var i = 0; i < count; i++)
          (
            key: keys[i],
            size: 10.0 + random.nextInt(19),
            weight: FontWeight.values[random.nextInt(9)],
            color: _randomColor(random, minAlpha: 0.3),
            align: TextAlign.values[random.nextInt(TextAlign.values.length)],
            width: 60.0 + random.nextInt(260),
            maxLines: random.nextBool() ? null : 1 + random.nextInt(3),
            opacity: random.nextBool() ? 1.0 : 0.2 + random.nextDouble() * 0.8,
            family: random.nextBool() ? null : 'IBM Plex Sans Arabic',
          ),
      ];
      for (final s in specs) {
        catalogs[language]![s.key] = words.take(1 + random.nextInt(8));
      }
      final spanKey = keys[count];
      catalogs[language]![spanKey] = words.take(1 + random.nextInt(2));
      final spanStyle = TextStyle(
        fontSize: 10.0 + random.nextInt(19),
        fontWeight: FontWeight.values[random.nextInt(9)],
        color: _randomColor(random),
      );
      final interpolated = stringArgKeys[random.nextInt(stringArgKeys.length)];
      final args = [
        for (final _ in placeholderTypes[interpolated]!) argWords.take(1),
      ];
      final prefix = '${words.take(1)} ';
      final suffix = ' ${words.take(1)}';

      final recorder = L10nLabelRecorder();
      late String interpolatedValue;
      late String spanValue;
      await tester.pumpWidget(_app(recorder, catalogs, language, (l) {
        String t(String key) => RemoteAppLocalizations.debugInvoke(l, key, []);
        interpolatedValue =
            RemoteAppLocalizations.debugInvoke(l, interpolated, args);
        spanValue = t(spanKey);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, s) in specs.indexed)
              Opacity(
                opacity: s.opacity,
                child: SizedBox(
                  width: s.width,
                  child: Text(
                    t(s.key),
                    key: ValueKey('t$i'),
                    textAlign: s.align,
                    maxLines: s.maxLines,
                    overflow: s.maxLines == null ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: s.size,
                      fontWeight: s.weight,
                      color: s.color,
                      fontFamily: s.family,
                    ),
                  ),
                ),
              ),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black),
                children: [
                  TextSpan(text: prefix),
                  TextSpan(text: spanValue, style: spanStyle),
                  TextSpan(text: suffix),
                ],
              ),
              key: const ValueKey('span'),
            ),
            Text(interpolatedValue, key: const ValueKey('p')),
          ],
        );
      }));

      final hits = _hits(tester, recorder);
      final direction = language == 'ar' ? 'rtl' : 'ltr';
      for (final hit in hits) {
        expect(hit.text, contains(hit.value));
        expect(hit.value.trim(), hit.value);
        expect(hit.value, isNotEmpty);
        _expectValidStyle(hit.style!);
        // The room the text may grow into is never narrower than the text.
        if (hit.style!.maxWidth case final w?) {
          expect(w, greaterThanOrEqualTo(hit.rect.width - 0.5));
        }
        expect(hit.style!.direction, direction);
      }

      for (final (i, s) in specs.indexed) {
        final hit = hits.where((h) => h.key == s.key).single;
        final paragraph = _paragraph(tester, 't$i');
        final style = hit.style!;
        expect(hit.key, s.key);
        expect(hit.text, paragraph.text.toPlainText());
        expect(hit.value, catalogs[language]![s.key]!.trim());
        expect(hit.args, isNull);
        expect(style.fontSize, s.size);
        expect(style.fontWeight, s.weight.value);
        // Unset family: the ambient default text style's.
        final ambient =
            DefaultTextStyle.of(tester.element(find.byKey(ValueKey('t$i'))))
                .style
                .fontFamily;
        expect(style.fontFamily, s.family ?? ambient);
        expect(style.color, s.color.toARGB32() & 0xFFFFFF);
        expect(style.opacity, closeTo(s.color.a * s.opacity, 1e-9));
        expect(style.align, s.align.name);
        expect(style.maxLines, s.maxLines);
        // Lines and line height describe the laid-out paragraph: they add
        // up to its height and match the distinct painted line boxes.
        expect(style.lines * style.lineHeight,
            closeTo(paragraph.size.height, 0.01));
        final tops = paragraph
            .getBoxesForSelection(TextSelection(
                baseOffset: 0,
                extentOffset: paragraph.text.toPlainText().length))
            .map((b) => b.top.round())
            .toSet();
        expect(style.lines, tops.length);
      }

      final span = hits.where((h) => h.key == spanKey).single;
      expect(span.key, spanKey);
      expect(span.text, '$prefix$spanValue$suffix');
      expect(span.value, spanValue.trim());
      expect(span.style!.fontSize, spanStyle.fontSize);
      expect(span.style!.fontWeight, spanStyle.fontWeight!.value);
      expect(span.style!.color, spanStyle.color!.toARGB32() & 0xFFFFFF);

      final p = hits.where((h) => h.key == interpolated).single;
      final message = catalogs[language]![interpolated]!;
      expect(p.args, isNotNull);
      expect(p.args!.keys.toSet(), IcuLite.argumentNames(message).toSet());
      expect(p.args!.values.toSet(), args.toSet());
      if (_substitute(message, p.args!) case final expected?) {
        expect(expected.trim(), p.value);
      }
    });
  }

  for (final language in ['ar', 'en']) {
    testWidgets(
        '$language: bg is the solid colour each label is painted on, '
        'sampled from the rendered pixels', (tester) async {
      final words = _Words(random, language == 'ar');
      final keys = [...plainKeys]..shuffle(random);
      final catalogs = {
        for (final e in _catalogs.entries) e.key: {...e.value},
      };
      for (final key in keys.take(10)) {
        catalogs[language]![key] = words.take(1 + random.nextInt(3));
      }
      final page = _randomColor(random);
      final boxes = [for (var i = 0; i < 6; i++) _randomColor(random)];
      // A dark button with light text, and a light one with dark text.
      final darkButton = Color.fromARGB(
          255, random.nextInt(60), random.nextInt(60), random.nextInt(60));
      final lightButton = Color.fromARGB(255, 200 + random.nextInt(56),
          200 + random.nextInt(56), 200 + random.nextInt(56));
      final recorder = L10nLabelRecorder();
      await tester.pumpWidget(_app(recorder, catalogs, language, (l) {
        String t(String key) => RemoteAppLocalizations.debugInvoke(l, key, []);
        ButtonStyle button(Color bg, Color fg) => ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            );
        return Column(children: [
          Text(t(keys[0]), key: const ValueKey('page')),
          for (final (i, c) in boxes.indexed)
            Container(
              key: ValueKey('box$i'),
              color: c,
              margin: const EdgeInsets.all(4),
              padding: EdgeInsets.all(3.0 + random.nextInt(10)),
              child: Text(t(keys[1 + i]),
                  style: TextStyle(color: _randomColor(random))),
            ),
          ElevatedButton(
            key: const ValueKey('dark'),
            onPressed: () {},
            style: button(darkButton, Colors.white),
            child: Text(t(keys[7])),
          ),
          ElevatedButton(
            key: const ValueKey('light'),
            onPressed: () {},
            style: button(lightButton, Colors.black87),
            child: Text(t(keys[8])),
          ),
        ]);
      }, background: page));

      final hits = _hits(tester, recorder);
      const ratio = 2.0;
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(_rootKey));
      final (rgba, width, height) = (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: ratio);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final size = (image.width, image.height);
        image.dispose();
        return (data!, size.$1, size.$2);
      }))!;
      int bgOf(String id) => sampleBackground(
          rgba, width, height, _in(tester, hits, id).single.rect, ratio);
      int rgb(Color c) => c.toARGB32() & 0xFFFFFF;

      expect(bgOf('page'), rgb(page));
      for (final (i, c) in boxes.indexed) {
        expect(bgOf('box$i'), rgb(c), reason: 'box $i');
      }
      expect(bgOf('dark'), rgb(darkButton));
      expect(bgOf('light'), rgb(lightButton));
      expect(hits.first.toJson(bg: bgOf('page'))['bg'],
          matches(RegExp(r'^#[0-9A-F]{6}$')));
    });
  }
}
