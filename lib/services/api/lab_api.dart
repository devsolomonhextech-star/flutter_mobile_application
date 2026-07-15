import 'dart:convert';

import 'package:doctor_app/data/constants/urls.dart';
import 'package:doctor_app/data/models/lab_models.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LabApi {
  final SessionService _session = Get.find<SessionService>();

  /// GET /api/v1/lab/patient-labs?patient_id=<uuid>&status=<optional>
  Future<Map<String, dynamic>> getPatientLabs({
    required String patientId,
    String? status,
  }) async {
    try {
      final token = _session.token;
      if (token == null || token.isEmpty) {
        return {"success": false, "error": "Missing auth token"};
      }

      final uri = Uri.parse('$baseUrl/lab/patient-labs').replace(
        queryParameters: {
          'patient_id': patientId,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // expected: { status:'success', data:{ visits:[...] }, ... }
        final data = (responseData is Map) ? responseData['data'] : null;
        final visitsJson = data is Map ? data['visits'] : null;

        final visits = (visitsJson is List)
            ? visitsJson
                .map((e) => PatientLabVisit.fromJson(e as Map<String, dynamic>))
                .toList()
            : <PatientLabVisit>[];

        return {
          'success': true,
          'data': visits,
          'count': visits.length,
        };
      }

      return {
        'success': false,
        'error': responseData is Map
            ? responseData['error'] ?? responseData['message'] ?? 'Failed'
            : 'Failed',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

