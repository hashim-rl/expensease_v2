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
import 'package:expensease/app/modules/authentication/views/splash_view.dart';
import 'package:expensease/app/services/auth_service.dart';

void main() async {
  // --- THIS IS THE ROBUST INITIALIZATION SEQUENCE ---
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- NEW LINE TO ENABLE OFFLINE PERSISTENCE ---
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

      // --- THIS IS THE DEFINITIVE FIX FOR THE RACE CONDITION ---
      // The app's home is now controlled by an Obx widget that listens to our
      // reliable AuthService. It will instantly and correctly show the right
      // screen based on the user's real-time login status.
      home: Obx(() {
        if (authService.isLoading.value) {
          // While the service is checking the initial auth state, show a splash screen.
          return const SplashView();
        } else if (authService.user.value != null) {
          // If the user is logged in, go to the dashboard.
          // --- SAFER NAVIGATION ---
          // Use Get.offAllNamed to ensure proper stack management
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/dashboard');
          });
          // Return a placeholder while navigating
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
          // ------------------------
        } else {
          // If the user is logged out, go to the auth hub.
          // --- SAFER NAVIGATION ---
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/auth-hub');
          });
          // Return a placeholder while navigating
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
          // ------------------------
        }
      }),
      // --- REMOVE HOME, use initialRoute instead for GetX ---
      // initialRoute: '/splash', // Or determine initial route based on auth status
      getPages: AppPages.routes,
    );
  }
}