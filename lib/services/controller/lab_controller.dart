import 'package:doctor_app/data/models/lab_models.dart';
import 'package:doctor_app/services/api/lab_api.dart';
import 'package:get/get.dart';

class LabController extends GetxController {
  final LabApi _labApi = LabApi();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<PatientLabVisit> patientLabs = <PatientLabVisit>[].obs;

  Future<void> loadPatientLabs({
    required String patientId,
    String? status,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _labApi.getPatientLabs(
        patientId: patientId,
        status: status,
      );

      if (result['success'] == true) {
        patientLabs.value = List<PatientLabVisit>.from(result['data'] ?? []);
      } else {
        errorMessage.value = result['error']?.toString() ?? 'Failed to load';
        patientLabs.clear();
      }
    } catch (e) {
      errorMessage.value = e.toString();
      patientLabs.clear();
    } finally {
      isLoading.value = false;
    }
  }
}

