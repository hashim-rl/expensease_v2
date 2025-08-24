import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/widgets/auth_background.dart'; // Import background

class AuthHubView extends GetView<AuthController> {
  const AuthHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Image.asset('assets/icon.png', height: 80), // Use your logo
            const SizedBox(height: 24),
            const Text(
              'Splitting bills, simlified.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Manage shared expenses effortlessly with friends and family. Track payments, split costs, and gain financial clarity together.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: controller.goToSignupPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.goToLoginPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log In', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),

            // --- INSERTED CODE ---
            TextButton(
              onPressed: controller.signInAsGuest,
              child: const Text(
                'Continue in Guest Mode',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            // --- END INSERTED CODE ---

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}