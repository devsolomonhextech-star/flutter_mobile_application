import 'package:doctor_app/services/auth_models.dart';

import 'user_models.dart';

class LoginResponse {
  final String? token;
  final String? userId;
  final String? logicQuestion;
  final List<dynamic>? options;
  final String? message;

  LoginResponse({
    this.token,
    this.userId,
    this.logicQuestion,
    this.options,
    this.message,
  });

  bool get needsLogicAnswer =>
      logicQuestion != null && (options?.isNotEmpty ?? false);

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token']?.toString() ??
          json['accessToken']?.toString() ??
          json['access_token']?.toString(),
      userId: json['userId']?.toString() ??
          json['staffId']?.toString() ??
          json['id']?.toString(),
      logicQuestion: json['logic_question']?.toString(),
      options: json['options'] is List ? (json['options'] as List) : null,
      message: json['message']?.toString() ?? json['error']?.toString(),
    );
  }
}

class LogicVerifyResponse {
  final String? token;
  final String? userId;
  final String? message;
  final StaffUser? user;

  LogicVerifyResponse({
    this.token,
    this.userId,
    this.message,
    this.user,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  factory LogicVerifyResponse.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];

    return LogicVerifyResponse(
      token: json['token']?.toString() ??
          json['accessToken']?.toString() ??
          json['access_token']?.toString(),
      userId: json['userId']?.toString() ??
          json['staffId']?.toString() ??
          json['id']?.toString() ??
          (userRaw is Map
              ? (userRaw['id']?.toString() ?? userRaw['staffID']?.toString())
              : null),
      message: json['message']?.toString() ?? json['error']?.toString(),
      user: userRaw == null ? null : StaffUser.fromJson(userRaw),
    );
  }
}