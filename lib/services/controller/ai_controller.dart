import 'package:get/get.dart';
import 'package:doctor_app/services/api/ai_api.dart';

class AiController extends GetxController {
  final AiApi _aiApi = AiApi();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString aiSummary = ''.obs;
  final RxMap<String, dynamic> patient = <String, dynamic>{}.obs;

  Future<void> loadPatientAiSummary(String visitId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _aiApi.getPatientAiSummary(visitId: visitId);
      if (result['success'] == true) {
        aiSummary.value = (result['aiSummary'] ?? '').toString();
        final p = result['patient'];
        if (p is Map<String, dynamic>) {
          patient.assignAll(p);
        } else {
          patient.clear();
        }
      } else {
        errorMessage.value = result['error']?.toString() ?? 'Failed';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

