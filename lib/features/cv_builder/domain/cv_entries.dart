/// Structured experience, education and certification entries for the CV
/// wizard (Salem review, issue 3).
///
/// The API still takes `experience_input` / `education_input` /
/// `certifications_input` as text, and the server turns that text into CV
/// entries with `App\Cv\LegacySectionParser`. So entries are written in the
/// exact shape that parser reads, one block per entry:
///
///     Role | Company | City | 03/2021 - Present
///     - What you did and achieved
///
/// and read back with the same rules, so text from older drafts or from AI
/// enhancement still maps onto entries.
library;

/// A month (optional) and year, as picked in the wizard.
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, [this.month]);

  final int year;

  /// 1–12, or null when only the year is known.
  final int? month;

  /// `MM/YYYY`, or `YYYY` without a month: both are date points for the
  /// server parser.
  String format() =>
      month == null ? '$year' : '${month!.toString().padLeft(2, '0')}/$year';

  @override
  int compareTo(YearMonth other) => year != other.year
      ? year.compareTo(other.year)
      : (month ?? 0).compareTo(other.month ?? 0);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => format();
}

/// One job in the experience step.
class ExperienceEntry {
  const ExperienceEntry({
    this.title = '',
    this.company = '',
    this.location = '',
    this.start,
    this.end,
    this.current = false,
    this.description = '',
  });

  final String title;
  final String company;
  final String location;
  final YearMonth? start;

  /// Ignored while [current].
  final YearMonth? end;
  final bool current;

  /// One achievement or duty per line.
  final String description;

  bool get isBlank =>
      title.trim().isEmpty &&
      company.trim().isEmpty &&
      location.trim().isEmpty &&
      start == null &&
      end == null &&
      !current &&
      description.trim().isEmpty;

  ExperienceEntry copyWith({
    String? title,
    String? company,
    String? location,
    YearMonth? start,
    YearMonth? end,
    bool? current,
    String? description,
    bool clearEnd = false,
  }) =>
      ExperienceEntry(
        title: title ?? this.title,
        company: company ?? this.company,
        location: location ?? this.location,
        start: start ?? this.start,
        end: clearEnd ? null : (end ?? this.end),
        current: current ?? this.current,
        description: description ?? this.description,
      );
}

/// One qualification in the education step.
class EducationEntry {
  const EducationEntry({
    this.degree = '',
    this.institution = '',
    this.start,
    this.end,
    this.current = false,
    this.details = '',
  });

  final String degree;
  final String institution;
  final YearMonth? start;
  final YearMonth? end;
  final bool current;
  final String details;

  bool get isBlank =>
      degree.trim().isEmpty &&
      institution.trim().isEmpty &&
      start == null &&
      end == null &&
      !current &&
      details.trim().isEmpty;

  EducationEntry copyWith({
    String? degree,
    String? institution,
    YearMonth? start,
    YearMonth? end,
    bool? current,
    String? details,
    bool clearEnd = false,
  }) =>
      EducationEntry(
        degree: degree ?? this.degree,
        institution: institution ?? this.institution,
        start: start ?? this.start,
        end: clearEnd ? null : (end ?? this.end),
        current: current ?? this.current,
        details: details ?? this.details,
      );
}

/// One certificate or course.
class CertificationEntry {
  const CertificationEntry({this.name = '', this.issuer = '', this.date});

  final String name;
  final String issuer;
  final YearMonth? date;

  bool get isBlank =>
      name.trim().isEmpty && issuer.trim().isEmpty && date == null;

  CertificationEntry copyWith({
    String? name,
    String? issuer,
    YearMonth? date,
  }) =>
      CertificationEntry(
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        date: date ?? this.date,
      );
}

/// What is wrong with one entry, field by field; empty when it is complete.
enum EntryProblem {
  missingTitle,
  missingOrganisation,
  missingStart,
  missingEnd,
  endBeforeStart,
  missingDescription,
}

/// "Present" in the CV language; the server parser reads both.
String presentWord(String language) => language == 'en' ? 'Present' : 'حتى الآن';

// ── Writing ────────────────────────────────────────────────────────────────

String serializeExperience(List<ExperienceEntry> entries, String language) =>
    entries.where((e) => !e.isBlank).map((e) {
      final header = _header(
        [e.title, e.company, e.location],
        e.start,
        e.current ? null : e.end,
        current: e.current,
        language: language,
      );
      return [header, ..._bullets(e.description)].join('\n');
    }).join('\n\n');

String serializeEducation(List<EducationEntry> entries, String language) =>
    entries.where((e) => !e.isBlank).map((e) {
      final header = _header(
        [e.degree, e.institution],
        e.start,
        e.current ? null : e.end,
        current: e.current,
        language: language,
      );
      return [header, ..._bullets(e.details)].join('\n');
    }).join('\n\n');

/// One "- Name | Issuer | MM/YYYY" line per certificate.
String serializeCertifications(List<CertificationEntry> entries) => entries
    .where((e) => !e.isBlank)
    .map((e) => '- ${[
          _clean(e.name),
          _clean(e.issuer),
          if (e.date != null) e.date!.format(),
        ].where((part) => part.isNotEmpty).join(' | ')}')
    .join('\n');

String _header(
  List<String> parts,
  YearMonth? start,
  YearMonth? end, {
  required bool current,
  required String language,
}) {
  final range = start == null
      ? ''
      : '${start.format()} - ${current ? presentWord(language) : (end ?? start).format()}';
  return [...parts.map(_clean), range]
      .where((part) => part.isNotEmpty)
      .join(' | ');
}

List<String> _bullets(String text) => text
    .split('\n')
    .map((line) => line.trim().replaceFirst(_bulletMarker, '').trim())
    .where((line) => line.isNotEmpty)
    .map((line) => '- $line')
    .toList();

/// Field text on one header line: no separators or line breaks inside.
String _clean(String value) => value
    .replaceAll(RegExp(r'\s*\|\s*'), ' / ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

// ── Reading (mirrors LegacySectionParser) ──────────────────────────────────

final _bulletMarker = RegExp(r'^[-*•–—]\s+');
const _monthNames = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  'يناير': 1, 'فبراير': 2, 'مارس': 3, 'أبريل': 4, 'ابريل': 4, 'مايو': 5,
  'يونيو': 6, 'يوليو': 7, 'أغسطس': 8, 'اغسطس': 8, 'سبتمبر': 9,
  'أكتوبر': 10, 'اكتوبر': 10, 'نوفمبر': 11, 'ديسمبر': 12,
};
const _datePoint = r'(?:\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\.?\s+|(?<!\p{L})(?:يناير|فبراير|مارس|أبريل|ابريل|مايو|يونيو|يوليو|أغسطس|اغسطس|سبتمبر|أكتوبر|اكتوبر|نوفمبر|ديسمبر)\s+|(?:0?[1-9]|1[0-2])\/)?(?:19|20)\d{2}';
const _currentWord = r'(?:Present|Current|Now|حتى الآن|حالياً?)';
final _range = RegExp(
  '($_datePoint)\\s*(?:[-–—]|to|إلى)\\s*($_datePoint|$_currentWord)',
  caseSensitive: false,
  unicode: true,
);
final _currentOnly = RegExp('^$_currentWord\$', caseSensitive: false, unicode: true);
final _pointOnly = RegExp('^$_datePoint\$', caseSensitive: false, unicode: true);

/// Parses one date point ("03/2021", "Mar 2021", "مارس 2021", "2021").
YearMonth? parseYearMonth(String raw) {
  final text = raw.trim();
  final year = RegExp(r'(?:19|20)\d{2}').firstMatch(text);
  if (year == null) return null;
  final y = int.parse(year.group(0)!);
  final numeric = RegExp(r'^(0?[1-9]|1[0-2])\/').firstMatch(text);
  if (numeric != null) return YearMonth(y, int.parse(numeric.group(1)!));
  final word = text.substring(0, year.start).trim().toLowerCase();
  for (final MapEntry(key: name, value: month) in _monthNames.entries) {
    if (word.isNotEmpty && word.startsWith(name)) return YearMonth(y, month);
  }
  return YearMonth(y);
}

typedef _Header = ({
  String title,
  String subtitle,
  String location,
  YearMonth? start,
  YearMonth? end,
  bool current,
});

_Header _splitHeader(String line) {
  var rest = line.trim();
  YearMonth? start;
  YearMonth? end;
  var current = false;
  final range = _range.firstMatch(rest);
  if (range != null) {
    start = parseYearMonth(range.group(1)!);
    current = _currentOnly.hasMatch(range.group(2)!.trim());
    end = current ? null : parseYearMonth(range.group(2)!);
    rest = rest.replaceFirst(range.group(0)!, '').trim();
  }
  rest = rest
      .replaceAll(RegExp(r'^[\s\-–—|,;،]+|[\s\-–—|,;،]+$', unicode: true), '');

  var title = rest, subtitle = '', location = '';
  for (final separator in const [' | ', ' — ', ' – ', '، ', ', ', ' لدى ']) {
    if (!rest.contains(separator)) continue;
    final parts = rest
        .split(separator)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    title = parts.isNotEmpty ? parts[0] : '';
    subtitle = parts.length > 1 ? parts[1] : '';
    location = parts.length > 2 ? parts.sublist(2).join(separator) : '';
    break;
  }
  return (
    title: title,
    subtitle: subtitle,
    location: location,
    start: start,
    end: end,
    current: current,
  );
}

bool _looksLikeHeader(String chunk) {
  final first = chunk.trim().split('\n').first;
  return _range.hasMatch(first) || RegExp(r'^#{1,4}\s+\S').hasMatch(first);
}

/// Blocks separated by blank lines; a block that does not start with a dated
/// (or `#`) header belongs to the one before it.
List<String> _blocks(String text) {
  final chunks = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split(RegExp(r'\n{2,}'))
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty);
  final blocks = <String>[];
  for (final chunk in chunks) {
    if (blocks.isNotEmpty && !_looksLikeHeader(chunk)) {
      blocks[blocks.length - 1] = '${blocks.last}\n\n$chunk';
    } else {
      blocks.add(chunk);
    }
  }
  return blocks;
}

({String header, List<String> body}) _splitBody(String block) {
  final lines = block
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return (header: '', body: const []);
  return (
    header: lines.first.replaceFirst(RegExp(r'^#+\s*'), ''),
    body: [
      for (final line in lines.skip(1)) line.replaceFirst(_bulletMarker, ''),
    ],
  );
}

List<ExperienceEntry> parseExperience(String text) => [
      for (final block in _blocks(text))
        () {
          final (:header, :body) = _splitBody(block);
          final h = _splitHeader(header);
          // A free-text block with no recognisable header keeps all its
          // text in the description, so nothing typed is lost.
          final structured = h.start != null || h.subtitle.isNotEmpty;
          return structured
              ? ExperienceEntry(
                  title: h.title,
                  company: h.subtitle,
                  location: h.location,
                  start: h.start,
                  end: h.end,
                  current: h.current,
                  description: body.join('\n'),
                )
              : ExperienceEntry(description: [header, ...body].join('\n'));
        }(),
    ];

List<EducationEntry> parseEducation(String text) => [
      for (final block in _blocks(text))
        () {
          final (:header, :body) = _splitBody(block);
          final h = _splitHeader(header);
          final structured = h.start != null || h.subtitle.isNotEmpty;
          return structured
              ? EducationEntry(
                  degree: h.title,
                  institution: h.subtitle,
                  start: h.start,
                  end: h.end,
                  current: h.current,
                  details: [
                    if (h.location.isNotEmpty) h.location,
                    ...body,
                  ].join('\n'),
                )
              : EducationEntry(details: [header, ...body].join('\n'));
        }(),
    ];

List<CertificationEntry> parseCertifications(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim().replaceFirst(_bulletMarker, '').trim())
      .where((l) => l.isNotEmpty);
  return [
    for (final line in lines)
      () {
        final h = _splitHeader(line);
        var issuer = h.subtitle;
        var date = h.end ?? h.start;
        if (date == null && _pointOnly.hasMatch(h.location)) {
          date = parseYearMonth(h.location);
        } else if (date == null &&
            h.location.isEmpty &&
            _pointOnly.hasMatch(h.subtitle)) {
          date = parseYearMonth(h.subtitle);
          issuer = '';
        }
        return CertificationEntry(name: h.title, issuer: issuer, date: date);
      }(),
  ];
}

// ── Checks ─────────────────────────────────────────────────────────────────

Set<EntryProblem> experienceProblems(ExperienceEntry e) => {
      if (e.title.trim().isEmpty) EntryProblem.missingTitle,
      if (e.company.trim().isEmpty) EntryProblem.missingOrganisation,
      if (e.start == null) EntryProblem.missingStart,
      if (!e.current && e.end == null) EntryProblem.missingEnd,
      if (!e.current &&
          e.start != null &&
          e.end != null &&
          e.end!.compareTo(e.start!) < 0)
        EntryProblem.endBeforeStart,
      if (e.description.trim().isEmpty) EntryProblem.missingDescription,
    };

Set<EntryProblem> educationProblems(EducationEntry e) => {
      if (e.degree.trim().isEmpty) EntryProblem.missingTitle,
      if (e.institution.trim().isEmpty) EntryProblem.missingOrganisation,
      if (e.start == null) EntryProblem.missingStart,
      if (!e.current && e.end == null) EntryProblem.missingEnd,
      if (!e.current &&
          e.start != null &&
          e.end != null &&
          e.end!.compareTo(e.start!) < 0)
        EntryProblem.endBeforeStart,
    };

Set<EntryProblem> certificationProblems(CertificationEntry e) =>
    e.isBlank || e.name.trim().isNotEmpty
        ? const {}
        : const {EntryProblem.missingTitle};
