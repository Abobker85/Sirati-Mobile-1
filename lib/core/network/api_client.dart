import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sirati/core/l10n/remote_l10n.dart';
import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';

class ApiClient {
  ApiClient(
      {http.Client? httpClient, Future<String?> Function()? tokenProvider})
      : _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;
  static const _timeout = Duration(seconds: 45);

  /// Invoked once when an authenticated call returns 401.
  /// Set from app bootstrap (see [AuthSessionGuard]).
  ///
  /// [requestToken] is the bearer token sent with the failed request so a
  /// delayed 401 cannot clear a newer session.
  static Future<void> Function({String? requestToken})? onAuthExpired;

  Future<Map<String, dynamic>> getJson(String path) async {
    final authorized = await _authorizedHeaders();
    final response = await _send(
      () {
        return _httpClient.get(
          ApiConfig.uri(path),
          headers: authorized.headers,
        );
      },
      requestToken: authorized.token,
    );

    return _decodeObject(response);
  }

  Future<List<int>> getBytes(
    String path, {
    Duration receiveTimeout = _timeout,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final authorized = await _authorizedHeaders();
    final response = await _send(
      () async {
        final request = http.Request('GET', ApiConfig.uri(path))
          ..headers.addAll(authorized.headers);
        final streamed =
            await _httpClient.send(request).timeout(receiveTimeout);
        final bytes = <int>[];
        await for (final chunk in streamed.stream.timeout(receiveTimeout)) {
          bytes.addAll(chunk);
          if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
            onReceiveProgress?.call(bytes.length, streamed.contentLength ?? -1);
          }
        }
        return http.Response.bytes(bytes, streamed.statusCode,
            headers: streamed.headers,
            reasonPhrase: streamed.reasonPhrase,
            request: streamed.request);
      },
      requestToken: authorized.token,
      timeout: receiveTimeout,
    );

    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
  }) async {
    final authorized =
        await _authorizedHeaders(contentType: 'application/json');
    final headers = {...authorized.headers, ...?extraHeaders};
    final response = await _send(
      () {
        return _httpClient.post(
          ApiConfig.uri(path),
          headers: headers,
          body: jsonEncode(body),
        );
      },
      requestToken: authorized.token,
    );

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
  }) async {
    final authorized =
        await _authorizedHeaders(contentType: 'application/json');
    final headers = {...authorized.headers, ...?extraHeaders};
    final response = await _send(
      () {
        return _httpClient.put(
          ApiConfig.uri(path),
          headers: headers,
          body: jsonEncode(body),
        );
      },
      requestToken: authorized.token,
    );

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path,
      {Map<String, dynamic>? body}) async {
    final authorized = await _authorizedHeaders(
        contentType: body != null ? 'application/json' : null);
    final response = await _send(
      () {
        return _httpClient.delete(
          ApiConfig.uri(path),
          headers: authorized.headers,
          body: body != null ? jsonEncode(body) : null,
        );
      },
      requestToken: authorized.token,
    );

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    http.MultipartFile? file,
    Map<String, String>? extraHeaders,
  }) async {
    final authorized = await _authorizedHeaders();
    final headers = {...authorized.headers, ...?extraHeaders};
    final response = await _send(
      () async {
        final request = http.MultipartRequest('POST', ApiConfig.uri(path))
          ..headers.addAll(headers)
          ..fields.addAll(fields);

        if (file != null) {
          request.files.add(file);
        }

        final streamedResponse =
            await _httpClient.send(request).timeout(_timeout);
        return http.Response.fromStream(streamedResponse);
      },
      requestToken: authorized.token,
    );

    return _decodeObject(response);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    String? requestToken,
    Duration timeout = _timeout,
  }) async {
    try {
      final response = await request().timeout(timeout);
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
        onAuthExpired!(requestToken: requestToken);
      }
      throw exception;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException.timeout(RemoteL10n.current.sharedErrorTimeoutSubtitle);
    } on FormatException {
      throw ApiException(
        RemoteL10n.current.coreApiErrorBadResponse,
        type: ApiErrorType.unknown,
      );
    } on http.ClientException {
      throw ApiException.network(RemoteL10n.current.sharedErrorNetworkSubtitle);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.network(RemoteL10n.current.coreApiErrorUnexpected);
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (body.trim().isEmpty) {
      throw ApiException(
        RemoteL10n.current.coreApiErrorEmptyResponse,
        type: ApiErrorType.unknown,
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw ApiException(
        RemoteL10n.current.coreApiErrorBadResponse,
        type: ApiErrorType.unknown,
      );
    }

    throw ApiException(RemoteL10n.current.coreApiErrorBadResponse,
        type: ApiErrorType.unknown);
  }

  Future<({Map<String, String> headers, String? token})> _authorizedHeaders(
      {String? contentType}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Sirati-Async': '1',
      // The server writes its messages in this language (#12).
      'X-App-Language': AppLocale.languageCode.value,
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return (headers: headers, token: token);
  }

  ApiException _exceptionFromResponse(http.Response response) {
    try {
      final decoded = _decodeObject(response);
      final message = decoded['message']?.toString() ??
          RemoteL10n.current.coreApiErrorRequestFailed;
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
    } on ApiException catch (exception) {
      if (exception.statusCode != null) rethrow;
      return ApiException(
        RemoteL10n.current.coreApiErrorStatus(response.statusCode),
        statusCode: response.statusCode,
        type: _typeFromStatus(response.statusCode),
      );
    } catch (_) {
      return ApiException(
        RemoteL10n.current.coreApiErrorStatus(response.statusCode),
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
