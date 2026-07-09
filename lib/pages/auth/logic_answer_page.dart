import 'package:doctor_app/services/api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api/auth_api_with_isar.dart.dart';
import '../../services/session_service.dart';
import '../../app/routes/app_routes.dart';

class LogicAnswerPage extends StatefulWidget {
  const LogicAnswerPage({super.key});

  @override
  State<LogicAnswerPage> createState() => _LogicAnswerPageState();
}

class _LogicAnswerPageState extends State<LogicAnswerPage> {
  final SessionService session = Get.find<SessionService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  String? selected;

  String get staffId =>
      (Get.arguments?['staffId'] ?? Get.arguments?['staffID']).toString();
  String get password => (Get.arguments?['password']).toString();
  String get logicQuestion =>
      (Get.arguments?['logicQuestion'] ?? Get.arguments?['logic_question'])
          .toString();
  List<dynamic> get options => (Get.arguments?['options'] as List?) ?? [];

  // Helper to get display value from option
  String getDisplayValue(dynamic opt) {
    if (opt is String) return opt;
    if (opt is int) return opt.toString();
    if (opt is Map) return opt['label']?.toString() ?? opt['value']?.toString() ?? opt.toString();
    return opt.toString();
  }

  // Helper to get actual value from option
  dynamic getOptionValue(dynamic opt) {
    if (opt is String) return opt;
    if (opt is int) return opt;
    if (opt is Map) return opt['value'] ?? opt['label'] ?? opt;
    return opt;
  }

  Future<void> verify() async {
    if (selected == null) {
      errorMessage.value = 'Please select an answer';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Find the selected option's value
      final selectedOption = options.firstWhere(
        (opt) {
          if (opt is String) return opt == selected;
          if (opt is int) return opt.toString() == selected;
          if (opt is Map) {
            final val = opt['value'] ?? opt['label'] ?? opt;
            return val.toString() == selected;
          }
          return opt.toString() == selected;
        },
        orElse: () => null,
      );

      if (selectedOption == null) {
        errorMessage.value = 'Invalid selection';
        isLoading.value = false;
        return;
      }

      final optionValue = getOptionValue(selectedOption);
      final optionIndex = options.indexOf(selectedOption);

      // Backend typically expects the *value* (not index).
      final res = await AuthApi.verifyLogicAnswer(
        staffId: staffId,
        password: password,
        selectedOption: optionValue,
        logicQuestion: logicQuestion,
      );



      if (!res.isAuthenticated) {
        errorMessage.value = res.message ?? 'Verification failed. Please try again.';
        return;
      }

      await session.saveSession(
        token: res.token!,
        userId: res.userId,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Security Verification',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey.shade700),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify Your Identity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Answer the security question to proceed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Question Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Security Question',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      logicQuestion,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Options Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your answer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          final displayText = getDisplayValue(opt);
                          final optionValue = getOptionValue(opt);
                          final selectedValue = selected ?? '';

                          // Determine if this option is selected
                          bool isSelected = false;
                          if (opt is String) {
                            isSelected = opt == selected;
                          } else if (opt is int) {
                            isSelected = opt.toString() == selected;
                          } else if (opt is Map) {
                            final val = opt['value'] ?? opt['label'] ?? opt;
                            isSelected = val.toString() == selected;
                          } else {
                            isSelected = opt.toString() == selected;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: Material(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              elevation: isSelected ? 2 : 0,
                              child: InkWell(
                                onTap: isLoading.value
                                    ? null
                                    : () => setState(() {
                                          selected = optionValue.toString();
                                        }),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Radio Button
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade200,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 14,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          displayText,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.blue.shade700
                                                : Colors.grey.shade900,
                                          ),
                                        ),
                                      ),
                                      // Optional: Show type indicator
                                      if (opt is int)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Number',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      if (opt is String)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Text',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Error Message
              Obx(
                () => errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage.value,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              // Proceed Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: isLoading.value ? null : verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify & Proceed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}