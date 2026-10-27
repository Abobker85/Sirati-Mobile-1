import 'package:intl/intl.dart' as intl;

/// Thrown for any message that cannot be parsed or formatted. Callers catch
/// it and fall back to the next string source (never shown to users).
class IcuFormatException implements Exception {
  const IcuFormatException(this.message, [this.offset]);

  final String message;
  final int? offset;

  @override
  String toString() => offset == null
      ? 'IcuFormatException: $message'
      : 'IcuFormatException: $message (at $offset)';
}

/// An argument whose display text differs from the raw value used for
/// plural/select choice (e.g. an int shown with a compact number format).
class IcuArgument {
  const IcuArgument(this.value, this.text);

  final Object? value;
  final String text;
}

/// Small ICU MessageFormat subset matching what Flutter gen-l10n supports:
/// `{name}`, `{n, plural, =N{..} zero{..} one{..} two{..} few{..} many{..}
/// other{..}}` and `{x, select, a{..} other{..}}`, nested to any depth.
///
/// Like gen-l10n without `use-escaping` (this app's l10n.yaml), apostrophes
/// are plain characters: `'{'` is not an escaped brace. `#` is literal too.
/// Plural selectors are `=0`, `=1`, `=2` and the CLDR keywords; plural and
/// select must have an `other` branch.
abstract final class IcuLite {
  /// Deepest nesting accepted; adversarial input fails instead of
  /// overflowing the stack.
  static const maxDepth = 16;

  /// Formats [message] for [locale]. [args] values are used for plural and
  /// select choice; their text is `toString()` unless an [IcuArgument]
  /// supplies one. Throws [IcuFormatException] on any problem.
  static String format(
    String message, {
    required String locale,
    Map<String, Object?> args = const {},
  }) {
    final nodes = parse(message);
    final out = StringBuffer();
    _render(nodes, locale, args, out);
    return out.toString();
  }

  /// Argument names referenced anywhere in [message], in first-use order.
  static List<String> argumentNames(String message) {
    final names = <String>[];
    void visit(List<IcuNode> nodes) {
      for (final node in nodes) {
        switch (node) {
          case IcuText():
            break;
          case IcuArg(:final name):
            if (!names.contains(name)) names.add(name);
          case IcuChoice(:final name, :final branches):
            if (!names.contains(name)) names.add(name);
            branches.values.forEach(visit);
        }
      }
    }

    visit(parse(message));
    return names;
  }

  static List<IcuNode> parse(String message) {
    final parser = _Parser(message);
    final nodes = parser.parseMessage(depth: 0);
    if (!parser.atEnd) {
      throw IcuFormatException('Unexpected "}"', parser.pos);
    }
    return nodes;
  }

  static void _render(
    List<IcuNode> nodes,
    String locale,
    Map<String, Object?> args,
    StringBuffer out,
  ) {
    for (final node in nodes) {
      switch (node) {
        case IcuText(:final text):
          out.write(text);
        case IcuArg(:final name):
          out.write(_text(_arg(args, name)));
        case IcuChoice(:final name, :final isPlural, :final branches):
          final value = _arg(args, name);
          final raw = value is IcuArgument ? value.value : value;
          final branch = isPlural
              ? _pluralBranch(raw, branches, locale, name)
              : _selectBranch(raw, branches);
          _render(branch, locale, args, out);
      }
    }
  }

  static Object? _arg(Map<String, Object?> args, String name) {
    if (!args.containsKey(name)) {
      throw IcuFormatException('Missing argument "$name"');
    }
    return args[name];
  }

  static String _text(Object? value) =>
      value is IcuArgument ? value.text : '$value';

  static List<IcuNode> _pluralBranch(
    Object? raw,
    Map<String, List<IcuNode>> branches,
    String locale,
    String name,
  ) {
    if (raw is! num) {
      throw IcuFormatException('Plural argument "$name" is not a number');
    }
    for (final entry in branches.entries) {
      final key = entry.key;
      if (key.startsWith('=') && num.parse(key.substring(1)) == raw) {
        return entry.value;
      }
    }
    // gen-l10n maps =0/=1/=2 onto zero/one/two; keep the same semantics so a
    // remote copy of a bundled string selects the same branch.
    List<IcuNode>? pick(String keyword, String exact) =>
        branches[keyword] ?? branches[exact];
    try {
      return intl.Intl.pluralLogic<List<IcuNode>>(
        raw,
        locale: locale,
        zero: pick('zero', '=0'),
        one: pick('one', '=1'),
        two: pick('two', '=2'),
        few: branches['few'],
        many: branches['many'],
        other: branches['other']!,
      );
    } on IcuFormatException {
      rethrow;
    } catch (error) {
      throw IcuFormatException('Plural rules failed for "$locale": $error');
    }
  }

  static List<IcuNode> _selectBranch(
    Object? raw,
    Map<String, List<IcuNode>> branches,
  ) {
    final choice = '$raw';
    return branches[choice] ??
        branches[choice.split('.').last] ??
        branches['other']!;
  }
}

sealed class IcuNode {
  const IcuNode();
}

final class IcuText extends IcuNode {
  const IcuText(this.text);
  final String text;
}

final class IcuArg extends IcuNode {
  const IcuArg(this.name);
  final String name;
}

final class IcuChoice extends IcuNode {
  const IcuChoice(this.name, {required this.isPlural, required this.branches});
  final String name;
  final bool isPlural;
  final Map<String, List<IcuNode>> branches;
}

const _pluralKeywords = {'zero', 'one', 'two', 'few', 'many', 'other'};

class _Parser {
  _Parser(this.src);

  final String src;
  int pos = 0;

  bool get atEnd => pos >= src.length;

  String get _ch => src[pos];

  /// Parses text and arguments until an unmatched `}` or the end.
  List<IcuNode> parseMessage({required int depth}) {
    if (depth > IcuLite.maxDepth) {
      throw IcuFormatException('Message nested too deeply', pos);
    }
    final nodes = <IcuNode>[];
    final text = StringBuffer();
    void flush() {
      if (text.isNotEmpty) {
        nodes.add(IcuText(text.toString()));
        text.clear();
      }
    }

    while (!atEnd) {
      final c = _ch;
      if (c == '{') {
        flush();
        nodes.add(_parseArgument(depth));
      } else if (c == '}') {
        break;
      } else {
        text.write(c);
        pos++;
      }
    }
    flush();
    return nodes;
  }

  IcuNode _parseArgument(int depth) {
    final start = pos;
    pos++; // {
    _skipSpace();
    final name = _readIdentifier();
    if (name == null) {
      throw IcuFormatException('Expected an argument name', pos);
    }
    _skipSpace();
    if (atEnd) throw IcuFormatException('Unclosed "{"', start);
    if (_ch == '}') {
      pos++;
      return IcuArg(name);
    }
    if (_ch != ',') {
      throw IcuFormatException('Expected "," or "}" after "$name"', pos);
    }
    pos++;
    _skipSpace();
    final type = _readIdentifier();
    final isPlural = type == 'plural';
    if (!isPlural && type != 'select') {
      throw IcuFormatException('Unsupported argument type "$type"', pos);
    }
    _skipSpace();
    if (atEnd || _ch != ',') {
      throw IcuFormatException('Expected "," after "$type"', pos);
    }
    pos++;
    final branches = <String, List<IcuNode>>{};
    while (true) {
      _skipSpace();
      if (atEnd) throw IcuFormatException('Unclosed "{"', start);
      if (_ch == '}') {
        pos++;
        break;
      }
      final selector = _readSelector();
      if (selector.isEmpty) {
        throw IcuFormatException('Expected a branch selector', pos);
      }
      if (isPlural) _checkPluralSelector(selector);
      if (branches.containsKey(selector)) {
        throw IcuFormatException('Duplicate branch "$selector"', pos);
      }
      _skipSpace();
      if (atEnd || _ch != '{') {
        throw IcuFormatException('Expected "{" after "$selector"', pos);
      }
      final branchStart = pos;
      pos++;
      final body = parseMessage(depth: depth + 1);
      if (atEnd) throw IcuFormatException('Unclosed "{"', branchStart);
      pos++; // }
      branches[selector] = body;
    }
    if (!branches.containsKey('other')) {
      throw IcuFormatException('"$name" has no "other" branch', start);
    }
    return IcuChoice(name, isPlural: isPlural, branches: branches);
  }

  void _checkPluralSelector(String selector) {
    if (_pluralKeywords.contains(selector)) return;
    if (selector == '=0' || selector == '=1' || selector == '=2') return;
    throw IcuFormatException('Invalid plural selector "$selector"', pos);
  }

  void _skipSpace() {
    while (!atEnd && _isSpace(_ch)) {
      pos++;
    }
  }

  String? _readIdentifier() {
    final start = pos;
    while (!atEnd && _isIdentChar(_ch, first: pos == start)) {
      pos++;
    }
    return pos == start ? null : src.substring(start, pos);
  }

  String _readSelector() {
    final start = pos;
    while (!atEnd) {
      final c = _ch;
      if (_isSpace(c) || c == '{' || c == '}' || c == ',') break;
      pos++;
    }
    return src.substring(start, pos);
  }

  static bool _isSpace(String c) =>
      c == ' ' || c == '\t' || c == '\n' || c == '\r';

  static bool _isIdentChar(String c, {required bool first}) {
    final u = c.codeUnitAt(0);
    final letter = (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A);
    final digit = u >= 0x30 && u <= 0x39;
    return letter || c == '_' || (!first && digit);
  }
}
