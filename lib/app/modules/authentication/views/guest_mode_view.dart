import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/routes/app_routes.dart';

class GuestModeView extends GetView<AuthController> {
  const GuestModeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Dashboard'),
        actions: [
          // A button to exit guest mode
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Exit Guest Mode',
            onPressed: controller.signOut,
          )
        ],
      ),
      body: Column(
        children: [
          // This is the persistent warning banner from your document
          _buildWarningBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to Guest Mode!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can create one local group and add expenses to try out the app.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      // --- UPDATED LOGIC ---
                      onPressed: controller.createLocalGuestGroup,
                      // ---------------------
                      child: const Text('Create a Local Group'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              'You are in Guest Mode. Your data is stored only on this device and will be lost if you uninstall the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.SIGNUP),
              child: const Text(
                'Sign up for free to save and sync your data.',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            )
          ],
        ),
      ),
    );
  }
}