import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sse_frontend_mobil/config/api_config.dart';

// ignore_for_file: prefer_initializing_formals

class ApiClient {
  final String baseUrl;
  final Future<String?> Function() _tokenGetter;
  final void Function()? _onUnauthorized;

  ApiClient({
    String? baseUrl,
    required Future<String?> Function() tokenGetter,
    void Function()? onUnauthorized,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _tokenGetter = tokenGetter,
        _onUnauthorized = onUnauthorized;

  Future<Map<String, String>> _headers() async {
    final token = await _tokenGetter();
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    final response = await http.put(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<http.Response> multipart(
    String path, {
    required File file,
    String fieldName = 'file',
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _tokenGetter();
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _onUnauthorized?.call();
    }
    if (response.statusCode >= 400) {
      String message;
      try {
        final body = jsonDecode(response.body);
        message = body['error'] as String? ?? 'Error ${response.statusCode}';
      } catch (_) {
        message = 'Error ${response.statusCode}';
      }
      throw ApiException(statusCode: response.statusCode, message: message);
    }
    return response;
  }

  T parse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return fromJson(body);
  }

  List<T> parseList<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    final body = jsonDecode(response.body);
    final list = body is List ? body : body['notifications'] ?? body['users'] ?? [body];
    return (list as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
