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

  Future<void> _initializeApp() async {
    // Wait for 3 seconds to show the splash screen.
    await Future.delayed(const Duration(seconds: 3));

    // Manually check if a user is currently logged in.
    if (FirebaseAuth.instance.currentUser != null) {
      // If they are, go directly to the dashboard.
      Get.offAllNamed(Routes.DASHBOARD);
    } else {
      // If not, go to the authentication hub.
      Get.offAllNamed(Routes.AUTH_HUB);
    }
  }
}