import 'package:doctor_app/data/models/user_models.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

class IsarService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([UserModelSchema], directory: dir.path);
  }

  // User operations
  static Future<void> saveUser(UserModel user) async {
    await isar.writeTxn(() async {
      final existingUser = await isar.userModels
          .where()
          .userIdEqualTo(user.userId)
          .findFirst();

      if (existingUser != null) {
        user.id = existingUser.id;
      }

      print('💾 Putting user into Isar:');
      print('   userId=${user.userId} staffID=${user.staffID}');
      print(
        '   firstName=${user.firstName} lastName=${user.lastName} email=${user.email}',
      );
      await isar.userModels.put(user);

      // Log what was saved
      final saved = await isar.userModels.get(user.id);
      print('📂 Saved user to Isar (after put):');
      print('   ID: ${saved?.id}');
      print('   UserID: ${saved?.userId}');
      print('   FirstName: ${saved?.firstName}');
      print('   LastName: ${saved?.lastName}');
      print('   StaffID: ${saved?.staffID}');
      print('   Email: ${saved?.email}');
      print('   Token: ${saved?.token?.substring(0, 20)}...');
    });
  }

  static Future<void> updateUserToken(String userId, String token) async {
    await isar.writeTxn(() async {
      final user = await isar.userModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();

      if (user != null) {
        user.token = token;
        user.isLoggedIn = true;
        user.lastLogin = DateTime.now();
        await isar.userModels.put(user);
      }
    });
  }

  static Future<UserModel?> getLoggedInUser() async {
    return await isar.userModels.where().isLoggedInEqualTo(true).findFirst();
  }

  static Future<UserModel?> getUserByUserId(String userId) async {
    return await isar.userModels.where().userIdEqualTo(userId).findFirst();
  }

  static Future<void> logoutUser() async {
    await isar.writeTxn(() async {
      final user = await isar.userModels
          .where()
          .isLoggedInEqualTo(true)
          .findFirst();

      if (user != null) {
        user.isLoggedIn = false;
        user.token = null;
        await isar.userModels.put(user);
      }
    });
  }

  static Future<void> clearAllUsers() async {
    await isar.writeTxn(() async {
      await isar.userModels.clear();
    });
  }

  static Future<void> deleteUser(String userId) async {
    await isar.writeTxn(() async {
      final user = await isar.userModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();

      if (user != null) {
        await isar.userModels.delete(user.id);
      }
    });
  }

  // Save logic question temporarily for verification
  static Future<void> saveLogicQuestion({
    required String userId,
    required String question,
    required List<String> options,
    required String password,
  }) async {
    await isar.writeTxn(() async {
      final user = await isar.userModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();

      if (user != null) {
        user.logicQuestion = question;
        user.logicOptions = options.join(',');
        user.pendingPassword = password;
        await isar.userModels.put(user);
      } else {
        // Create new user with logic question
        final newUser = UserModel()
          ..userId = userId
          ..logicQuestion = question
          ..logicOptions = options.join(',')
          ..pendingPassword = password
          ..isLoggedIn = false;
        await isar.userModels.put(newUser);
      }
    });
  }

  static Future<void> clearLogicQuestion(String userId) async {
    await isar.writeTxn(() async {
      final user = await isar.userModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();

      if (user != null) {
        user.logicQuestion = null;
        user.logicOptions = null;
        user.pendingPassword = null;
        await isar.userModels.put(user);
      }
    });
  }

  // Update user details from backend response
  static Future<void> updateUserDetails(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await isar.writeTxn(() async {
      final user = await isar.userModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();

      if (user != null) {
        // Update fields based on backend response
        user.username =
            userData['username']?.toString() ??
            userData['user_name']?.toString() ??
            user.username;
        user.email =
            userData['email']?.toString() ??
            userData['email_address']?.toString() ??
            user.email;
        user.firstName =
            userData['firstName']?.toString() ??
            userData['first_name']?.toString() ??
            userData['givenName']?.toString() ??
            user.firstName;
        user.lastName =
            userData['lastName']?.toString() ??
            userData['last_name']?.toString() ??
            userData['familyName']?.toString() ??
            user.lastName;
        user.phoneNumber =
            userData['phoneNumber']?.toString() ??
            userData['phone_number']?.toString() ??
            userData['phone']?.toString() ??
            user.phoneNumber;

        // role/department/institution can be either strings/ids or objects.
        final roleVal = userData['role'];
        user.role = roleVal is Map
            ? roleVal['name']?.toString()
            : roleVal?.toString();
        final deptVal = userData['department'];
        user.department = deptVal is Map
            ? deptVal['name']?.toString()
            : deptVal?.toString();
        final instVal = userData['institution'];
        user.institution = instVal is Map
            ? instVal['name']?.toString()
            : instVal?.toString();

        final ugVal = userData['userGroup'] ?? userData['user_group'];
        user.userGroup = ugVal is Map
            ? ugVal['name']?.toString()
            : ugVal?.toString();

        // Keep existing values if backend doesn't return them.
        user.role = user.role ?? user.role;
        user.department = user.department ?? user.department;
        user.institution = user.institution ?? user.institution;
        user.userGroup = user.userGroup ?? user.userGroup;
        user.updatedAt = DateTime.now();

        await isar.userModels.put(user);
      }
    });
  }
}
