import 'package:doctor_app/data/models/auth_models.dart';
import 'package:doctor_app/data/models/user_models.dart';
import 'package:doctor_app/services/api/auth_api_with_isar.dart.dart';

import 'auth_api.dart';
import '../isar/isar_service.dart';

class AuthService {
  // Use this for standard login without Isar
  static Future<LoginResponse> loginStandard({
    required String staffId,
    required String password,
  }) async {
    return await AuthApi.loginStaff(staffId: staffId, password: password);
  }

  // Use this for login with Isar persistence
  static Future<LoginResponse> loginWithPersistence({
    required String staffId,
    required String password,
  }) async {
    return await AuthApiWithIsar.loginStaffWithIsar(
      staffId: staffId,
      password: password,
    );
  }

  // Use this for logic verification with Isar persistence
  static Future<LogicVerifyResponse> verifyLogicWithPersistence({
    required String staffId,
    required String password,
    required dynamic selectedOption,
    required String? logicQuestion,
  }) async {
    return await AuthApiWithIsar.verifyLogicAnswerWithIsar(
      staffId: staffId,
      password: password,
      selectedOption: selectedOption,
      logicQuestion: logicQuestion,
    );
  }

  // Add this method to AuthService class
  static Future<UserModel?> getUserDetails({
    required String userId,
    required String token,
  }) async {
    return await AuthApiWithIsar.getUserDetailsWithIsar(
      userId: userId,
      token: token,
    );
  }
  
}
