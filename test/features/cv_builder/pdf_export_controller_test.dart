import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/features/cv_builder/application/pdf_export_controller.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/models/generated_cv.dart';

GeneratedCv _cv({String language = 'ar'}) => GeneratedCv.fromJson({
      'id': 101,
      'full_name': 'أحمد علي الغامدي',
      'target_job_title': 'مهندس برمجيات',
      'email': 'ahmed@example.com',
      'phone': '+966501112233',
      'language': language,
      'generated_markdown': '# السيرة الذاتية',
      'score_total': 90,
      'grade': 'A',
      'ai_status': 'completed',
    });

const _premium = CvTemplate(
  id: 2,
  slug: 'executive-leadership-brief',
  name: 'Executive',
  nameAr: 'Executive',
  nameEn: 'Executive',
  previewImageUrl: null,
  languageDirection: 'both',
  supportedLanguages: ['ar', 'en'],
  supportedSections: [],
  isDefault: false,
  isPremium: true,
);

class _Shared {
  final calls = <List<XFile>>[];
  final names = <List<String>>[];

  Future<void> call(List<XFile> files,
      {required List<String> fileNameOverrides,
      String? text,
      String? subject,
      Rect? sharePositionOrigin}) async {
    calls.add(files);
    names.add(fileNameOverrides);
  }
}

ApiClient _serving(int status, List<int> body, {List<Uri>? requests}) =>
    ApiClient(
      httpClient: MockClient((req) async {
        requests?.add(req.url);
        return http.Response.bytes(body, status,
            headers: {'content-type': 'application/pdf'});
      }),
    );

List<int> _pdf(Random r) => [
      ...ascii.encode('%PDF-1.${r.nextInt(8)}\n'),
      for (var i = 0; i < r.nextInt(400); i++) r.nextInt(256),
    ];

void main() {
  final random = Random(19);

  group('the shared file is the PDF the server sent', () {
    test('any PDF body is shared byte for byte as application/pdf', () async {
      for (var i = 0; i < 40; i++) {
        final body = _pdf(random);
        final shared = _Shared();
        final requests = <Uri>[];
        final language = ['ar', 'en', 'fr', 'ur'][i % 4];
        final controller = PdfExportController(
          apiClient: _serving(200, body, requests: requests),
          cv: _cv(language: language),
          share: shared.call,
        );
        expect(await controller.sharePdf(), isTrue);
        final file = shared.calls.single.single;
        expect(await file.readAsBytes(), body);
        expect(file.mimeType, 'application/pdf');
        expect(shared.names.single.single, endsWith('.pdf'));
        expect(requests.single.queryParameters['language'], language);
        expect(
            requests.single.queryParameters.containsKey('template'), isFalse);
        controller.dispose();
      }
    });

    test('a body that is not a PDF is never shared', () async {
      final bodies = <List<int>>[
        [],
        ascii.encode('%PDF'),
        ascii.encode('%PDf-1.4'),
        ascii.encode(' %PDF-1.4'),
        utf8.encode('<html><body>Login</body></html>'),
        utf8.encode('{"message":"ok"}'),
        for (var i = 0; i < 40; i++)
          [
            for (var j = 0; j < random.nextInt(64); j++) random.nextInt(256),
          ],
      ].where((b) => !(b.length >= 5 &&
          ascii.decode(b.sublist(0, 5), allowInvalid: true) == '%PDF-'));
      for (final body in bodies) {
        final shared = _Shared();
        final controller = PdfExportController(
          apiClient: _serving(200, body),
          cv: _cv(),
          share: shared.call,
        );
        expect(await controller.sharePdf(), isFalse);
        expect(controller.state.status, ExportStatus.notPdf);
        expect(controller.state.pdfBytes, isNull);
        expect(shared.calls, isEmpty);
        controller.dispose();
      }
    });
  });

  group('premium lock comes from the status code', () {
    test('402 is locked whatever the body says; other errors are not',
        () async {
      final bodies = [
        '{"message":"premium"}',
        '{"message":"هذا القالب متاح للمشتركين فقط"}',
        '{"message":"anything"}',
        '',
      ];
      for (final status in [400, 401, 402, 403, 404, 409, 422, 500, 503]) {
        for (final body in bodies) {
          final shared = _Shared();
          final controller = PdfExportController(
            apiClient: _serving(status, utf8.encode(body)),
            cv: _cv(),
            template: _premium,
            share: shared.call,
          );
          expect(await controller.sharePdf(), isFalse);
          expect(controller.state.status,
              status == 402 ? ExportStatus.premiumLocked : ExportStatus.error,
              reason: '$status $body');
          expect(shared.calls, isEmpty);
          controller.dispose();
        }
      }
    });
  });

  test('progress follows received chunks', () async {
    final chunks = StreamController<List<int>>();
    final requested = Completer<void>();
    final client =
        ApiClient(httpClient: MockClient.streaming((request, _) async {
      requested.complete();
      return http.StreamedResponse(chunks.stream, 200, contentLength: 20);
    }));
    final controller = PdfExportController(apiClient: client, cv: _cv());
    final progress = <double>[];
    controller.addListener(() => progress.add(controller.state.progress));
    final download = controller.exportPdf();
    await requested.future;
    expect(controller.state.progress, 0);
    chunks.add(ascii.encode('%PDF-'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.progress, 0.25);
    chunks.add(List.filled(10, 2));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.progress, 0.75);
    chunks.add(List.filled(5, 3));
    await chunks.close();
    expect(await download, isTrue);
    expect(progress, containsAllInOrder([0.0, 0.25, 0.75, 1.0]));
    controller.dispose();
  });

  testWidgets(
      'PDF times out at 90 seconds while JSON keeps its 45 second limit',
      (tester) async {
    final transport = _PendingHttpClient();
    final client = ApiClient(httpClient: transport);
    final controller = PdfExportController(apiClient: client, cv: _cv());
    final download = controller.exportPdf();
    Object? jsonError;
    final json = client.getJson('/other').catchError((Object error) {
      jsonError = error;
      return <String, dynamic>{};
    });
    await tester.pump();
    expect(transport.requests, 2);
    await tester.pump(const Duration(seconds: 46));
    expect(jsonError, isNotNull);
    expect(controller.state.status, ExportStatus.downloading);
    await tester.pump(const Duration(seconds: 43));
    expect(controller.state.status, ExportStatus.downloading);
    await tester.pump(const Duration(seconds: 2));
    expect(controller.state.status, ExportStatus.error);
    expect(await download, isFalse);
    await json;
    controller.dispose();
  });
}

class _PendingHttpClient extends http.BaseClient {
  int requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests++;
    return Completer<http.StreamedResponse>().future;
  }
}
