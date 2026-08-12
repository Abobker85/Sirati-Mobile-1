import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(
      {http.Client? httpClient, Future<String?> Function()? tokenProvider})
      : _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;
  static const _timeout = Duration(seconds: 45);

  /// Invoked once when an authenticated call returns 401/403.
  /// Set from app bootstrap (see [AuthSessionGuard]).
  static Future<void> Function()? onAuthExpired;

  Future<Map<String, dynamic>> getJson(String path) async {
    final headers = await _headers();
    final response = await _send(() {
      return _httpClient.get(
        ApiConfig.uri(path),
        headers: headers,
      );
    });

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers(contentType: 'application/json');
    final response = await _send(() {
      return _httpClient.post(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body),
      );
    });

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers(contentType: 'application/json');
    final response = await _send(() {
      return _httpClient.put(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body),
      );
    });

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path,
      {Map<String, dynamic>? body}) async {
    final headers =
        await _headers(contentType: body != null ? 'application/json' : null);
    final response = await _send(() {
      return _httpClient.delete(
        ApiConfig.uri(path),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    http.MultipartFile? file,
  }) async {
    final headers = await _headers();
    final response = await _send(() async {
      final request = http.MultipartRequest('POST', ApiConfig.uri(path))
        ..headers.addAll(headers)
        ..fields.addAll(fields);

      if (file != null) {
        request.files.add(file);
      }

      final streamedResponse =
          await _httpClient.send(request).timeout(_timeout);
      return http.Response.fromStream(streamedResponse);
    });

    return _decodeObject(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      final exception = _exceptionFromResponse(response);
      // Only HTTP 401 means the session token is invalid/expired.
      // 403 (forbidden / not your resource) must NOT force logout.
      if (response.statusCode == 401 &&
          _tokenProvider != null &&
          onAuthExpired != null) {
        // Fire-and-forget; do not block the throw path.
        // ignore: unawaited_futures
        onAuthExpired!();
      }
      throw exception;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException.timeout(
          'انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.');
    } on http.ClientException {
      throw const ApiException.network(
          'تعذر الاتصال بالخادم. تأكد من تشغيل Laravel وصحة رابط API.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException.network(
          'حدث خطأ غير متوقع أثناء الاتصال بالخادم.');
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException('استجابة الخادم غير متوقعة.',
        type: ApiErrorType.unknown);
  }

  Future<Map<String, String>> _headers({String? contentType}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Sirati-Async': '1',
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  ApiException _exceptionFromResponse(http.Response response) {
    try {
      final decoded = _decodeObject(response);
      final message =
          decoded['message']?.toString() ?? 'فشل الطلب. حاول مرة أخرى.';
      final rawErrors = decoded['errors'];
      final errors = <String, List<String>>{};

      if (rawErrors is Map<String, dynamic>) {
        rawErrors.forEach((key, value) {
          if (value is List) {
            errors[key] = value.map((item) => item.toString()).toList();
          } else if (value != null) {
            errors[key] = [value.toString()];
          }
        });
      }

      return ApiException(message,
          statusCode: response.statusCode,
          errors: errors,
          type: _typeFromStatus(response.statusCode));
    } catch (_) {
      return ApiException(
        'فشل الطلب برمز ${response.statusCode}.',
        statusCode: response.statusCode,
        type: _typeFromStatus(response.statusCode),
      );
    }
  }

  static ApiErrorType _typeFromStatus(int status) {
    if (status == 401 || status == 403) return ApiErrorType.auth;
    if (status == 404) return ApiErrorType.notFound;
    if (status == 422) return ApiErrorType.validation;
    if (status == 429) return ApiErrorType.rateLimited;
    if (status >= 500 && status < 600) return ApiErrorType.server;
    return ApiErrorType.unknown;
  }
}
