import 'dart:convert';
import 'package:doctor_app/data/models/auth_models.dart';
import 'package:doctor_app/data/models/user_models.dart';
import 'package:doctor_app/services/api/auth_api.dart';
import 'package:doctor_app/services/isar/isar_service.dart';
import 'package:http/http.dart' as http;
import '../auth_models.dart';

class AuthApiWithIsar extends AuthApi {
  // Override the login method to include Isar functionality
  static Future<LoginResponse> loginStaffWithIsar({
    required String staffId,
    required String password,
  }) async {
    // Call the parent class method
    final response = await AuthApi.loginStaff(
      staffId: staffId,
      password: password,
    );

    if (response.needsLogicAnswer && response.logicQuestion != null) {
      // Save logic question to Isar
      await IsarService.saveLogicQuestion(
        userId: staffId,
        question: response.logicQuestion!,
        options: response.options?.cast<String>() ?? [],
        password: password,
      );
    }

    return response;
  }

  static Future<LogicVerifyResponse> verifyLogicAnswerWithIsar({
    required String staffId,
    required String password,
    required dynamic selectedOption,
    required String? logicQuestion,
  }) async {
    final response = await AuthApi.verifyLogicAnswer(
      staffId: staffId,
      password: password,
      selectedOption: selectedOption,
      logicQuestion: logicQuestion,
    );

    print('📥 Response received: token=${response.token}, user=$response');

    if (response.isAuthenticated && response.token != null) {
      // Check if we have user data in the response
      print(
        '👤 User data received: ${response.user?.firstName} ${response.user?.lastName}',
      );
      print('👤 Staff ID: ${response.user?.staffID}');
      print('👤 Email: ${response.user?.email}');
      print('👤 Role: ${response.user?.roleName}');
      print('👤 Department: ${response.user?.department}');
      print('👤 Institution: ${response.user?.institution}');

      // Convert StaffUser payload to Isar model.
      // The backend response body you showed looks like:
      // { firstName, lastName, email, phone_number, id, staffID, token, ... }
      // Your current mapping reads `response.user!.raw`, but then expects keys like
      // `firstName/lastName` etc inside that `raw`. The debug output shows nulls,
      // so we instead read from the decoded json map that exists in the response.

      final userRaw = (response.user!.raw is Map)
          ? (response.user!.raw as Map).cast<String, dynamic>()
          : <String, dynamic>{};

      // If the StaffUser wrapper doesn't expose the raw json properly,
      // fallback to the decoded map held by the wrapper.
      // This prevents saving null fields in Isar.
      final fallbackRaw = (response.user as dynamic).json is Map
          ? (response.user as dynamic).json as Map
          : null;

      final effectiveRaw = userRaw.isNotEmpty
          ? userRaw
          : (fallbackRaw is Map
                ? fallbackRaw.cast<String, dynamic>()
                : <String, dynamic>{});

      // If raw is present but doesn't contain the expected keys, try other common
      // shapes (some APIs wrap user under `user` or use snake_case keys).
      final firstName =
          (userRaw['firstName'] ??
                  userRaw['first_name'] ??
                  userRaw['givenName'])
              ?.toString();
      final lastName =
          (userRaw['lastName'] ?? userRaw['last_name'] ?? userRaw['familyName'])
              ?.toString();
      final email = (userRaw['email'] ?? userRaw['email_address'])?.toString();

      // Map institution from backend payload.
      // Backend sends `institution: {id, name, ...}` and also `institution_id` (snake_case).
      // Institution
      final instId =
          (userRaw['institution_id'] ?? userRaw['institutionId'])?.toString();
      final instObj = userRaw['institution'];
      final instObjMap = (instObj is Map)
          ? instObj.cast<String, dynamic>()
          : null;
      final instIdFromObj = instObjMap?['id']?.toString();
      final institutionName =
          (instObjMap?['name']?.toString() ?? userRaw['institution_name']?.toString());

      // Department
      final deptId =
          (userRaw['department_id'] ?? userRaw['departmentId'])?.toString();
      final deptObj = userRaw['department'];
      final deptObjMap = (deptObj is Map)
          ? deptObj.cast<String, dynamic>()
          : null;
      final deptIdFromObj = deptObjMap?['id']?.toString();
      final departmentName =
          (deptObjMap?['name']?.toString() ?? userRaw['department_name']?.toString());

      final userModel = UserModel()
        ..userId =
            (userRaw['id'] ??
                    userRaw['userId'] ??
                    userRaw['staffID'] ??
                    userRaw['staffId'] ??
                    userRaw['staff_id'])
                ?.toString() ??
            staffId
        ..staffID =
            (userRaw['staffID'] ?? userRaw['staffId'] ?? userRaw['staff_id'])
                ?.toString()
        ..token = response.token
        ..isLoggedIn = true
        ..lastLogin = DateTime.now()
        ..firstName = firstName
        ..lastName = lastName
        ..middleName = (userRaw['middleName'] ?? userRaw['middle_name'])
            ?.toString()
        ..email = email
        ..phoneNumber =
            (userRaw['phone_number'] ?? userRaw['phoneNumber'] ?? userRaw['phone'])
                ?.toString()
        // These are stored as names + ids in Isar (not Department objects).
        ..department = departmentName
        ..departmentId = (deptIdFromObj ?? deptId)?.toString()
        ..institutionId = (instIdFromObj ?? instId)?.toString()
        ..institution = institutionName
        ..adminId = (userRaw['admin_id'] ?? userRaw['adminId'])?.toString()
        ..role = null;
      // Log what we're saving
      print('💾 Saving user into Isar:');
      print('   userId=${userModel.userId}');
      print('   staffID=${userModel.staffID}');
      print('   firstName=${userModel.firstName}');
      print('   lastName=${userModel.lastName}');
      print('   email=${userModel.email}');

      await IsarService.saveUser(userModel);
      print('✅ User saved to Isar successfully');

      await IsarService.clearLogicQuestion(staffId);
    } else {
      print('❌ Authentication failed or token missing');
    }

    return response;
  }

  // Add this method to AuthApiWithIsar class
  static Future<UserModel?> getUserDetailsWithIsar({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await AuthApi.getUserDetails(
        userId: userId,
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;

        // Update user in Isar
        await IsarService.updateUserDetails(userId, userData);

        // Return the updated user
        return await IsarService.getUserByUserId(userId);
      }

      return null;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }
}
