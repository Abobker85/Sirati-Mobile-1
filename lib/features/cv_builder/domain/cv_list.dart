import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/shared/models/cv_export_state.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';

/// One row of the "My CVs" list.
class CvListItem {
  const CvListItem({
    required this.id,
    required this.title,
    required this.badge,
    required this.isDraft,
    required this.canDownload,
    required this.pdfUrl,
    required this.templatePdfUrl,
    required this.updatedAt,
    required this.updatedLabel,
    this.scoreTotal,
    this.export,
    this.language,
  });

  factory CvListItem.fromJson(Map<String, dynamic> json) {
    final id = _id(json['id']);
    return CvListItem(
      id: id,
      title: _text(json['title']),
      badge: _text(json['badge']),
      isDraft: _flag(json['is_draft'], fallback: false),
      // Server enforces entitlement on the PDF endpoint; this only hides UI.
      canDownload: _flag(json['can_download'], fallback: true),
      pdfUrl: _text(json['pdf_url']),
      templatePdfUrl: _text(json['template_pdf_url']),
      updatedAt: _date(json['updated_at']) ?? _date(json['created_at']),
      updatedLabel: _text(json['updated_label']),
      scoreTotal: _score(json['score_total']),
      export: CvExportState.fromJson(json['export']),
      language: _language(json['language']),
    );
  }

  /// Null when the API row has no usable id; such rows can't be edited,
  /// deleted, or re-rendered.
  final int? id;
  final String title;
  final String badge;
  final bool isDraft;
  final bool canDownload;
  final String pdfUrl;
  final String templatePdfUrl;
  final DateTime? updatedAt;

  /// Server-formatted fallback when no timestamp is present.
  final String updatedLabel;

  /// ATS score 0-100; null when the CV hasn't been scored yet.
  final int? scoreTotal;

  /// Whether the server will export this CV; null from older servers.
  final CvExportState? export;

  /// The CV's own language; null when the server does not send it.
  final String? language;

  /// Stored link to use when the CV can't be re-fetched.
  String get storedPdfUrl =>
      templatePdfUrl.isNotEmpty ? templatePdfUrl : pdfUrl;

  /// Whether a download should first offer a template choice.
  bool get offersTemplateChoice => id != null || templatePdfUrl.isNotEmpty;
}

/// Parsed `/mobile/my-cvs` payload.
class CvList {
  const CvList({
    required this.title,
    required this.items,
    required this.offline,
  });

  factory CvList.fromPayload(
    Map<String, dynamic> data, {
    required bool english,
  }) {
    final raw = data['items'];
    final title = _text(data['title']);
    return CvList(
      title: title,
      // Non-object rows are dropped rather than shown as blank cards.
      items: raw is List
          ? [
              for (final item in raw)
                if (item is Map<String, dynamic>) CvListItem.fromJson(item),
            ]
          : const [],
      offline: MobileContentService.isOfflinePayload(data),
    );
  }

  /// Shell shown when the list can't be loaded — never invents rows.
  factory CvList.empty({required bool english}) => const CvList(
        title: '',
        items: [],
        offline: false,
      );

  /// Server title; empty when omitted (the screen shows its catalog label).
  final String title;
  final List<CvListItem> items;
  final bool offline;

  CvList without(int id) => CvList(
        title: title,
        items: [
          for (final item in items)
            if (item.id != id) item,
        ],
        offline: offline,
      );
}

/// Adds `template=<slug>` to [url], keeping existing query parameters.
/// Returns [url] unchanged when there's no slug or it doesn't parse.
String withTemplateParam(String url, String? templateSlug) {
  if (templateSlug == null || templateSlug.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return url;
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'template': templateSlug,
  }).toString();
}

String _text(Object? value) => value?.toString().trim() ?? '';

String? _language(Object? value) => normalizeLanguageCode(value);

int? _id(Object? value) {
  final n = switch (value) {
    int() => value,
    String() => int.tryParse(value.trim()),
    _ => null,
  };
  return n != null && n > 0 ? n : null;
}

/// Accepts JSON booleans and the 0/1 forms Laravel often serialises.
bool _flag(Object? value, {required bool fallback}) => switch (value) {
      bool() => value,
      num() => value != 0,
      'true' || '1' => true,
      'false' || '0' => false,
      _ => fallback,
    };

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

/// A 0-100 score, or null when missing or out of range.
int? _score(Object? value) {
  final n = switch (value) {
    num() => value.round(),
    String() => num.tryParse(value.trim())?.round(),
    _ => null,
  };
  return n != null && n >= 0 && n <= 100 ? n : null;
}
