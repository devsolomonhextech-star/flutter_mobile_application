// lib/services/http_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:doctor_app/services/session_service.dart';

class HttpService extends GetxService {
  final SessionService _session = Get.find<SessionService>();
  static const String baseUrl = 'YOUR_API_BASE_URL'; // Replace with your actual base URL

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = _session.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.get(uri, headers: headers);
    _handleResponse(response);
    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = _session.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = _session.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.put(
      uri,
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = _session.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.delete(uri, headers: headers);
    _handleResponse(response);
    return response;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Handle unauthorized - maybe redirect to login
      Get.offAllNamed('/login');
    }
  }
}