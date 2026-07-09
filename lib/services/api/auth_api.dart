import 'dart:convert';
import 'package:doctor_app/data/models/auth_models.dart';
import 'package:http/http.dart' as http;

/// Base Auth API class with core authentication methods
class AuthApi {
  static const String baseUrl = 'http://localhost:5001/api/v1';
  static const String loginEndpoint = '/auth/login';

  static Future<LoginResponse> loginStaff({
    required String staffId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final resp = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staffID': staffId,
        'staffId': staffId,
        'password': password,
      }),
    );

    final body = _decodeBody(resp);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return LoginResponse.fromJson(body);
    }

    final msg = body['error'] ?? body['message'] ?? 'Login failed';
    throw Exception(msg.toString());
  }

  static Future<LogicVerifyResponse> verifyLogicAnswer({
    required String staffId,
    required String password,
    required dynamic selectedOption,
    required String? logicQuestion,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-logic-answer');

    final resp = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staffID': staffId,
        'password': password,
        'logic_question': logicQuestion,
        'logicQuestion': logicQuestion,
        'selectedAnswer': selectedOption,
      }),
    );

    final body = _decodeBody(resp);
    print('Verify Logic Response Status: ${resp.statusCode}');
  print('Verify Logic Response Body: ${body['user']}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return LogicVerifyResponse.fromJson(body['user']);
    }

    final msg = body['error'] ?? body['message'] ?? 'Logic verification failed';
    throw Exception(msg?.toString() ?? 'Logic verification failed');
  }

  static Map<String, dynamic> _decodeBody(http.Response resp) {
    if (resp.body.isEmpty) return {};
    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return {};
  }

  // get user details
  // Add this method to AuthApi class in auth_api.dart
  static Future<Map<String, dynamic>> getUserDetails({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/user/$userId');

    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return body;
    }

    final msg =
        body['error'] ?? body['message'] ?? 'Failed to get user details';
    throw Exception(msg.toString());
  }





}
