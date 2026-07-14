import 'package:doctor_app/data/models/user_models.dart';
import 'package:doctor_app/services/api/auth_service.dart';
import 'package:doctor_app/services/isar/isar_service.dart';
import 'package:get/get.dart';

extension UserModelExtraData on UserModel {
  static final Expando<Map<String, dynamic>> _extraData = Expando<Map<String, dynamic>>();

  set extraData(Map<String, dynamic>? value) {
    _extraData[this] = value;
  }

  Map<String, dynamic>? get extraData => _extraData[this];
}

class SessionService extends GetxService {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;

  Future<SessionService> init() async {
    await loadSession();
    return this;
  }

  Future<void> loadSession() async {
    final user = await IsarService.getLoggedInUser();
    if (user != null && user.token != null && user.token!.isNotEmpty) {
      currentUser.value = user;
      isAuthenticated.value = true;
    } else {
      isAuthenticated.value = false;
    }
  }

  Future<void> saveSession({
    required String token,
    required String? userId,
    Map<String, dynamic>? userData,
  }) async {
    final user = await IsarService.getUserByUserId(userId ?? '');

    if (user != null) {
      user.token = token;
      user.isLoggedIn = true;
      user.lastLogin = DateTime.now();
      await IsarService.saveUser(user);
      currentUser.value = user;
    } else {
      final newUser = UserModel()
        ..userId = userId
        ..token = token
        ..isLoggedIn = true
        ..lastLogin = DateTime.now();

      if (userData != null) {
        print('User data received: $userData'); // Debug log
        newUser.username = userData['username']?.toString();
        newUser.email = userData['email']?.toString();
        newUser.firstName = userData['firstName']?.toString();
        newUser.lastName = userData['lastName']?.toString();
        newUser.phoneNumber = userData['phoneNumber']?.toString();
        newUser.role = userData['role']?.toString();
        newUser.department = userData['department']?.toString();
        newUser.institution = userData['institution']?.toString();
        newUser.staffId = userData['staffId']?.toString();
        newUser.extraData = userData;
        // institution_id may come from nested institution OR from flat field.
        newUser.institutionId =
            userData['institution']?['id']?.toString() ??
            userData['institution_id']?.toString() ??
            userData['id']?.toString();

        // department_id may come from nested department OR from flat field.
        newUser.departmentId =
            userData['department']?['id']?.toString() ??
            userData['department_id']?.toString() ??
            newUser.departmentId;
      }

      // Always persist the extracted IDs so controllers can read them from Isar.
      await IsarService.saveUser(newUser);
      currentUser.value = newUser;

      print('Saved session institutionId=${newUser.institutionId} departmentId=${newUser.departmentId}');
    }

    isAuthenticated.value = true;
  }

  Future<void> logout() async {
    await IsarService.logoutUser();
    currentUser.value = null;
    isAuthenticated.value = false;
  }

  Future<void> updateUserDetails(Map<String, dynamic> userData) async {
    final userId = currentUser.value?.userId;
    if (userId != null) {
      await IsarService.updateUserDetails(userId, userData);
      await loadSession(); // Reload session
    }
  }

  // Add this method to SessionService
  Future<void> fetchAndUpdateUserDetails() async {
    final userId = currentUser.value?.userId;
    final token = currentUser.value?.token;

    if (userId != null && token != null) {
      try {
        final user = await AuthService.getUserDetails(
          userId: userId,
          token: token,
        );
        if (user != null) {
          currentUser.value = user;
        }
      } catch (e) {
        print('Failed to fetch user details: $e');
      }
    }
  }

  String? get token => currentUser.value?.token;
  String? get userId => currentUser.value?.userId;
  UserModel? get user => currentUser.value;
}
