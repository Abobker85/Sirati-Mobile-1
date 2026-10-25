import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';

/// Texts the server parser is tested against (tests/Feature/
/// WizardEntriesContractTest.php). If the writer changes, both sides must.
const contractExperience = 'E-Commerce Specialist | Al-Dawaa | Al Khobar | 11/2025 - Present\n'
    '- Ran Google Ads campaigns across product categories\n'
    '- Raised ROAS by 30%\n'
    '\n'
    'مسؤول مبيعات | شركة النخبة | 03/2021 - 10/2025\n'
    '- إدارة حسابات كبار العملاء';
const contractEducation = 'بكالوريوس إدارة أعمال | جامعة الملك فيصل | 09/2015 - 06/2019\n'
    '- مرتبة الشرف الثانية';
const contractCertifications = '- Google Ads Search | Google | 05/2024\n'
    '- إدارة المشاريع الاحترافية | PMI';

void main() {
  group('writer contract', () {
    test('experience, education and certificates in the server shape', () {
      expect(
        serializeExperience(const [
          ExperienceEntry(
            title: 'E-Commerce Specialist',
            company: 'Al-Dawaa',
            location: 'Al Khobar',
            start: YearMonth(2025, 11),
            current: true,
            description:
                'Ran Google Ads campaigns across product categories\n• Raised ROAS by 30%',
          ),
          ExperienceEntry(),
          ExperienceEntry(
            title: 'مسؤول مبيعات',
            company: 'شركة النخبة',
            start: YearMonth(2021, 3),
            end: YearMonth(2025, 10),
            description: '- إدارة حسابات كبار العملاء\n\n',
          ),
        ], 'en'),
        contractExperience,
      );
      expect(
        serializeEducation(const [
          EducationEntry(
            degree: 'بكالوريوس إدارة أعمال',
            institution: 'جامعة الملك فيصل',
            start: YearMonth(2015, 9),
            end: YearMonth(2019, 6),
            details: 'مرتبة الشرف الثانية',
          ),
        ], 'ar'),
        contractEducation,
      );
      expect(
        serializeCertifications(const [
          CertificationEntry(
            name: 'Google Ads Search',
            issuer: 'Google',
            date: YearMonth(2024, 5),
          ),
          CertificationEntry(),
          CertificationEntry(name: 'إدارة المشاريع الاحترافية', issuer: 'PMI'),
        ]),
        contractCertifications,
      );
    });

    test('"Present" follows the CV language', () {
      for (final language in ['ar', 'en']) {
        final text = serializeExperience(const [
          ExperienceEntry(
            title: 'T',
            company: 'C',
            start: YearMonth(2020, 1),
            end: YearMonth(2021, 1),
            current: true,
            description: 'd',
          ),
        ], language);
        expect(text, contains('01/2020 - ${presentWord(language)}'));
        expect(text, isNot(contains('2021')),
            reason: 'a current job has no end date');
      }
    });
  });

  group('round trip', () {
    // Arbitrary entries — Arabic, Latin, mixed, separators inside fields,
    // month-less years, current jobs — survive write then read.
    final random = Random(20261025);
    const words = [
      'مهندس', 'Engineer', 'شركة', 'Acme', 'الرياض', 'Data', 'تحليل',
      'C++', 'R&D', 'ذ.م.م', 'Ltd.', '2nd', 'أول',
    ];
    String phrase([int max = 3]) => List.generate(
        1 + random.nextInt(max), (_) => words[random.nextInt(words.length)]).join(' ');
    YearMonth point() => YearMonth(
        1990 + random.nextInt(36), random.nextBool() ? 1 + random.nextInt(12) : null);

    for (var run = 0; run < 200; run++) {
      test('experience #$run', () {
        final entries = List.generate(1 + random.nextInt(4), (_) {
          final start = point();
          final current = random.nextInt(3) == 0;
          final title = random.nextInt(8) == 0 ? '${phrase()} | x' : phrase();
          return ExperienceEntry(
            title: title,
            company: phrase(),
            location: random.nextBool() ? phrase(2) : '',
            start: start,
            end: current ? null : YearMonth(start.year + random.nextInt(5), start.month),
            current: current,
            description: List.generate(1 + random.nextInt(3), (_) => phrase(6)).join('\n'),
          );
        });
        final language = random.nextBool() ? 'ar' : 'en';
        final text = serializeExperience(entries, language);
        final back = parseExperience(text);
        expect(back, hasLength(entries.length), reason: text);
        for (final (i, e) in entries.indexed) {
          expect(back[i].title, e.title.replaceAll(RegExp(r'\s*\|\s*'), ' / '),
              reason: text);
          expect(back[i].company, e.company, reason: text);
          expect(back[i].location, e.location, reason: text);
          expect(back[i].start, e.start, reason: text);
          expect(back[i].current, e.current, reason: text);
          expect(back[i].end, e.current ? null : e.end, reason: text);
          expect(back[i].description, e.description, reason: text);
        }
        expect(serializeExperience(back, language), text,
            reason: 'writing what was read changes nothing');
      });
    }

    for (var run = 0; run < 100; run++) {
      test('education and certificates #$run', () {
        final education = List.generate(1 + random.nextInt(3), (_) {
          final start = point();
          return EducationEntry(
            degree: phrase(),
            institution: phrase(),
            start: start,
            end: YearMonth(start.year + 1 + random.nextInt(5), start.month),
            details: random.nextBool() ? phrase(5) : '',
          );
        });
        final text = serializeEducation(education, 'ar');
        final back = parseEducation(text);
        expect(back, hasLength(education.length), reason: text);
        for (final (i, e) in education.indexed) {
          expect((back[i].degree, back[i].institution, back[i].start, back[i].end, back[i].details),
              (e.degree, e.institution, e.start, e.end, e.details),
              reason: text);
        }

        final certificates = List.generate(
          1 + random.nextInt(3),
          (_) => CertificationEntry(
            name: phrase(),
            issuer: random.nextBool() ? phrase(2) : '',
            date: random.nextBool() ? point() : null,
          ),
        );
        final certText = serializeCertifications(certificates);
        final certBack = parseCertifications(certText);
        expect(certBack, hasLength(certificates.length), reason: certText);
        for (final (i, e) in certificates.indexed) {
          expect((certBack[i].name, certBack[i].issuer, certBack[i].date),
              (e.name, e.issuer, e.date),
              reason: certText);
        }
      });
    }
  });

  group('reading other text', () {
    test('AI-style and hand-written headers still become entries', () {
      for (final (text, title, company, start, current) in [
        ('Engineer — Acme — 2020 - 2022\n- Built APIs.', 'Engineer', 'Acme', const YearMonth(2020), false),
        ('محاسب، شركة الأفق، مارس 2019 - حتى الآن\nإعداد القوائم', 'محاسب', 'شركة الأفق', const YearMonth(2019, 3), true),
        ('## Analyst | Beta | Jan 2018 to Dec 2019', 'Analyst', 'Beta', const YearMonth(2018, 1), false),
      ]) {
        final [entry] = parseExperience(text);
        expect((entry.title, entry.company, entry.start, entry.current),
            (title, company, start, current),
            reason: text);
      }
    });

    test('free text without a header is kept whole, never dropped', () {
      const old = 'I worked at a company doing marketing.\nAlso some sales.';
      final [entry] = parseExperience(old);
      expect(entry.title, isEmpty);
      expect(entry.description, old);
      expect(experienceProblems(entry), contains(EntryProblem.missingTitle));
    });

    test('an appended achievement joins the last job', () {
      const text = '$contractExperience\nAchieved 20% growth by doing X';
      final entries = parseExperience(text);
      expect(entries, hasLength(2));
      expect(entries.last.description.split('\n').last,
          'Achieved 20% growth by doing X');
    });

    test('blank and whitespace text has no entries', () {
      for (final text in ['', '  ', '\n\n']) {
        expect(parseExperience(text), isEmpty);
        expect(parseEducation(text), isEmpty);
        expect(parseCertifications(text), isEmpty);
      }
    });
  });

  test('problems: each missing piece is named, complete entries pass', () {
    const complete = ExperienceEntry(
      title: 't',
      company: 'c',
      start: YearMonth(2020, 1),
      end: YearMonth(2020, 1),
      description: 'd',
    );
    expect(experienceProblems(complete), isEmpty);
    expect(experienceProblems(complete.copyWith(current: true, clearEnd: true)),
        isEmpty);
    expect(experienceProblems(complete.copyWith(title: ' ')),
        {EntryProblem.missingTitle});
    expect(experienceProblems(complete.copyWith(company: '')),
        {EntryProblem.missingOrganisation});
    expect(experienceProblems(complete.copyWith(clearEnd: true)),
        {EntryProblem.missingEnd});
    expect(experienceProblems(complete.copyWith(end: const YearMonth(2019, 12))),
        {EntryProblem.endBeforeStart});
    expect(experienceProblems(complete.copyWith(description: '\n')),
        {EntryProblem.missingDescription});
    expect(experienceProblems(const ExperienceEntry(title: 't', company: 'c', description: 'd')),
        contains(EntryProblem.missingStart));
    expect(certificationProblems(const CertificationEntry()), isEmpty,
        reason: 'certificates are optional');
    expect(certificationProblems(const CertificationEntry(issuer: 'x')),
        {EntryProblem.missingTitle});
  });
}
