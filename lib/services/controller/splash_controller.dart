import 'package:get/get.dart';

import '../session_service.dart';
import '../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  final SessionService session;

  SplashController(this.session);

  @override
  void onReady() {
    super.onReady();
    _route();
  }

  Future<void> _route() async {
    await Future<void>.delayed(const Duration(seconds: 5));

    if (session.isAuthenticated.value) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}

