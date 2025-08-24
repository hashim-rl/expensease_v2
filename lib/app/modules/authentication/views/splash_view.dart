import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_colors.dart'; // Assuming this file exists

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// This is the working logic that handles startup navigation.
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

  @override
  Widget build(BuildContext context) {
    // This is your original, beautiful UI with animations.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Using your AppColors gradient
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Image.asset(
                  'assets/icon.png', // Your logo
                  width: 120,
                ),
              ),
              const SizedBox(height: 24),

              // App name animation
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  'ExpensEase',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tagline animation
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  'Make Every Split Effortless',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}