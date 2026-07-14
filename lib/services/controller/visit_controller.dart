// lib/app/modules/patient_list/controllers/visit_controller.dart
import 'package:get/get.dart';
import 'package:doctor_app/data/models/visit_models.dart';
import 'package:doctor_app/services/api/visit_api.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:get_storage/get_storage.dart';

class VisitController extends GetxController {
  final VisitApi _visitApi = VisitApi();
  final SessionService _session = Get.find<SessionService>();

  // Observable variables
  final RxList<Visit> visits = <Visit>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt totalCount = 0.obs;

  // Filters
  final RxString selectedDepartmentId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveVisits(departmentId: _session.user?.departmentId);
  }

  Future<void> loadActiveVisits({String? departmentId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final institutionId = _session.user?.institutionId;
      print(_session.user!.institutionId);

      // if (institutionId == null || institutionId.isEmpty) {
      //   errorMessage.value = 'No institution found for this user';
      //   return;
      // }
      print('printing session user: ${_session.user!.institution}');

      final result = await _visitApi.getActiveVisits(
        institutionId: institutionId ?? '',
        departmentId: departmentId ?? selectedDepartmentId.value,
      );
      if (result['success'] == true) {
        visits.value = List<Visit>.from(result['data']);

        totalCount.value = result['count'] ?? visits.length;
      } else {
        errorMessage.value = result['error'] ?? 'Failed to load visits';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshVisits() async {
    await loadActiveVisits();
  }

  Future<void> filterByDepartment(String departmentId) async {
    selectedDepartmentId.value = departmentId;
    await loadActiveVisits(departmentId: departmentId);
  }

  Future<void> clearDepartmentFilter() async {
    selectedDepartmentId.value = '';
    await loadActiveVisits();
  }

  Future<Visit?> getVisitDetails(String visitId) async {
    try {
      isLoading.value = true;
      final result = await _visitApi.getVisitDetails(visitId: visitId);

      if (result['success'] == true) {
        return Visit.fromJson(result['data']);
      } else {
        errorMessage.value = result['error'] ?? 'Failed to load visit details';
        return null;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  List<Visit> get activeVisits =>
      visits.where((v) => v.status == 'Active').toList();
  List<Visit> get completedVisits =>
      visits.where((v) => v.status == 'Completed').toList();
  List<Visit> get pendingVisits =>
      visits.where((v) => v.status == 'Pending').toList();

  int get activeCount => activeVisits.length;
  int get completedCount => completedVisits.length;
  int get pendingCount => pendingVisits.length;
}
