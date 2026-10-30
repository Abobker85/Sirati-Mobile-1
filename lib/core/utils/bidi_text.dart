/// Bidirectional text helpers for mixed Arabic / Latin content.
///
/// Use these when embedding Latin usernames, product codes (ATS, Java, SQL),
/// emails, or file names inside Arabic UI strings so the visual order stays
/// stable under RTL [Directionality].
class BidiText {
  BidiText._();

  static const lre = '\u202A'; // Left-to-Right Embedding
  static const rle = '\u202B'; // Right-to-Left Embedding
  static const pdf = '\u202C'; // Pop Directional Formatting
  static const lrm = '\u200E'; // Left-to-Right Mark
  static const rlm = '\u200F'; // Right-to-Left Mark

  /// True when the whole string is Latin / digits / common username chars.
  static bool looksLatin(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[A-Za-z0-9@._+\-\s]+$').hasMatch(trimmed);
  }

  /// True when the string contains any Arabic letter.
  static bool hasArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Wrap a Latin/LTR run so it does not reverse inside RTL paragraphs.
  static String isolateLtr(String text) {
    if (text.isEmpty) return text;
    return '$lrm$lre$text$pdf';
  }

  /// First character suitable for avatar badges; [fallback] (a catalog
  /// label) when [name] is empty.
  static String avatarInitial(String name, {required String fallback}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.substring(0, 1).toUpperCase();
  }

  /// Isolate Latin tokens (ATS, Java, Spring Boot, SQL, …) inside mixed copy.
  ///
  /// Safe for job descriptions and marketing blurbs that mix AR + tech terms.
  static String protectLatinTokens(String text) {
    if (text.isEmpty || !hasArabic(text)) return text;
    return text.replaceAllMapped(
      RegExp(r'[A-Za-z][A-Za-z0-9+.#/\-]{0,}'),
      (match) => isolateLtr(match.group(0)!),
    );
  }

  /// Format a product term like ATS for use inside Arabic UI copy.
  static String productTerm(String term, {required bool english}) {
    if (english) return term;
    return isolateLtr(term);
  }
}
