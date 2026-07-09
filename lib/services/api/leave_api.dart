import 'dart:convert';

import 'package:doctor_app/services/session_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LeaveApi {
  static const String baseUrl = 'http://localhost:5001/api/v1';

  static Map<String, String> _authHeaders() {
    final session = Get.find<SessionService>();
    final token = session.token;

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// POST /api/v1/leave/request
  static Future<Map<String, dynamic>> requestLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
    required String emergencyContact,
    String? documentUrl,
  }) async {
    final url = Uri.parse('$baseUrl/leave/request');

    final resp = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'emergencyContact': emergencyContact,
        if (documentUrl != null && documentUrl.trim().isNotEmpty)
          'documentUrl': documentUrl,
      }),
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // Backend returns: { message, leave }
      return (body is Map<String, dynamic>) ? body : <String, dynamic>{};
    }

    throw Exception((body['message'] ?? body['error'] ?? body).toString());
  }

  /// GET /api/v1/leave/my-leaves
  static Future<List<dynamic>> getMyLeaves() async {
    final session = Get.find<SessionService>();
    final staffId = session.userId;
    if (staffId == null || staffId.isEmpty) {
      throw Exception('Missing staff id');
    }

    final url = Uri.parse('$baseUrl/leave/my-leaves');

    final resp = await http.get(
      url,
      headers: _authHeaders(),
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // Backend returns array
      return (body is List) ? body : <dynamic>[];
    }

    throw Exception((body['message'] ?? body['error'] ?? body).toString());
  }

  /// PUT /api/v1/leave/cancel/:leaveId
  static Future<void> cancelLeave({required String leaveId}) async {
    final url = Uri.parse('$baseUrl/leave/cancel/$leaveId');

    final resp = await http.put(
      url,
      headers: _authHeaders(),
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    }

    throw Exception((body['message'] ?? body['error'] ?? body).toString());
  }

  /// GET /api/v1/leave/balance
  static Future<List<dynamic>> getLeaveBalance() async {
    final session = Get.find<SessionService>();
    final staffId = session.userId;
    if (staffId == null || staffId.isEmpty) {
      throw Exception('Missing staff id');
    }

    final url = Uri.parse('$baseUrl/leave/balance');

    final resp = await http.get(
      url,
      headers: _authHeaders(),
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return (body is List) ? body : <dynamic>[];
    }

    throw Exception((body['message'] ?? body['error'] ?? body).toString());
  }

  static dynamic _decodeBody(http.Response resp) {
    if (resp.body.isEmpty) return {};
    try {
      return jsonDecode(resp.body);
    } catch (_) {
      return resp.body;
    }
  }
}

