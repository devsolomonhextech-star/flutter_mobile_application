import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../services/session_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<SessionService>();


    if (session.isAuthenticated.value) {
      return null;
    }

    return const RouteSettings(name: '/login');
  }
}

