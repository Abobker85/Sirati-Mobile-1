/// Whether the server will hand this CV's PDF to an employer
/// (`CvExportGuard::exportState`), and why not when it won't.
class CvExportState {
  const CvExportState({
    required this.ready,
    this.blockedReason,
    this.messageAr,
    this.messageEn,
  });

  static const generating = 'generating';
  static const missingContact = 'missing_contact';
  static const unstructuredExperience = 'unstructured_experience';

  /// Null when the payload has no `export` block (older servers).
  static CvExportState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final ready = raw['ready'];
    if (ready is! bool) return null;
    return CvExportState(
      ready: ready,
      blockedReason: _text(raw['blocked_reason']),
      messageAr: _text(raw['message_ar']),
      messageEn: _text(raw['message_en']),
    );
  }

  final bool ready;
  final String? blockedReason;
  final String? messageAr;
  final String? messageEn;

  /// The server's explanation in the UI language, falling back to the other.
  String? message({required bool english}) =>
      english ? (messageEn ?? messageAr) : (messageAr ?? messageEn);
}

String? _text(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
