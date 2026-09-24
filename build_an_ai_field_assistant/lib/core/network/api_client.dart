import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';

/// HTTP Client wrapper for external services & Gemini AI API
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Perform POST request with JSON body
  Future<Map<String, dynamic>> postJson({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final combinedHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        ...?headers,
      };

      final response = await _client
          .post(
            Uri.parse(url),
            headers: combinedHeaders,
            body: jsonEncode(body),
          )
          .timeout(ApiEndpoints.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('Không có kết nối mạng Internet.');
    } on TimeoutException {
      throw const NetworkException('Quá thời gian kết nối đến máy chủ.');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('Lỗi mạng không xác định: $e');
    }
  }

  /// Perform GET request
  Future<dynamic> get({
    required String url,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiEndpoints.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('Không có kết nối mạng Internet.');
    } on TimeoutException {
      throw const NetworkException('Quá thời gian kết nối.');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('Lỗi GET: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (e) {
        throw ServerException('Dữ liệu máy chủ trả về không đúng định dạng JSON: $e');
      }
    } else {
      String errorMessage = 'Lỗi HTTP (${response.statusCode})';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['error'] != null) {
          errorMessage = decoded['error']['message'] ?? decoded['error'].toString();
        }
      } catch (_) {}
      throw ServerException(errorMessage, response.statusCode);
    }
  }

  void close() {
    _client.close();
  }
}
