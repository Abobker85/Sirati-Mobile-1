import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';

import '../support/l10n_label_capture.dart';

/// Invariants of the l10n screen-capture tool (test_screens/): every label
/// lookup is recorded with its key, and every painted text run that shows a
/// recorded value is reported with that key (all keys when shared) at the
/// rect where it is painted — whatever the strings, language or direction.

const _rootKey = ValueKey('root');

final _catalogs = {
  for (final l in ['ar', 'en']) l: readArbCatalog(l)
};

const _latin = [
  'alpha',
  'bravo',
  'cedar',
  'delta',
  'ember',
  'fjord',
  'grove',
  'harbor',
  'indigo',
  'jasper',
  'kettle',
  'lumen',
  'meadow',
  'nectar',
  'orbit',
  'pebble',
  'quartz',
  'raven',
  'summit',
  'tundra',
  'umber',
  'velvet',
  'willow',
  'xenon',
  'yonder',
  'zephyr',
  'Café',
  'naïve',
  'Ünïcode',
  'São',
];

const _arabic = [
  'سيرة',
  'مهارات',
  'وظيفة',
  'تحليل',
  'خبرة',
  'تعليم',
  'شهادة',
  'لغة',
  'مشروع',
  'هدف',
  'إنجاز',
  'فريق',
  'قيادة',
  'تواصل',
  'تصميم',
  'برمجة',
  'بيانات',
  'مراجعة',
  'تطوير',
  'نجاح',
  'مستقبل',
  'رؤية',
  'إبداع',
  'جودة',
  'سرعة',
  'دقة',
  'أمان',
  'ثقة',
  'مرونة',
  'حلول',
];

/// Distinct words, so no generated label is a whole-word part of another.
class _Words {
  _Words(Random random, bool arabic)
      : _pool = [...(arabic ? _arabic : _latin)]..shuffle(random);

  final List<String> _pool;
  var _next = 0;

  String take([int count = 1]) =>
      List.generate(count, (_) => _pool[_next++]).join(' ');
}

Widget _app(
  L10nLabelRecorder recorder,
  Map<String, Map<String, String>> catalogs,
  String language,
  Widget Function(AppLocalizations l) body,
) =>
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
          body: Builder(
            builder: (context) => Center(
              child: body(AppLocalizations.of(context)),
            ),
          ),
        ),
      ),
    );

Object _sampleArg(String type) => switch (type) {
      'int' || 'num' => 3,
      'double' => 2.5,
      'DateTime' => DateTime.utc(2026, 1, 2),
      _ => 'x',
    };

List<LabelHit> _hits(WidgetTester tester, L10nLabelRecorder recorder) =>
    findLabelHits(
        tester.renderObject(find.byKey(_rootKey)), recorder.keysByValue);

List<LabelHit> _within(List<LabelHit> hits, Rect rect) => hits
    .where((h) =>
        h.rect.left >= rect.left - 0.5 &&
        h.rect.right <= rect.right + 0.5 &&
        h.rect.top >= rect.top - 0.5 &&
        h.rect.bottom <= rect.bottom + 0.5)
    .toList();

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

  for (final language in ['ar', 'en']) {
    testWidgets('$language: every label lookup is recorded under its key',
        (tester) async {
      final recorder = L10nLabelRecorder();
      final values = <String, String>{};
      await tester.pumpWidget(_app(recorder, _catalogs, language, (l) {
        for (final e in placeholderTypes.entries) {
          values[e.key] = RemoteAppLocalizations.debugInvoke(
              l, e.key, [for (final t in e.value) _sampleArg(t)]);
        }
        return const SizedBox();
      }));
      final recorded = recorder.keysByValue;
      for (final e in values.entries) {
        if (e.value.trim().isEmpty) continue;
        expect(recorded[e.value.trim()], contains(e.key),
            reason: '${e.key} returned "${e.value}" without being recorded');
      }
      // Nothing is recorded that the app did not show for that key.
      for (final e in recorded.entries) {
        for (final key in e.value) {
          expect(values[key]!.trim(), e.key);
        }
      }
    });
  }

  final random = Random(20261028);
  for (var trial = 0; trial < 24; trial++) {
    final language = trial.isEven ? 'ar' : 'en';
    testWidgets(
        'trial $trial ($language): shared, interpolated, span and embedded '
        'labels map to all their keys at their painted rect', (tester) async {
      final words = _Words(random, language == 'ar');
      // Latin arguments inside Arabic messages: mixed-direction runs.
      final argWords = _Words(random, false);
      final keys = [...plainKeys]..shuffle(random);
      final sharedA = keys[0], sharedB = keys[1];
      final unique = keys[2], inSpan = keys[3], embedded = keys[4];
      final interpolated = stringArgKeys[random.nextInt(stringArgKeys.length)];

      final shared = words.take(1 + random.nextInt(2));
      final catalogs = {
        for (final e in _catalogs.entries) e.key: {...e.value},
      };
      catalogs[language]!.addAll({
        sharedA: shared,
        sharedB: shared,
        unique: words.take(1 + random.nextInt(3)),
        inSpan: words.take(1 + random.nextInt(2)),
        embedded: words.take(1 + random.nextInt(2)),
      });
      final args = [
        for (final _ in placeholderTypes[interpolated]!) argWords.take(),
      ];
      final prefix = '${words.take()} ';
      final suffix = ' ${words.take()}';
      final dynamicValue = words.take();
      final unrelated = '#${random.nextInt(1 << 20)} ${words.take(2)}';

      final recorder = L10nLabelRecorder();
      late String interpolatedValue;
      await tester.pumpWidget(_app(recorder, catalogs, language, (l) {
        String t(String key) => RemoteAppLocalizations.debugInvoke(l, key, []);
        interpolatedValue =
            RemoteAppLocalizations.debugInvoke(l, interpolated, args);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t(sharedA), key: const ValueKey('a')),
            Text(t(sharedB), key: const ValueKey('b')),
            Text(t(unique), key: const ValueKey('c')),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: t(inSpan),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: suffix),
              ]),
              key: const ValueKey('span'),
            ),
            Text(interpolatedValue, key: const ValueKey('p')),
            Text('${t(embedded)}: $dynamicValue', key: const ValueKey('e')),
            Text(unrelated, key: const ValueKey('u')),
          ],
        );
      }));

      // Recording: one value used by two keys keeps both.
      expect(recorder.keysByValue[shared], containsAll([sharedA, sharedB]));
      expect(recorder.keysByValue[interpolatedValue.trim()],
          contains(interpolated));

      final hits = _hits(tester, recorder);
      Rect rectOf(String id) => tester.getRect(find.byKey(ValueKey(id)));
      // Widest painted line: a wrapped paragraph is wider than its text.
      List<LineMetrics> linesOf(String id) {
        final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
            of: find.byKey(ValueKey(id)), matching: find.byType(RichText)));
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        final lines = painter.computeLineMetrics();
        painter.dispose();
        return lines;
      }

      // The box spans the widest line and every line's baseline.
      void expectCoversText(String id, Rect hit) {
        final lines = linesOf(id);
        final top = rectOf(id).top;
        // Wrapped lines may add their trailing space; never beyond the box.
        expect(hit.width,
            greaterThanOrEqualTo(lines.map((m) => m.width).reduce(max) - 0.5));
        expect(hit.width, lessThanOrEqualTo(rectOf(id).width + 0.5));
        expect(hit.top, lessThan(top + lines.first.baseline));
        expect(hit.bottom, greaterThan(top + lines.last.baseline));
      }

      Set<String> keysIn(String id) =>
          _within(hits, rectOf(id)).map((h) => h.key).toSet();

      // Exact paragraphs: every key of the value, covering the whole run.
      for (final id in ['a', 'b']) {
        expect(keysIn(id), {sharedA, sharedB});
        final rects = _within(hits, rectOf(id)).map((h) => h.rect).toSet();
        expect(rects, hasLength(1), reason: 'both keys share one rect');
        expectCoversText(id, rects.single);
      }
      expect(keysIn('c'), {unique});
      expect(keysIn('p'), {interpolated});
      expectCoversText('p', _within(hits, rectOf('p')).single.rect);

      // Span / embedded: a strictly narrower box inside the paragraph, on
      // the side the reading direction puts it.
      final rtl = language == 'ar';
      for (final (id, key) in [('span', inSpan), ('e', embedded)]) {
        expect(keysIn(id), {key});
        final hit = _within(hits, rectOf(id)).single.rect;
        final paragraph = rectOf(id);
        expect(hit.width, lessThan(paragraph.width - 1));
        if (id == 'span') {
          // Prefix comes first in reading order, suffix last.
          expect(
              rtl ? hit.right : hit.left,
              rtl
                  ? lessThan(paragraph.right - 1)
                  : greaterThan(paragraph.left + 1));
          expect(
              rtl ? hit.left : hit.right,
              rtl
                  ? greaterThan(paragraph.left + 1)
                  : lessThan(paragraph.right - 1));
        } else {
          // Label leads the dynamic value.
          expect(rtl ? hit.right : hit.left,
              closeTo(rtl ? paragraph.right : paragraph.left, 0.5));
        }
      }
      expect(keysIn('u'), isEmpty);

      // Sound and complete: no other keys, sorted, deduped.
      expect(hits.map((h) => h.key).toSet(),
          {sharedA, sharedB, unique, inSpan, embedded, interpolated});
      expect(hits.toSet(), hasLength(hits.length));
      for (var i = 1; i < hits.length; i++) {
        final a = hits[i - 1].rect, b = hits[i].rect;
        expect(a.top < b.top || (a.top == b.top && a.left <= b.left), isTrue);
      }
    });
  }

  for (final language in ['ar', 'en']) {
    testWidgets(
        '$language: offstage, transparent, covered and scrolled-out '
        'labels are not reported', (tester) async {
      final keys = [...plainKeys]..shuffle(random);
      final visible = keys[0], visible2 = keys[5];
      final hint = keys[6];
      final hidden = keys.sublist(1, 5);
      final words = _Words(random, language == 'ar');
      final catalogs = {
        for (final e in _catalogs.entries) e.key: {...e.value},
      };
      for (final key in [visible, visible2, hint, ...hidden]) {
        catalogs[language]![key] = words.take(2);
      }
      final recorder = L10nLabelRecorder();
      await tester.pumpWidget(_app(recorder, catalogs, language, (l) {
        String t(String key) => RemoteAppLocalizations.debugInvoke(l, key, []);
        return SizedBox(
          height: 120,
          child: SingleChildScrollView(
            child: Column(children: [
              Text(t(visible)),
              // Hint under the field's own (empty) editable: visible.
              TextField(decoration: InputDecoration(hintText: t(hint))),
              Offstage(child: Text(t(hidden[0]))),
              Opacity(opacity: 0, child: Text(t(hidden[1]))),
              // Painted over by an opaque surface (as a sheet or barrier).
              Stack(children: [
                Text(t(hidden[3])),
                const Positioned.fill(child: ColoredBox(color: Colors.white)),
              ]),
              // Under IgnorePointer but not covered: still visible.
              IgnorePointer(child: Text(t(visible2))),
              const SizedBox(height: 2000),
              Text(t(hidden[2])),
            ]),
          ),
        );
      }));
      expect(recorder.keysByValue.values.expand((k) => k).toSet(),
          containsAll([visible, visible2, hint, ...hidden]));
      final hits = _hits(tester, recorder);
      expect(hits.map((h) => h.key).toSet(), {visible, visible2, hint});
    });
  }
}
