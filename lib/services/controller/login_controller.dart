import 'package:doctor_app/app/routes/app_routes.dart';
import 'package:doctor_app/services/api/auth_service.dart';
import 'package:doctor_app/services/isar/isar_service.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';


class LoginController extends GetxController {
  final SessionService session;

  LoginController(this.session);

  final staffIdController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    if (session.isAuthenticated.value) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> login() async {
    final staffId = staffIdController.text.trim();
    final password = passwordController.text;

    if (staffId.isEmpty || password.isEmpty) {
      errorMessage.value = 'Staff ID and password are required';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Use the persistence version that saves to Isar
      final res = await AuthService.loginWithPersistence(
        staffId: staffId,
        password: password,
      );

      if (res.needsLogicAnswer) {
        final logicStaffId = res.userId ?? staffId;
        
        // Retrieve saved logic question from Isar if not in response
        final savedUser = await IsarService.getUserByUserId(logicStaffId);
        
        Get.toNamed('/logic-answer', arguments: {
          'staffId': logicStaffId,
          'password': password,
          'logicQuestion': res.logicQuestion ?? savedUser?.logicQuestion,
          'options': res.options ?? savedUser?.logicOptions,
          'staffID': logicStaffId,
        });
        return;
      }

      if (res.isAuthenticated && res.token != null) {
        await session.saveSession(
          token: res.token!,
          userId: res.userId ?? staffId,
        );
        Get.offAllNamed(AppRoutes.home);
      } else {
        errorMessage.value = 'Authentication failed. Please try again.';
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  void forgotPassword() {
    Get.toNamed('/forgot-password');
  }

  void goToRegister() {
    Get.toNamed('/register');
  }

  @override
  void onClose() {
    staffIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}