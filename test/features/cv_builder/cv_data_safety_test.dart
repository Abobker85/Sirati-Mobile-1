import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/controllers/cv_manage_controller.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_schema_migrator.dart';
import 'package:sirati/shared/models/cv_document.dart';

/// Keys the v0 → v1 migration reads, renames or replaces.
const _v0Keys = [
  'full_name',
  'candidate_name',
  'headline',
  'target_job_title',
  'job_title',
  'summary_input',
  'summary',
  'email',
  'phone',
  'linkedin',
  'location',
  'experience',
  'experience_input',
  'education',
  'education_input',
  'skills',
  'skills_input',
  'certifications',
  'certifications_input',
  'languages',
  'projects',
  'custom_sections',
  'export_language',
  'personal_notes',
  CvSchemaMigrator.legacyKey,
];

class _Gen {
  _Gen(int seed) : _r = Random(seed);
  final Random _r;

  String text() => String.fromCharCodes(List.generate(
      _r.nextInt(12),
      (_) => switch (_r.nextInt(3)) {
            0 => 0x20 + _r.nextInt(0x5E),
            1 => 0x0621 + _r.nextInt(0x3A),
            _ => [0x2C, 0x060C, 0x0A][_r.nextInt(3)],
          }));

  Object? value(int depth) => switch (_r.nextInt(depth > 1 ? 5 : 7)) {
        0 => null,
        1 => _r.nextInt(1000) - 500,
        2 => _r.nextBool(),
        3 || 4 => text(),
        5 => [for (var i = 0; i < _r.nextInt(4); i++) value(depth + 1)],
        _ => {
            for (var i = 0; i < _r.nextInt(4); i++)
              [text(), 'name', 'level', 'ar', 'en'][_r.nextInt(5)]:
                  value(depth + 1),
          },
      };

  Map<String, dynamic> v0() => {
        'id': 'cv_${_r.nextInt(1 << 30)}',
        for (final key in _v0Keys)
          if (_r.nextInt(3) > 0) key: value(0),
      };
}

/// Every value of [source] that is not where it was must be in the archive.
void _expectLossless(Map<String, dynamic> source, Map<String, dynamic> out) {
  final archive = out[CvSchemaMigrator.legacyKey];
  for (final entry in source.entries) {
    final inPlace = jsonEncode(out[entry.key]) == jsonEncode(entry.value) &&
        out.containsKey(entry.key);
    final archived = archive is Map &&
        archive.containsKey(entry.key) &&
        jsonEncode(archive[entry.key]) == jsonEncode(entry.value);
    expect(inPlace || archived, isTrue,
        reason: '${entry.key}=${jsonEncode(entry.value)} was lost: '
            '${jsonEncode(out)}');
  }
}

/// A raw document as builds before the default-title fix saved it.
Map<String, dynamic> _legacyStored(String? title) =>
    CvDocument.createEmpty(id: 'k', title: title).toJson()
      ..remove(CvDocument.noDefaultTitleKey);

class _BrokenEngine extends MemoryCvStorageEngine {
  _BrokenEngine(this.raw);
  final Map<String, String> raw;

  @override
  Future<List<String>> listIds() async => raw.keys.toList();
  @override
  Future<String?> read(String id) async => raw[id];
  @override
  Future<void> writeAtomic(String id, String content) async =>
      raw[id] = content;
  @override
  Future<void> delete(String id) async => raw.remove(id);
  @override
  Future<bool> exists(String id) async => raw.containsKey(id);
}

void main() {
  group('v0 migration keeps every source value', () {
    test('over arbitrary v0 payloads', () {
      final gen = _Gen(19);
      for (var i = 0; i < 400; i++) {
        final v0 = gen.v0();
        final input = jsonDecode(jsonEncode(v0)) as Map<String, dynamic>;
        final out = CvSchemaMigrator.migrate(input).data;
        expect(jsonEncode(input), jsonEncode(v0), reason: 'input untouched');
        _expectLossless(v0, out);
        // The archive survives loading and saving the document.
        final saved = CvDocument.fromJson(out).toJson();
        expect(jsonEncode(saved[CvSchemaMigrator.legacyKey]),
            jsonEncode(out[CvSchemaMigrator.legacyKey]));
        // Migrating the result again changes nothing.
        expect(jsonEncode(CvSchemaMigrator.migrate(out).data), jsonEncode(out));
      }
    });

    test('alternative names that lose to the first one are archived', () {
      final gen = _Gen(7);
      for (var i = 0; i < 100; i++) {
        final names = {
          for (final k in ['full_name', 'candidate_name']) k: gen.text()
        };
        final titles = {
          for (final k in ['headline', 'target_job_title', 'job_title'])
            k: gen.text()
        };
        final v0 = {
          ...names,
          ...titles,
          'summary_input': gen.text(),
          'summary': gen.text(),
          'languages': 'Arabic, English ${gen.text()}',
          'projects': {'name': gen.text()},
          'skills': [
            'plain ${gen.text()}',
            {'name': gen.text()},
            3
          ],
        };
        final out = CvSchemaMigrator.migrate(v0).data;
        expect(out['personal']['full_name']['ar'], names['full_name']);
        expect(out['personal']['headline']['ar'], titles['headline']);
        expect(out['summary']['ar'], v0['summary_input']);
        _expectLossless(v0, out);
        // Only maps reach typed sections; the rest stays in the archive.
        for (final section in ['skills', 'languages', 'projects']) {
          expect((out[section] as List).every((e) => e is Map), isTrue);
        }
      }
    });
  });

  group('legacy default titles', () {
    // Rule: builds before the fix wrote the default title into every new
    // draft and offered no way to type a title, so an exact default title
    // in a document without the no-default-title marker can only be that
    // default. Documents saved by this build carry the marker and keep
    // every title, defaults included.
    test('a document saved by this build keeps any title', () async {
      final gen = _Gen(3);
      final titles = [
        ...CvSchemaMigrator.legacyPlaceholderTitles,
        for (var i = 0; i < 200; i++) gen.text(),
      ];
      final raw = <String, String>{};
      final repo = LocalCvRepository(engine: _BrokenEngine(raw));
      for (final t in titles) {
        await repo.saveCv(CvDocument.createEmpty(id: 'k', title: t));
        final stored = jsonDecode(raw['k']!) as Map<String, dynamic>;
        expect(stored[CvDocument.noDefaultTitleKey], isTrue);
        expect(CvSchemaMigrator.migrate(stored).data['title'], t);
        expect((await repo.getCv('k'))!.title, t);
      }
    });

    test('a legacy document loses only an exact default title, once', () async {
      final gen = _Gen(4);
      final others = [
        for (var i = 0; i < 200; i++) gen.text(),
        for (final t in CvSchemaMigrator.legacyPlaceholderTitles) ...[
          ' $t',
          '$t ',
          '${t}x',
        ],
      ].where((t) => !CvSchemaMigrator.legacyPlaceholderTitles.contains(t));
      for (final t in others) {
        expect(CvSchemaMigrator.migrate(_legacyStored(t)).data['title'], t);
      }
      for (final t in CvSchemaMigrator.legacyPlaceholderTitles) {
        final once = CvSchemaMigrator.migrate(_legacyStored(t));
        expect(once.data.containsKey('title'), isFalse);
        expect(once.wasMigrated, isTrue);
        expect(CvSchemaMigrator.migrate(once.data).data, once.data);
        // Saved again, the document is marked and a title typed later
        // that equals the old default is kept.
        final raw = {'k': jsonEncode(_legacyStored(t))};
        final repo = LocalCvRepository(engine: _BrokenEngine(raw));
        final opened = (await repo.getCv('k'))!;
        expect(opened.title, isNull);
        await repo.saveCv(opened.copyWith(title: t));
        expect((await repo.getCv('k'))!.title, t);
      }
    });
  });

  group('unreadable CVs are never lost silently', () {
    final unreadable = <String, String>{
      'newer': jsonEncode({'schema_version': 99, 'title': 'from the future'}),
      'not-json': '{"title": "half writ',
      'list': '[1,2,3]',
      'string': '"just text"',
    };

    test('listing shows them as unreadable instead of hiding them', () async {
      final raw = Map.of(unreadable);
      final repo = LocalCvRepository(engine: _BrokenEngine(raw));
      await repo.saveCv(CvDocument.createEmpty(id: 'ok', title: 'Mine'));
      final list = await repo.listCvs();
      expect(list.map((m) => m.id), containsAll([...unreadable.keys, 'ok']));
      for (final m in list) {
        expect(m.unreadable, unreadable.containsKey(m.id));
      }
    });

    test('opening one fails loudly instead of returning an empty draft',
        () async {
      final repo = LocalCvRepository(engine: _BrokenEngine(Map.of(unreadable)));
      for (final id in unreadable.keys) {
        await expectLater(
            repo.getCv(id), throwsA(isA<UnreadableCvException>()));
      }
      expect(await repo.getCv('missing'), isNull);
    });

    test('delete refuses until the user confirms, then deletes', () async {
      final raw = Map.of(unreadable);
      final repo = LocalCvRepository(engine: _BrokenEngine(raw));
      for (final id in unreadable.keys) {
        await expectLater(
            repo.deleteCv(id), throwsA(isA<UnreadableCvException>()));
        expect(raw[id], unreadable[id], reason: 'bytes kept');
      }
      final controller = CvManageController(repository: repo);
      for (final id in unreadable.keys) {
        await expectLater(
            controller.deleteCv(id), throwsA(isA<UnreadableCvException>()));
        expect(raw[id], unreadable[id]);
        await controller.deleteCv(id, confirmUnreadable: true);
        expect(raw.containsKey(id), isFalse);
      }
      controller.dispose();
    });
  });
}
