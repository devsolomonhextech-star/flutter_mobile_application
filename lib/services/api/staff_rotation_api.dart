import 'dart:convert';

import 'package:doctor_app/services/session_service.dart';
import 'package:http/http.dart' as http;

class StaffShift {
  final String day;
  final String shift;
  final String startTime;
  final String endTime;

  const StaffShift({
    required this.day,
    required this.shift,
    required this.startTime,
    required this.endTime,
  });

  factory StaffShift.fromJson(Map<String, dynamic> json) {
    return StaffShift(
      day: json['day']?.toString() ?? '',
      shift: json['shift']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }
}

class StaffRotationApi {
  StaffRotationApi({this.baseUrl = 'http://localhost:5001/api/v1'});

  final String baseUrl;

  Future<List<StaffShift>> fetchStaffShifts({
    required SessionService sessionService,
  }) async {
    final staffId = sessionService.user?.staffId ?? sessionService.userId;
    if (staffId == null || staffId.toString().isEmpty) {
      throw Exception('staffId not found in session');
    }

    final token = sessionService.token;
    final url = Uri.parse('$baseUrl/shifts/staff-shifts/$staffId');

    final resp = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(resp.body);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Failed to fetch shifts';
      throw Exception(msg);
    }

    // Backend may return either:
    // 1) { shifts: [...] }
    // 2) [...] (direct list)
    final dynamic dataShifts = decoded is Map ? decoded['shifts'] : decoded;
    if (dataShifts is! List) return <StaffShift>[];

    return dataShifts
        .whereType<Map<String, dynamic>>()
        .map((e) => StaffShift.fromJson(e))
        .toList();
  }
}
