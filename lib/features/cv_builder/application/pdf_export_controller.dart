import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/features/cv_builder/domain/export_file_namer.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/models/generated_cv.dart';

enum ExportStatus {
  idle,
  downloading,
  ready,
  error,

  /// The server answered 402: exporting needs a subscription.
  premiumLocked,

  /// The server answered 2xx with something that is not a PDF.
  notPdf,
}

/// Hands files to the platform share sheet. [fileNameOverrides] names
/// in-memory files (cross_file ignores their own name off the web).
typedef ShareFiles = Future<void> Function(
  List<XFile> files, {
  required List<String> fileNameOverrides,
  String? text,
  String? subject,
  Rect? sharePositionOrigin,
});

Future<void> _systemShare(
  List<XFile> files, {
  required List<String> fileNameOverrides,
  String? text,
  String? subject,
  Rect? sharePositionOrigin,
}) =>
    Share.shareXFiles(
      files,
      fileNameOverrides: fileNameOverrides,
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );

/// The share sheet; tests replace it to inspect the shared file.
final pdfShareProvider = Provider<ShareFiles>((ref) => _systemShare);

/// Whether [bytes] start with the PDF header (`%PDF-`).
bool isPdfBytes(List<int> bytes) =>
    bytes.length >= 5 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46 &&
    bytes[4] == 0x2D;

class PdfExportState {
  final ExportStatus status;
  final double progress;
  final Uint8List? pdfBytes;
  final String filename;

  const PdfExportState({
    required this.status,
    required this.progress,
    required this.pdfBytes,
    required this.filename,
  });

  PdfExportState copyWith({
    ExportStatus? status,
    double? progress,
    Uint8List? pdfBytes,
    bool clearBytes = false,
  }) {
    return PdfExportState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      pdfBytes: clearBytes ? null : (pdfBytes ?? this.pdfBytes),
      filename: filename,
    );
  }
}

/// Downloads a generated CV's PDF in the CV's own language and shares it.
/// Only bytes with a PDF header are ever kept or shared.
class PdfExportController extends ChangeNotifier {
  final ApiClient _apiClient;
  final GeneratedCv _cv;
  final CvTemplate? _template;
  final ShareFiles _share;
  late PdfExportState _state;

  /// A null [template] lets the server use its default design.
  PdfExportController({
    required ApiClient apiClient,
    required GeneratedCv cv,
    CvTemplate? template,
    ShareFiles? share,
  })  : _apiClient = apiClient,
        _cv = cv,
        _template = template,
        _share = share ?? _systemShare {
    _state = PdfExportState(
      status: ExportStatus.idle,
      progress: 0.0,
      pdfBytes: null,
      filename: ExportFileNamer.formatFilename(
        fullName: cv.fullName,
        targetJobTitle: cv.targetJobTitle,
        language: cv.language,
      ),
    );
  }

  PdfExportState get state => _state;

  void _set(PdfExportState state) {
    _state = state;
    notifyListeners();
  }

  String get _downloadPath => Uri(
        path: '/generated-cvs/${_cv.id}/download',
        queryParameters: {
          if (_template case final template?) 'template': template.slug,
          'language': _cv.language,
        },
      ).toString();

  Future<bool> exportPdf() async {
    _set(_state.copyWith(
      status: ExportStatus.downloading,
      progress: 0.0,
      clearBytes: true,
    ));

    try {
      final bytes = await _apiClient.getBytes(
        _downloadPath,
        receiveTimeout: const Duration(seconds: 90),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _set(_state.copyWith(
              progress: (received / total).clamp(0.0, 1.0),
            ));
          }
        },
      );
      if (!isPdfBytes(bytes)) {
        _set(_state.copyWith(status: ExportStatus.notPdf));
        return false;
      }
      _set(_state.copyWith(
        status: ExportStatus.ready,
        progress: 1.0,
        pdfBytes: Uint8List.fromList(bytes),
      ));
      return true;
    } on ApiException catch (e) {
      _set(_state.copyWith(
        status: e.statusCode == 402
            ? ExportStatus.premiumLocked
            : ExportStatus.error,
      ));
      return false;
    } catch (_) {
      _set(_state.copyWith(status: ExportStatus.error));
      return false;
    }
  }

  /// Downloads the PDF if needed and opens the share sheet with it.
  /// False when there was no PDF to share ([state] says why).
  Future<bool> sharePdf({Rect? sharePositionOrigin}) async {
    if (_state.pdfBytes == null && !await exportPdf()) return false;
    final bytes = _state.pdfBytes;
    if (bytes == null || !isPdfBytes(bytes)) return false;

    await _share(
      [
        XFile.fromData(bytes,
            name: _state.filename, mimeType: 'application/pdf')
      ],
      fileNameOverrides: [_state.filename],
      text: _cv.fullName,
      subject: _state.filename,
      sharePositionOrigin: sharePositionOrigin,
    );
    return true;
  }
}
