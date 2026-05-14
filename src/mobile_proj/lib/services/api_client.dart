import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const ApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _httpClient;
  final Duration timeout;

  ApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> getJson(Uri uri) {
    return _send(() => _httpClient.get(uri, headers: _jsonHeaders));
  }

  Future<Map<String, dynamic>> postForm(
    Uri uri, {
    Map<String, String> body = const {},
  }) {
    return _send(() => _httpClient.post(uri, body: body));
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    Map<String, dynamic> body = const {},
  }) {
    return _send(
      () =>
          _httpClient.post(uri, headers: _jsonHeaders, body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeout);
      final data = _decodeJsonObject(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _messageForStatus(response.statusCode, data),
          statusCode: response.statusCode,
        );
      }

      return data;
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      throw ApiException(
        'The server took too long to respond. Please try again.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        'Could not connect to the server. Check your network and API URL.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw ApiException(
        'Invalid server response. Please try again later.',
        cause: error,
      );
    } catch (error) {
      throw ApiException(
        'Something went wrong. Please try again.',
        cause: error,
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const FormatException('Expected a JSON object');
  }

  String _messageForStatus(int statusCode, Map<String, dynamic> data) {
    final rawMessage = data['error'] ?? data['message'];
    final message = rawMessage?.toString().trim();

    if (statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    if (message != null && message.isNotEmpty) {
      return message;
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Invalid email or password.';
    }
    if (statusCode == 404) {
      return 'The requested service was not found.';
    }
    return 'Request failed. Please check your input and try again.';
  }
}

const Map<String, String> _jsonHeaders = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
};
