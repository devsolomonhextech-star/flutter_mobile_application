import 'package:doctor_app/pages/appointments/upcoming_doctor_appointments_page.dart';
import 'package:doctor_app/pages/chat/department_list_screen.dart';
import 'package:doctor_app/pages/patient/patient_list_screen.dart';
import 'package:doctor_app/pages/patient/patient_visit_details_screen.dart';
import 'package:doctor_app/pages/profile/leave_request.dart';
import 'package:doctor_app/pages/profile/profile_settings_screen.dart';
import 'package:doctor_app/pages/profile/report_screen.dart';
import 'package:doctor_app/pages/profile/staff_rotation.dart';
import 'package:doctor_app/pages/profile/stepper/leave_request_stepper.dart';
import 'package:doctor_app/pages/qrcode/qrcode_screen.dart';
import 'package:get/get.dart';

import '../../pages/auth/login_page.dart';
import '../../pages/splash/splash_page.dart';
import '../middleware/auth_middleware.dart';
import '../../pages/home/home_page.dart';
import '../../pages/auth/logic_answer_page.dart';
import '../../pages/profile/notifications.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const chat = '/chat';
  static const profile = '/profile';
  static const qrcode = '/qrcode';
  static const notifications = '/notifications';
  static const leave = '/leave-requests';
  static const duty_roster = '/duty-roster';
  static const report_bug = '/report_bug';
  static const appointment = '/appointments';
  static const patients = '/patients';
  static const patientVisitDetails = '/patient-visit-details';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/logic-answer',
      page: () => const LogicAnswerPage(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: home,
      page: () => const HomePage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: chat,
      page: () => const DepartmentListScreen(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: profile,
      page: () => const ProfileSettingsPage(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: '/notifications',
      page: () => const NotificationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: qrcode,
      page: () => const QrcodeScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/notifications',
      page: () => const NotificationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: leave,
      page: () => const LeaveRequest(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: duty_roster,
      page: () => const StaffRotation(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: report_bug,
      page: () => const ReportScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: appointment,
      page: () => const UpcomingDoctorAppointmentsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: patients,
      page: () => const PatientListScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: patientVisitDetails,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final visitId = (args?['visitId'] ?? '').toString();
        return PatientVisitDetailsScreen(visitId: visitId);
      },
      transition: Transition.rightToLeft,
    ),

  ];
}
