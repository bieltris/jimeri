import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/http_interceptor.dart';

import 'api_auth_delegate.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'expired_token_retry_policy.dart';
import 'type_responses.dart';

typedef ResponseFactory<T> = T Function(dynamic json);

const Map<String, String> _jsonHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

Client _createBaseClient() {
  if (kIsWeb) {
    return BrowserClient()..withCredentials = true;
  }

  return Client();
}

final Client baseClient = _createBaseClient();

late Client apiClient;
late ApiAuthDelegate _auth;
bool _isConfigured = false;

void configureApiClient({
  required ApiAuthDelegate auth,
}) {
  _auth = auth;
  apiClient = InterceptedClient.build(
    client: baseClient,
    interceptors: [
      AuthInterceptor(auth),
    ],
    retryPolicy: ExpiredTokenRetryPolicy(auth),
  );
  _isConfigured = true;
}

class ApiClient {
  ApiClient._();

  static Future<T> get<T>(
    Uri uri, {
    Map<String, String>? headers,
    ResponseFactory<T>? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: _HttpMethod.get,
      uri: uri,
      headers: headers,
      fromJson: fromJson,
      timeout: timeout,
    );
  }

  static Future<T> post<T>(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    ResponseFactory<T>? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: _HttpMethod.post,
      uri: uri,
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
    );
  }

  static Future<T> put<T>(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    ResponseFactory<T>? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: _HttpMethod.put,
      uri: uri,
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
    );
  }

  static Future<T> patch<T>(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    ResponseFactory<T>? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: _HttpMethod.patch,
      uri: uri,
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
    );
  }

  static Future<T> delete<T>(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    ResponseFactory<T>? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: _HttpMethod.delete,
      uri: uri,
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
    );
  }

  static ResponseFactory<List<T>> listFromJson<T>(
    T Function(JsonMap json) itemFromJson,
  ) {
    return (json) {
      if (json is! List) {
        throw const ApiException('Resposta esperada como lista.');
      }

      return json.map((item) {
        if (item is! JsonMap) {
          throw const ApiException('Item da lista em formato invalido.');
        }

        return itemFromJson(item);
      }).toList();
    };
  }

  static Future<T> _sendRequest<T>({
    required _HttpMethod method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    ResponseFactory<T>? fromJson,
    Duration? timeout,
  }) async {
    _ensureConfigured();

    try {
      final request = _executeRequest(
        method: method,
        uri: uri,
        headers: {
          ..._jsonHeaders,
          if (headers != null) ...headers,
        },
        body: body,
      );

      final response = await (timeout == null ? request : request.timeout(timeout));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSuccessResponse(response, fromJson);
      }

      await _handleFailure(uri, response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Tempo limite da requisicao excedido.');
    } on ClientException {
      throw const ApiException('Nao foi possivel conectar com o servidor.');
    } on FormatException {
      throw const ApiException('Resposta invalida recebida do servidor.');
    } catch (error) {
      throw ApiException('Erro inesperado: $error');
    }
  }

  static Future<Response> _executeRequest({
    required _HttpMethod method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) {
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case _HttpMethod.get:
        return apiClient.get(uri, headers: headers);
      case _HttpMethod.post:
        return apiClient.post(uri, headers: headers, body: encodedBody);
      case _HttpMethod.put:
        return apiClient.put(uri, headers: headers, body: encodedBody);
      case _HttpMethod.patch:
        return apiClient.patch(uri, headers: headers, body: encodedBody);
      case _HttpMethod.delete:
        return apiClient.delete(uri, headers: headers, body: encodedBody);
    }
  }

  static T _parseSuccessResponse<T>(
    Response response,
    ResponseFactory<T>? fromJson,
  ) {
    if (response.body.isEmpty) {
      return null as T;
    }

    final decoded = jsonDecode(response.body);
    final data = _unwrapData(decoded);

    if (fromJson != null) {
      return fromJson(data);
    }

    final mapped = _processDeepMapping(data);

    if (mapped is T) {
      return mapped;
    }

    throw ApiException(
      'Resposta nao corresponde ao tipo esperado.',
      statusCode: response.statusCode,
      body: decoded,
    );
  }

  static Future<Never> _handleFailure(Uri uri, Response response) async {
    final decoded = _tryDecode(response.body);
    final message = _extractErrorMessage(decoded) ??
        'Erro na requisicao. Codigo: ${response.statusCode}';

    if (response.statusCode == 401 && !_auth.shouldSkipAuth(uri)) {
      await _auth.logout();
    }

    throw ApiException(
      message,
      statusCode: response.statusCode,
      body: decoded,
    );
  }

  static Object? _unwrapData(Object? decoded) {
    if (decoded is JsonMap && decoded.containsKey('data')) {
      return decoded['data'];
    }

    return decoded;
  }

  static Object? _tryDecode(String body) {
    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  static String? _extractErrorMessage(Object? decoded) {
    if (decoded is JsonMap) {
      final message = decoded['message'] ?? decoded['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }

    return null;
  }

  static Object? _processDeepMapping(Object? value) {
    if (value is List) {
      return value.map(_processDeepMapping).toList();
    }

    if (value is JsonMap) {
      final mapped = <String, Object?>{};

      for (final entry in value.entries) {
        final entryValue = entry.value;

        if (entryValue is JsonMap && TypeResponses.hasFactory(entry.key)) {
          mapped[entry.key] = TypeResponses.fromKey(entry.key, entryValue);
          continue;
        }

        mapped[entry.key] = _processDeepMapping(entryValue);
      }

      return mapped;
    }

    return value;
  }

  static void _ensureConfigured() {
    if (!_isConfigured) {
      throw const ApiException(
        'ApiClient nao configurado. Chame configureApiClient antes de usar.',
      );
    }
  }
}

enum _HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}
