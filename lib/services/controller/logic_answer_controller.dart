import 'package:doctor_app/services/api/auth_api_with_isar.dart.dart';
import 'package:doctor_app/services/isar/isar_service.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';


class LogicAnswerController extends GetxController {
  final SessionService session;
  
  final RxString selectedOption = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  
  late final String staffId;
  late final String password;
  late final String logicQuestion;
  late final List<dynamic> options;
  
  LogicAnswerController(this.session);
  
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    staffId = args['staffId'] ?? args['staffID'] ?? '';
    password = args['password'] ?? '';
    logicQuestion = args['logicQuestion'] ?? '';
    options = args['options'] ?? [];
    
    if (staffId.isEmpty || logicQuestion.isEmpty || options.isEmpty) {
      Get.back();
      Get.snackbar(
        'Error',
        'Invalid logic question data. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void selectOption(String option) {
    selectedOption.value = option;
  }
  
  Future<void> verifyAnswer() async {
    if (selectedOption.value.isEmpty) {
      errorMessage.value = 'Please select an answer';
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final res = await AuthApiWithIsar.verifyLogicAnswerWithIsar(
        staffId: staffId,
        password: password,
        selectedOption: selectedOption.value,
        logicQuestion: logicQuestion,
      );
      
      if (res.isAuthenticated && res.token != null) {
        // Session is already saved in the API call
        await session.saveSession(
          token: res.token!,
          userId: res.userId ?? staffId,
          userData: res.user?.raw,
        );
        Get.offAllNamed('/home');
      } else {
        errorMessage.value = res.message ?? 'Verification failed. Please try again.';
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      
      // If verification fails, clear the stored logic question
      await IsarService.clearLogicQuestion(staffId);
    } finally {
      isLoading.value = false;
    }
  }
  
  void goBack() {
    Get.back();
  }
}