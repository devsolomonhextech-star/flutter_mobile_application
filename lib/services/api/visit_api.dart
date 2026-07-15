// lib/services/api/visit_api.dart

import 'dart:convert';
import 'package:doctor_app/data/constants/urls.dart';
import 'package:doctor_app/data/models/visit_models.dart';
import 'package:doctor_app/data/models/visit_related_models.dart';
import 'package:doctor_app/services/api/staff_comment_model.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

import '../../services/session_service.dart';

class VisitApi {
  final SessionService _session = Get.find<SessionService>();

  Future<Map<String, dynamic>> getActiveVisits({
    required String institutionId,
    String? departmentId,
  }) async {
    try {
      final token = _session.token;

      final Map<String, String> queryParameters = {
        "institution_id": institutionId,
      };

      if (departmentId != null && departmentId.isNotEmpty) {
        queryParameters["department_id"] = departmentId;
      }

      final uri = Uri.parse(
        '$baseUrl/records/visit/active',
      ).replace(queryParameters: queryParameters);

      print("GET ACTIVE VISITS URL: $uri");

      final response = await http
          .get(
            uri,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 30));

      final dynamic responseData = jsonDecode(response.body);

      print("Response runtimeType: ${responseData.runtimeType}");

      if (response.statusCode == 200) {
        dynamic data;

        // Handle direct array response:
        // [
        //   {...},
        //   {...}
        // ]
        if (responseData is List) {
          data = responseData;
        }
        // Handle wrapped response:
        // {
        //   success:true,
        //   data:[...]
        // }
        else if (responseData is Map) {
          data = responseData["data"];
        }

        List<dynamic> visitsJson = [];

        if (data is List) {
          visitsJson = data;
        } else if (data is Map && data["items"] is List) {
          visitsJson = data["items"];
        }

        print("visitsJson runtimeType: ${visitsJson.runtimeType}");

        if (visitsJson.isNotEmpty) {
          print(
            "first visit element runtimeType: ${visitsJson.first.runtimeType}",
          );
        }

        final List<Visit> visits = visitsJson
            .map((json) => Visit.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          "success": true,
          "data": visits,
          "count": responseData is Map
              ? responseData["count"] ?? visits.length
              : visits.length,
          "filters": responseData is Map ? responseData["filters"] ?? {} : {},
        };
      }

      return {
        "success": false,
        "error": responseData is Map
            ? responseData["error"] ??
                  responseData["message"] ??
                  "Failed to fetch visits"
            : "Failed to fetch visits",
      };
    } catch (e) {
      print("Get Active Visits Error: $e");

      return {"success": false, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVisitDetails({
    required String visitId,
  }) async {
    try {
      final token = _session.token;

      final response = await http
          .get(
            Uri.parse('$baseUrl/records/visits/$visitId'),

            headers: {
              "Authorization": "Bearer $token",

              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final visit = Visit.fromJson(responseData["data"] ?? responseData);

        return {"success": true, "data": visit};
      }

      return {
        "success": false,

        "error": responseData["error"] ?? "Failed to fetch visit details",
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // get patient notes
  Future<Map<String, dynamic>> getPatientNotes({
    required String visitId,
    required String institutionId,
  }) async {
    try {
      final token = _session.token;

      final uri = Uri.parse(
        '$baseUrl/patient-note/notes',
      ).replace(queryParameters: {'institution_id': institutionId,'visit_id': visitId});

      final response = await http
          .get(
            uri,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      print("Get Patient Notes Response: $responseData");

      if (response.statusCode == 200) {
        final List<dynamic> notesJson = responseData is List
            ? responseData
            : [];

        final notes = notesJson
            .map((e) => PatientNote.fromJson(e as Map<String, dynamic>))
            .toList();

        return {"success": true, "data": notes, "count": notes.length};
      }

      return {
        "success": false,
        "error": responseData is Map
            ? responseData["error"] ??
                  responseData["message"] ??
                  "Failed to fetch patient notes"
            : "Failed to fetch patient notes",
      };
    } catch (e) {
      print("Get Patient Notes Error: $e");

      return {"success": false, "error": e.toString()};
    }
  }

  // addCommentToNote
  Future<Map<String, dynamic>> addCommentToNote({
    required String noteId,
    required String comment,
    required String staffId,
  }) async {
    try {
      final token = _session.token;
      print("Adding comment to note $noteId by staff $staffId: $comment");

      final response = await http
          .post(
            Uri.parse('$baseUrl/patient-note/notes/comment'),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"comment": comment, "staff_id": staffId, "patient_note_id": noteId}),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final comment = StaffComment.fromJson(
          responseData["data"] ?? responseData,
        );

        return {"success": true, "data": comment};
      }

      return {
        "success": false,
        "error": responseData is Map
            ? responseData["error"] ??
                  responseData["message"] ??
                  "Failed to add comment"
            : "Failed to add comment",
      };
    } catch (e) {
      print("Add Comment Error: $e");

      return {"success": false, "error": e.toString()};
    }
  }
}
