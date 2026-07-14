// lib/services/api/visit_api.dart

import 'dart:convert';
import 'package:doctor_app/data/constants/urls.dart';
import 'package:doctor_app/data/models/visit_models.dart';
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
    ).replace(
      queryParameters: queryParameters,
    );

    print("GET ACTIVE VISITS URL: $uri");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(
      const Duration(seconds: 30),
    );


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

      } 
      
      else if (data is Map && data["items"] is List) {

        visitsJson = data["items"];

      }


      print(
        "visitsJson runtimeType: ${visitsJson.runtimeType}",
      );


      if (visitsJson.isNotEmpty) {
        print(
          "first visit element runtimeType: ${visitsJson.first.runtimeType}",
        );
      }


      final List<Visit> visits = visitsJson
          .map(
            (json) => Visit.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();



      return {
        "success": true,
        "data": visits,
        "count": responseData is Map
            ? responseData["count"] ?? visits.length
            : visits.length,
        "filters": responseData is Map
            ? responseData["filters"] ?? {}
            : {},
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

    print(
      "Get Active Visits Error: $e",
    );


    return {
      "success": false,
      "error": e.toString(),
    };
  }
}




  Future<Map<String,dynamic>> getVisitDetails({
    required String visitId,
  }) async {


    try {

      final token = _session.token;


      final response = await http.get(

        Uri.parse(
          '$baseUrl/records/visits/$visitId',
        ),

        headers: {

          "Authorization": "Bearer $token",

          "Content-Type": "application/json",

        },

      ).timeout(
        const Duration(seconds:30),
      );



      final responseData =
          jsonDecode(response.body);



      if(response.statusCode == 200){


        final visit =
            Visit.fromJson(
              responseData["data"] ?? responseData,
            );


        return {

          "success": true,

          "data": visit,

        };

      }


      return {

        "success": false,

        "error": responseData["error"] ??
            "Failed to fetch visit details",

      };


    }catch(e){


      return {

        "success": false,

        "error": e.toString(),

      };

    }

  }





  Future<Map<String,dynamic>> getDepartmentVisits({

    required String departmentId,

    required String institutionId,

  }){


    return getActiveVisits(

      institutionId: institutionId,

      departmentId: departmentId,

    );

  }


}