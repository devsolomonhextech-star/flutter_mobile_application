import 'dart:convert';
import 'package:doctor_app/services/auth_models.dart';
import 'package:isar/isar.dart';

part 'user_models.g.dart';

@Collection()
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? userId;

  String? staffID;
  String? staffId;
  String? token;
  String? email;
  String? username;
  String? firstName;
  String? lastName;
  String? middleName;
  String? phoneNumber;
  String? role;
  String? roleId;
  String? department;
  String? departmentId;
  String? institution;
  String? institutionId;
  String? userGroup;
  String? adminId;
  String? specialization;
  String? qualification;
  String? bio;
  String? gender;
  String? profilePic;
  String? fcmToken;

  @Index()
  bool? isLoggedIn;
  bool? isActive;
  bool? isVerified;

  DateTime? lastLogin;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? dateOfBirth;
  DateTime? tokenExpiration;

  // Logic question related fields
  String? logicQuestion;
  String? logicOptions; // Store as JSON string
  String? pendingPassword;

  // Store extra data as JSON string
  String? extraDataJson;

  // Helper methods
  List<String>? getLogicOptions() {
    if (logicOptions == null) return null;
    try {
      return List<String>.from(jsonDecode(logicOptions!));
    } catch (e) {
      return null;
    }
  }

  void setLogicOptions(List<String>? options) {
    logicOptions = options != null ? jsonEncode(options) : null;
  }

  Map<String, dynamic>? getExtraData() {
    if (extraDataJson == null) return null;
    try {
      return jsonDecode(extraDataJson!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  void setExtraData(Map<String, dynamic>? data) {
    extraDataJson = data != null ? jsonEncode(data) : null;
  }

  // Convert from StaffUser (or decoded JSON that matches the backend user shape)
  static UserModel fromStaffUser(StaffUser staffUser) {
    final s = staffUser as dynamic;
    final model = UserModel();

    // Try to extract a JSON map from the wrapper.
    Map<String, dynamic>? rawMap;
    try {
      final dynamic maybeRaw = s.raw ?? s.data ?? s.payload ?? s;
      if (maybeRaw is Map<String, dynamic>) {
        rawMap = maybeRaw;
      } else if (maybeRaw is Map) {
        rawMap = maybeRaw.cast<String, dynamic>();
      } else {
        final dynamic toJsonVal = (s.toJson is Function) ? s.toJson() : null;
        if (toJsonVal is Map<String, dynamic>) rawMap = toJsonVal;
        if (toJsonVal is Map) rawMap = toJsonVal.cast<String, dynamic>();
      }
    } catch (_) {
      rawMap = null;
    }

    // (helpers omitted)

    Map<String, dynamic>? pickNestedMap(Object? v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.cast<String, dynamic>();
      return null;
    }

    final userIdCandidate = rawMap != null
        ? (rawMap!['id'] ??
              rawMap!['userId'] ??
              rawMap!['staffID'] ??
              rawMap!['staffId'] ??
              rawMap!['staff_id'])
        : null;

    model.userId =
        userIdCandidate?.toString() ??
        s.id?.toString() ??
        s.userId?.toString() ??
        s.staffID?.toString() ??
        s.staffId?.toString() ??
        s.staff_id?.toString();
    model.staffID =
        (rawMap != null
                ? (rawMap!['staffID'] ??
                      rawMap!['staffId'] ??
                      rawMap!['staff_id'])
                : null)
            ?.toString() ??
        s.staffID?.toString() ??
        s.staffId?.toString() ??
        s.staff_id?.toString();
    model.staffId = model.staffID;

    // Token
    model.token =
        (rawMap != null
                ? (rawMap!['token'] ??
                      rawMap!['accessToken'] ??
                      rawMap!['access_token'] ??
                      rawMap!['authToken'] ??
                      rawMap!['auth_token'])
                : null)
            ?.toString() ??
        s.token?.toString() ??
        s.accessToken?.toString() ??
        s.authToken?.toString() ??
        s.access_token?.toString();

    // Basic user fields
    model.firstName =
        (rawMap != null
                ? (rawMap!['firstName'] ??
                      rawMap!['first_name'] ??
                      rawMap!['givenName'] ??
                      rawMap!['first'])
                : null)
            ?.toString() ??
        s.firstName?.toString() ??
        s.first_name?.toString() ??
        s.givenName?.toString() ??
        s.first?.toString();
    model.lastName =
        (rawMap != null
                ? (rawMap!['lastName'] ??
                      rawMap!['last_name'] ??
                      rawMap!['familyName'] ??
                      rawMap!['last'])
                : null)
            ?.toString() ??
        s.lastName?.toString() ??
        s.last_name?.toString() ??
        s.familyName?.toString() ??
        s.last?.toString();
    model.middleName =
        (rawMap != null
                ? (rawMap!['middleName'] ?? rawMap!['middle_name'])
                : null)
            ?.toString() ??
        s.middleName?.toString() ??
        s.middle_name?.toString();

    model.email =
        (rawMap != null ? (rawMap!['email'] ?? rawMap!['email_address']) : null)
            ?.toString() ??
        s.email?.toString() ??
        s.email_address?.toString();
    model.username =
        (rawMap != null ? (rawMap!['username'] ?? rawMap!['user_name']) : null)
            ?.toString() ??
        s.username?.toString() ??
        s.user_name?.toString();
    model.phoneNumber =
        (rawMap != null
                ? (rawMap!['phone_number'] ??
                      rawMap!['phoneNumber'] ??
                      rawMap!['phone'])
                : null)
            ?.toString() ??
        s.phoneNumber?.toString() ??
        s.phone_number?.toString() ??
        s.phone?.toString();

    // Role/department/institution are sometimes objects in JSON, sometimes ids/strings.
    final roleObj = pickNestedMap(rawMap != null ? rawMap!['role'] : null);
    model.role =
        (roleObj != null ? roleObj['name'] : null)?.toString() ??
        rawMap?['role']?.toString() ??
        s.role?.toString();
    final roleIdObj = roleObj != null ? roleObj['id'] : null;
    model.roleId =
        roleIdObj?.toString() ??
        rawMap?['role_id']?.toString() ??
        s.roleId?.toString() ??
        s.role_id?.toString();

    final deptObj = pickNestedMap(
      rawMap != null ? rawMap!['department'] : null,
    );
    model.department =
        (deptObj != null ? deptObj['name'] : null)?.toString() ??
        rawMap?['department']?.toString() ??
        s.department?.toString();
    model.departmentId =
        (deptObj != null ? deptObj['id'] : null)?.toString() ??
        rawMap?['department_id']?.toString() ??
        s.departmentId?.toString() ??
        s.department_id?.toString();

    final instObj = pickNestedMap(
      rawMap != null ? rawMap!['institution'] : null,
    );
    model.institution =
        (instObj != null ? instObj['name'] : null)?.toString() ??
        rawMap?['institution']?.toString() ??
        s.institution?.toString();
    model.institutionId =
        (instObj != null ? instObj['id'] : null)?.toString() ??
        rawMap?['id']?.toString() ??
        s.institutionId?.toString() ??
        s.institution_id?.toString();

    final userGroupObj = pickNestedMap(
      rawMap != null ? rawMap!['user_group'] ?? rawMap!['userGroup'] : null,
    );
    model.userGroup =
        (userGroupObj != null ? userGroupObj['name'] : null)?.toString() ??
        rawMap?['userGroup']?.toString() ??
        rawMap?['user_group']?.toString() ??
        s.userGroup?.toString();

    model.adminId =
        (rawMap != null ? (rawMap!['admin_id'] ?? rawMap!['adminId']) : null)
            ?.toString() ??
        s.admin_id?.toString() ??
        s.adminId?.toString();

    // Extra profile fields
    model.logicQuestion =
        rawMap?['logic_question']?.toString() ?? s.logicQuestion?.toString();
    model.logicOptions =
        rawMap?['logicOptions']?.toString() ?? s.logicOptions?.toString();

    model.specialization =
        rawMap?['specialization']?.toString() ?? s.specialization?.toString();
    model.qualification =
        rawMap?['qualification']?.toString() ?? s.qualification?.toString();
    model.bio = rawMap?['bio']?.toString() ?? s.bio?.toString();
    model.gender = rawMap?['gender']?.toString() ?? s.gender?.toString();
    model.profilePic =
        rawMap?['profile_pic']?.toString() ??
        rawMap?['profilePic']?.toString() ??
        s.profilePic?.toString() ??
        s.avatar?.toString();
    model.fcmToken =
        rawMap?['fcm_token']?.toString() ??
        rawMap?['fcmToken']?.toString() ??
        s.fcmToken?.toString() ??
        s.fcm_token?.toString();

    model.isActive =
        (rawMap?['is_active'] ??
                rawMap?['isActive'] ??
                s.isActive ??
                s.is_active)
            as bool?;
    model.isVerified =
        (rawMap?['is_verified'] ??
                rawMap?['isVerified'] ??
                s.isVerified ??
                s.is_verified)
            as bool?;

    model.lastLogin = rawMap?['last_login'] != null
        ? DateTime.tryParse(rawMap!['last_login'].toString())
        : (s.lastLogin as DateTime? ?? s.last_login as DateTime?);
    model.createdAt = rawMap?['created_at'] != null
        ? DateTime.tryParse(rawMap!['created_at'].toString())
        : (s.createdAt as DateTime? ?? s.created_at as DateTime?);
    model.updatedAt = rawMap?['updated_at'] != null
        ? DateTime.tryParse(rawMap!['updated_at'].toString())
        : (s.updatedAt as DateTime? ?? s.updated_at as DateTime?);

    model.tokenExpiration = rawMap?['token_expiration'] != null
        ? DateTime.tryParse(rawMap!['token_expiration'].toString())
        : null;

    model.isLoggedIn = true;

    // Store any remaining/complete payload in extraData.
    if (rawMap != null) {
      model.setExtraData(rawMap);
    }

    return model;
  }
}
