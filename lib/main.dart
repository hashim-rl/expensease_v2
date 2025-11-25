import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// --- NEW IMPORT ---
import 'package:cloud_firestore/cloud_firestore.dart';
// -----------------
import 'package:expensease/app/routes/app_pages.dart';
import 'package:expensease/app/shared/theme/app_theme.dart';
import 'package:expensease/app/bindings/app_binding.dart';
import 'package:expensease/firebase_options.dart';
import 'package:expensease/app/services/auth_service.dart';

// --- VIEW IMPORTS FOR STABLE NAVIGATION ---
import 'package:expensease/app/modules/authentication/views/splash_view.dart';
import 'package:expensease/app/modules/authentication/views/auth_hub_view.dart';
import 'package:expensease/app/modules/dashboard/views/dashboard_view.dart';
// ------------------------------------------

void main() async {
  // --- THIS IS THE ROBUST INITIALIZATION SEQUENCE ---
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- NEW LINE TO ENABLE OFFLINE PERSISTENCE ---
  // This ensures the app works without internet by caching Firestore data locally.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  // ---------------------------------------------

  // Initialize our new AuthService immediately
  await Get.putAsync(() => AuthService().init());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AuthService we just initialized
    final authService = Get.find<AuthService>();

    return GetMaterialApp(
      title: 'ExpensEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: AppBinding(),
      getPages: AppPages.routes,

      // --- PROFESSIONAL REACTIVE NAVIGATION ---
      // Instead of triggering side-effects (Get.offAllNamed) inside the build method,
      // we reactively switch the 'home' widget based on the user state.
      // This is cleaner, faster, and eliminates race conditions.
      home: Obx(() {
        if (authService.isLoading.value) {
          return const SplashView();
        } else if (authService.user.value != null) {
          return const DashboardView();
        } else {
          return const AuthHubView();
        }
      }),
      // ----------------------------------------
    );
  }
}