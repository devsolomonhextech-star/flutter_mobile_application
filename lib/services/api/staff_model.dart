// lib/data/models/staff_model.dart

import 'package:doctor_app/data/models/institution_models.dart';
import 'package:doctor_app/data/models/role_model.dart';
import 'package:doctor_app/data/models/visit_related_models.dart';

class Staff {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? email;
  final String? phoneNumber;
  final String? institutionId;
  final String? adminId;
  final String? departmentId;
  final String? roleId;
  final String? token;
  final String? staffID;
  final String? profilePic;
  final String? roleManager;

  final DateTime? tokenExpiration;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  final bool? isIncharge;
  final bool? hasFaceRegistered;

  final List<dynamic>? permissions;

  final Institution? institution;
  final Department? department;
  final Role? role;

  Staff({
    this.id,
    this.firstName,
    this.lastName,
    this.middleName,
    this.email,
    this.phoneNumber,
    this.institutionId,
    this.adminId,
    this.departmentId,
    this.roleId,
    this.token,
    this.staffID,
    this.profilePic,
    this.roleManager,
    this.tokenExpiration,
    this.createdAt,
    this.lastLogin,
    this.isIncharge,
    this.hasFaceRegistered,
    this.permissions,
    this.institution,
    this.department,
    this.role,
  });

  String get fullName {
    return [
      firstName,
      middleName,
      lastName,
    ].where((e) => e != null && e.isNotEmpty).join(' ');
  }

  String get initials {
    final first =
        firstName?.isNotEmpty == true ? firstName![0] : '';

    final last =
        lastName?.isNotEmpty == true ? lastName![0] : '';

    return '$first$last'.toUpperCase();
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json["id"],

      firstName: json["firstName"],

      lastName: json["lastName"],

      middleName: json["middleName"],

      email: json["email"],

      phoneNumber: json["phone_number"],

      institutionId: json["institution_id"],

      adminId: json["admin_id"],

      departmentId: json["department_id"],

      roleId: json["role_id"],

      token: json["token"],

      staffID: json["staffID"],

      profilePic: json["profile_pic"],

      roleManager: json["role_manager"],

      tokenExpiration: json["token_expiration"] != null
          ? DateTime.tryParse(
              json["token_expiration"],
            )
          : null,

      createdAt: json["created_at"] != null
          ? DateTime.tryParse(
              json["created_at"],
            )
          : null,

      lastLogin: json["last_login"] != null
          ? DateTime.tryParse(
              json["last_login"],
            )
          : null,

      isIncharge: json["is_incharge"],

      hasFaceRegistered:
          json["has_face_registered"],

      permissions:
          json["permissions"] as List<dynamic>?,

      institution: json["institution"] != null
          ? Institution.fromJson(
              json["institution"],
            )
          : null,

      department: json["department"] != null
          ? Department.fromJson(
              json["department"],
            )
          : null,

      role: json["role"] != null
          ? Role.fromJson(
              json["role"],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "firstName": firstName,
      "lastName": lastName,
      "middleName": middleName,
      "email": email,
      "phone_number": phoneNumber,
      "institution_id": institutionId,
      "admin_id": adminId,
      "department_id": departmentId,
      "role_id": roleId,
      "token": token,
      "staffID": staffID,
      "profile_pic": profilePic,
      "role_manager": roleManager,
      "token_expiration":
          tokenExpiration?.toIso8601String(),
      "created_at":
          createdAt?.toIso8601String(),
      "last_login":
          lastLogin?.toIso8601String(),
      "is_incharge": isIncharge,
      "has_face_registered":
          hasFaceRegistered,
      "permissions": permissions,
      "institution": institution?.toJson(),
      "department": department?.toJson(),
      "role": role?.toString(),
    };
  }
}