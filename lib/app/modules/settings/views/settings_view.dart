import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Account Section [cite: 269]
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed(Routes.PROFILE),
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions_outlined),
            title: const Text('Manage Subscription'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () { /* TODO: Navigate to subscription page */ },
          ),

          // Preferences Section [cite: 270]
          _buildSectionHeader('Preferences'),
          Obx(() => SwitchListTile(
            secondary: const Icon(Icons.brightness_6_outlined),
            title: const Text('Dark Mode'),
            value: controller.isDarkMode.value,
            onChanged: controller.toggleTheme,
          )),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('App Language'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notification Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed(Routes.NOTIFICATIONS),
          ),

          // Security Section [cite: 272]
          _buildSectionHeader('Security & Data'),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Helper widget to create clean section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}