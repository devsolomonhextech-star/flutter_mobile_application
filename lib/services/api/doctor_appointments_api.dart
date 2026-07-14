import 'dart:convert';

import 'package:doctor_app/data/models/doctor_appointment_model.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:http/http.dart' as http;



class DoctorAppointmentsApi {
  static const String baseUrl = 'http://localhost:5001/api/v1';

  static Map<String, String> _headers(SessionService session) {
    final token = session.token;
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

static Future<List<DoctorAppointment>> getAppointmentsByDoctorId({
  required SessionService session,
  required String institutionId,
  required String doctorId,
}) async {
  final url = Uri.parse(
    '$baseUrl/appointment/doctor'
    '?institution_id=${Uri.encodeQueryComponent(institutionId)}'
    '&doctor_id=${Uri.encodeQueryComponent(doctorId)}',
  );

  final resp = await http.get(
    url,
    headers: _headers(session),
  );

  final body = _decodeBody(resp);

  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw Exception(
      'getAppointmentsByDoctorId failed (${resp.statusCode}): '
      '${body['message'] ?? body['error'] ?? body}',
    );
  }


  final List<dynamic> list = body is List
      ? body
      : (body['data'] ?? body['appointments'] ?? []);


  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => DoctorAppointment.fromJson(e))
      .toList();
}

  static Future<List<DoctorAppointment>> getUpcomingAppointmentsByDoctorId({
    required SessionService session,
    required String institutionId,
    required String doctorId,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$baseUrl/appointments/doctor/upcoming?institution_id=${Uri.encodeQueryComponent(institutionId)}&doctor_id=${Uri.encodeQueryComponent(doctorId)}&limit=$limit',
    );

    final resp = await http.get(url, headers: _headers(session));
    final body = _decodeBody(resp);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'getUpcomingAppointmentsByDoctorId failed (${resp.statusCode}): ${body['message'] ?? body['error'] ?? body}',
      );
    }

    final list = body is List ? body : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => DoctorAppointment.fromJson(e))
        .toList();
  }

  static Future<void> deleteAppointment({
    required SessionService session,
    required String institutionId,
    required String appointmentId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/appointments/delete?id=${Uri.encodeQueryComponent(appointmentId)}&institution_id=${Uri.encodeQueryComponent(institutionId)}',
    );

    final resp = await http.delete(url, headers: _headers(session));
    final body = _decodeBody(resp);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'deleteAppointment failed (${resp.statusCode}): ${body['message'] ?? body['error'] ?? body}',
      );
    }
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

