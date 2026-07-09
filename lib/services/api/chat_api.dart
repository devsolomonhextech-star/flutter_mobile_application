// lib/services/api/chat_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApi {
  static const String baseUrl = 'http://localhost:5001/api/v1';

  static Future<Map<String, dynamic>> getDepartmentsByInstitution({
    required String institutionId,
    String? token,
  }) async {
    final url = Uri.parse(
  '$baseUrl/chats/get-departments?institution_id=$institutionId',
);

    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      url,
      headers: headers,
    );

    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }

    throw Exception(body['message'] ?? 'Failed to fetch departments');
  }
}