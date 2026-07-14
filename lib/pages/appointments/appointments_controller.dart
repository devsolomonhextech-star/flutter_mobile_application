import 'package:doctor_app/data/models/doctor_appointment_model.dart';
import 'package:doctor_app/services/api/doctor_appointments_api.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:get/get.dart';


class AppointmentsController extends GetxController {
  AppointmentsController({
    required this.session,
    required this.doctorId,
    required this.institutionId,
  });

  final SessionService session;
  final String doctorId;
  final String institutionId;

  final RxBool isLoading = false.obs;
  final RxList<DoctorAppointment> upcomingAppointments = <DoctorAppointment>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUpcoming();
  }

  Future<void> fetchUpcoming({int limit = 20}) async {
    try {
      isLoading.value = true;
      final tokenDoctorId = doctorId;
      final tokenInstitutionId = institutionId;

      final items = await DoctorAppointmentsApi.getAppointmentsByDoctorId(
        session: session,
        institutionId: tokenInstitutionId,
        doctorId: tokenDoctorId,
      );

      upcomingAppointments.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAppointment({required String appointmentId}) async {
    await DoctorAppointmentsApi.deleteAppointment(
      session: session,
      institutionId: institutionId,
      appointmentId: appointmentId,
    );

    await fetchUpcoming();
  }

  // filter date
  List<DoctorAppointment> getUpcomingAppointmentsForDate(DateTime date) {
    return upcomingAppointments.where((appointment) {
      final appointmentDate = DateTime.parse(appointment.date);
      return appointmentDate.year == date.year &&
          appointmentDate.month == date.month &&
          appointmentDate.day == date.day;
    }).toList();
  }
}

