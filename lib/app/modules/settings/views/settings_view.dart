import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Account',
              children: [
                _buildListTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => Get.toNamed(Routes.PROFILE),
                ),
                _buildListTile(
                  icon: Icons.subscriptions_outlined,
                  title: 'Manage Subscription',
                  onTap: () {
                    Get.snackbar('Coming Soon', 'Subscription management will be available in a future update.');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Preferences',
              children: [
                Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.brightness_6_outlined, color: AppColors.textSecondary),
                  title: const Text('Dark Mode'),
                  value: controller.isDarkMode.value,
                  onChanged: controller.toggleTheme,
                  activeColor: AppColors.primaryBlue,
                )),
                _buildListTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notification Settings',
                  onTap: () => Get.toNamed(Routes.NOTIFICATIONS),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Security & Data',
              children: [
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: AppColors.red,
                  onTap: () => controller.authController.signOut(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: color)),
      trailing: color == null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }
}