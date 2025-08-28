import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.dashboard_outlined,
            text: 'Dashboard',
            onTap: () => Get.back(), // Close drawer, already on dashboard
          ),
          _buildDrawerItem(
            icon: Icons.group_work_outlined,
            text: 'My Groups',
            onTap: () {
              Get.back(); // Close drawer first
              Get.toNamed(Routes.GROUPS_LIST);
            },
          ),
          const Divider(),
          _buildSectionHeader('Specialized Modes'),
          _buildDrawerItem(
            icon: Icons.favorite_border,
            text: 'Couples Mode',
            onTap: () => Get.toNamed(Routes.COUPLES_MODE_SETUP),
          ),
          _buildDrawerItem(
            icon: Icons.family_restroom_outlined,
            text: 'Family Mode',
            onTap: () => Get.toNamed(Routes.FAMILY_MODE_DASHBOARD),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            text: 'Settings',
            onTap: () {
              Get.back(); // Close drawer first
              Get.toNamed(Routes.SETTINGS);
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Logout',
            onTap: () => authController.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Center(
        child: Text(
          'ExpensEase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(text, style: AppTextStyles.bodyText1.copyWith(color: AppColors.textPrimary)),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}