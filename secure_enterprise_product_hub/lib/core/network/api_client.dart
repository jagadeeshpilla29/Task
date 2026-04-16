import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    final baseUri = Uri.parse(baseUrl);
    final mediaUri = Uri.tryParse(url);
    if (mediaUri == null) {
      return url;
    }
    if (!mediaUri.hasScheme) {
      return baseUri.resolve(url).toString();
    }
    if (mediaUri.host == 'localhost' || mediaUri.host == '127.0.0.1') {
      return mediaUri
          .replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          )
          .toString();
    }
    return url;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const {},
    bool auth = true,
  }) async {
    final uri = _uri(path, query);
    final response = await _send(
      'GET',
      uri,
      () async => _client.get(uri, headers: await _headers(auth: auth)),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = _uri(path);
    final response = await _send(
      'POST',
      uri,
      () async => _client.post(
        uri,
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
      body: body,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = _uri(path);
    final response = await _send(
      'PUT',
      uri,
      () async =>
          _client.put(uri, headers: await _headers(), body: jsonEncode(body)),
      body: body,
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final uri = _uri(path);
    final response = await _send(
      'DELETE',
      uri,
      () async => _client.delete(uri, headers: await _headers()),
    );
    if (response.statusCode != 204) {
      _decode(response);
    }
  }

  Future<Map<String, dynamic>> uploadImage(String path, File file) async {
    final uri = _uri(path);
    final response = await _send('POST multipart', uri, () async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(await _headers(json: false));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }, body: {'file': file.path});
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanBase$path');
    final filtered = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null && value.trim().isNotEmpty) {
        filtered[entry.key] = value;
      }
    }
    return filtered.isEmpty ? uri : uri.replace(queryParameters: filtered);
  }

  Future<Map<String, String>> _headers({
    bool auth = true,
    bool json = true,
  }) async {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth) {
      final token = await tokenStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Future<http.Response> Function() send, {
    Map<String, dynamic>? body,
  }) async {
    _logRequest(method, uri, body: body);
    try {
      final response = await send();
      _logResponse(method, uri, response);
      return response;
    } on SocketException {
      throw ApiException(_networkFailureMessage(uri));
    } on http.ClientException {
      throw ApiException(_networkFailureMessage(uri));
    } on FileSystemException {
      throw ApiException('Could not read the selected image file.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    } on TypeError {
      throw ApiException(
        'The server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      body['message']?.toString() ??
          body['detail']?.toString() ??
          'Request failed',
      statusCode: response.statusCode,
    );
  }

  String _networkFailureMessage(Uri uri) {
    return 'Could not connect to ${uri.authority}. Check that the API server is running and API_BASE_URL is correct.';
  }

  void _logRequest(String method, Uri uri, {Map<String, dynamic>? body}) {
    final safeBody = Map<String, dynamic>.from(body ?? {});
    if (safeBody.containsKey('password')) {
      safeBody['password'] = '***';
    }
    debugPrint('[API] -> $method $uri ${safeBody.isEmpty ? '' : safeBody}');
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    final preview = response.body.length > 600
        ? '${response.body.substring(0, 600)}...'
        : response.body;
    debugPrint('[API] <- $method $uri ${response.statusCode} $preview');
  }
}
