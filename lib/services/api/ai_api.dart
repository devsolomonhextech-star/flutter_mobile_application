import 'dart:convert';
import 'package:doctor_app/services/session_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../data/constants/urls.dart';

class AiApi {
  final SessionService _session = Get.find<SessionService>();

  /// Calls: GET /api/v1/ai/patient-summary/:visitId
  Future<Map<String, dynamic>> getPatientAiSummary({
    required String visitId,
  }) async {
    try {
      final token = _session.token;

      final uri = Uri.parse('$baseUrl/ai/patient-summary/$visitId');

      final response = await http
          .get(
            uri,
            headers: {
              "Authorization": token != null && token.isNotEmpty
                  ? "Bearer $token"
                  : "",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 60));

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String text = '';

        try {
          text = decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
        } catch (_) {
          text = '';
        }

        return {"success": true, "text": text};
      }

      return {
        "success": false,
        "error": decoded is Map<String, dynamic>
            ? (decoded['error'] ??
                  decoded['message'] ??
                  decoded['message'] ??
                  decoded)
            : 'Failed to get AI summary',
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }
}
