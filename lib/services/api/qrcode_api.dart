import 'dart:convert';

import 'package:doctor_app/services/session_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class QRCodeApi {
  static const String baseUrl = 'http://localhost:5001/api/v1';

  static final SessionService _session = Get.find<SessionService>();

  static String _authHeaderValue() {
    final token = _session.token;
    if (token == null || token.isEmpty) return '';
    return 'Bearer $token';
  }

  /// Backend: attendance_controller.scanQrCode expects { qr_code, staffId }
  static Future<http.Response> scanQRCode({
    required String qrCodeData,
    required String staffId,
  }) async {
    final url = Uri.parse('$baseUrl/attendance/scan');

    return http.post(
      url,
      headers: {
        if (_authHeaderValue().isNotEmpty) 'Authorization': _authHeaderValue(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // IMPORTANT: backend destructures qr_code (not qrCodeData)
        'qr_code': qrCodeData,
        'staffId': staffId,
      }),
    );
  }

  /// Backend: GET /attendance/get-staff-qrcode/:staffId
  static Future<Map<String, dynamic>> getStaffQRCode({
    required String staffId,
  }) async {
    final url = Uri.parse('$baseUrl/attendance/get-staff-qrcode/$staffId');

    final response = await http.get(
      url,
      headers: {
        if (_authHeaderValue().isNotEmpty) 'Authorization': _authHeaderValue(),
      },
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded is Map && decoded['message'] != null
          ? decoded['message']
          : 'Failed to fetch staff QR code');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format');
    }

    return decoded;
  }
}





