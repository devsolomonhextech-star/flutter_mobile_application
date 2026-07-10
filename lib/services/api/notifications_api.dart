import 'dart:convert';

import 'package:doctor_app/services/session_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NotificationsApi {
  static const String baseUrl = 'http://localhost:5001/api/v1';

  static Map<String, String> _authHeaders() {
    final session = Get.find<SessionService>();
    final token = session.token;

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<List<dynamic>> getMyNotifications({
    required String staffId,
    bool includeRead = true,
  }) async {
    final url = Uri.parse(
      '$baseUrl/notifications/get-notifications/?staffId=${Uri.encodeQueryComponent(staffId)}&includeRead=${includeRead ? 'true' : 'false'}',
    );

    final resp = await http.get(url, headers: _authHeaders());

    final body = _decodeBody(resp);
    print('NotificationsApi.getMyNotifications response: $body');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return (body['data'] as List?) ?? <dynamic>[];
    }

    throw Exception((body['error'] ?? body['message'] ?? 'Failed').toString());
  }

  static Future<int> getMyUnreadNotifications({
    required String staffId, 
  }) async {
    final url = Uri.parse(
      '$baseUrl/notifications/get-unread-count/?staffId=${Uri.encodeQueryComponent(staffId)}',
    );

    final resp = await http.get(url, headers: _authHeaders());

    final body = _decodeBody(resp);
    print('NotificationsApi.getMyUnreadNotifications response: ${body['unreadCount']}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return body['unreadCount'];
    }

    throw Exception((body['error'] ?? body['message'] ?? 'Failed').toString());
  }

  static Future<void> markNotificationsAsRead({
    required String staffId,
    required List<int> notificationIds,
  }) async {
    final url = Uri.parse('$baseUrl/notifications/mark-as-read');

    final resp = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({
        'staffId': staffId,
        'notificationIds': notificationIds,
      }),
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    }

    throw Exception((body['error'] ?? body['message'] ?? 'Failed').toString());
  }

  static Future<void> markAllAsRead({required String staffId}) async {
    final url = Uri.parse('$baseUrl/notifications/mark-all-as-read');

    final resp = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({'staffId': staffId}),
    );

    final body = _decodeBody(resp);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    }

    throw Exception((body['error'] ?? body['message'] ?? 'Failed').toString());
  }

  static Map<String, dynamic> _decodeBody(http.Response resp) {
    if (resp.body.isEmpty) return {};
    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return {};
  }
}
