import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:expensease/app/routes/app_pages.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_theme.dart';
import 'package:expensease/app/bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ExpensEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // The app will ALWAYS start at the splash screen.
      initialRoute: Routes.SPLASH,
      getPages: AppPages.routes,
      // The InitialBinding ensures the AuthController is ready from the start.
      initialBinding: InitialBinding(),
    );
  }
}