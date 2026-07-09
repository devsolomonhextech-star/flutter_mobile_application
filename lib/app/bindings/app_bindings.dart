import 'package:get/get.dart';

import '../../services/session_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(SessionService(), permanent: true);
  }
}

