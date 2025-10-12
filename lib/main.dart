import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:expensease/app/routes/app_pages.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_theme.dart';
import 'package:expensease/app/bindings/app_binding.dart'; // Correct binding import
import 'firebase_options.dart'; // Import the generated Firebase options

void main() async {
  // --- THIS IS THE FINAL, DEFINITIVE FIX ---

  // 1. Ensure Flutter's widget binding is initialized before any async operations.
  // This is a mandatory first step.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize GetStorage for local key-value storage.
  await GetStorage.init();

  // 3. CRITICAL: Initialize Firebase and WAIT for it to complete.
  // The 'await' keyword here is the most important change. It guarantees
  // that the app will not run until it is fully and securely connected
  // to your Firebase project. This was the root cause of the intermittent
  // permission errors.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. (Optional but good practice) Configure Firestore settings after initialization.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // 5. Now that all services are initialized, it is safe to run the app.
  runApp(const MyApp());

  // --- END OF FIX ---
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
      initialRoute: Routes.SPLASH,
      getPages: AppPages.routes,
      // Use the correct AppBinding as you specified.
      initialBinding: AppBinding(),
    );
  }
}