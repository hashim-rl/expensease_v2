import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _initializeApp();
  }

  /// --- THIS IS THE DEFINITIVE FIX FOR THE RACE CONDITION ---
  Future<void> _initializeApp() async {
    // This is a short, fixed delay for aesthetic purposes only.
    // The actual navigation logic no longer depends on this timer.
    await Future.delayed(const Duration(seconds: 2));

    // This is the correct way to check for authentication state on startup.
    // `authStateChanges().first` waits for the Firebase SDK to finish its
    // initialization and give us the FIRST definitive status of the user.
    final user = await FirebaseAuth.instance.authStateChanges().first;

    // Now, we can reliably navigate based on the result.
    if (user != null) {
      // The user is confirmed to be logged in.
      Get.offAllNamed(Routes.DASHBOARD);
    } else {
      // The user is confirmed to be logged out.
      Get.offAllNamed(Routes.AUTH_HUB);
    }
  }
}