import 'package:doctor_app/services/isar/isar_service.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/app_bindings.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar
  await IsarService.initialize();
  
  // Initialize Session Service
  await Get.put(SessionService()).init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Doctor App',
      theme: AppTheme.theme(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      initialBinding: AppBindings(),
      debugShowCheckedModeBanner: false,
    );
  }
}

