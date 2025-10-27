import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
// --- Use AuthService for user data, keep AuthController for actions ---
import 'package:expensease/app/services/auth_service.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
// -------------------------------------------------------------------

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep AuthController for the signOut action
    // Use tryFind to avoid errors if controller not ready immediately
    final AuthController? authController = Get.find<AuthController>();
    // Use AuthService to safely access user state
    final AuthService authService = Get.find<AuthService>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Make the header reactive using Obx and AuthService
          // --- CORRECTED CHECK USING isLoading ---
          Obx(() {
            // Only show user email when authService is NOT loading and user exists
            final user = !authService.isLoading.value ? authService.user.value : null;
            return _buildDrawerHeader(user?.email); // Pass email or null
          }),
          _buildDrawerItem(
            icon: Icons.dashboard_outlined,
            text: 'Dashboard',
            // --- Safely close drawer only if open ---
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Get.back(); // Close drawer if open
              }
              // Navigate or ensure already on dashboard
              if (Get.currentRoute != Routes.DASHBOARD) {
                // Use offNamed to clear stack if coming from auth
                if (Get.previousRoute == Routes.AUTH_HUB || Get.previousRoute == Routes.LOGIN || Get.previousRoute == Routes.SIGNUP) {
                  Get.offAllNamed(Routes.DASHBOARD);
                } else {
                  Get.toNamed(Routes.DASHBOARD);
                }
              }
            },
            // ------------------------------------------
          ),
          _buildDrawerItem(
            icon: Icons.group_work_outlined,
            text: 'My Groups',
            onTap: () {
              Get.back(); // Close drawer first
              Get.toNamed(Routes.GROUPS_LIST);
            },
          ),
          _buildDrawerItem( // Added Recurring Expenses shortcut
            icon: Icons.event_repeat_outlined,
            text: 'Recurring Expenses',
            onTap: () {
              Get.back(); // Close drawer first
              Get.toNamed(Routes.RECURRING_EXPENSE);
            },
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
          // --- Conditionally show Logout only if logged in ---
          // --- CORRECTED CHECK USING isLoading ---
          Obx(() {
            // Only show logout when authService is NOT loading and user exists
            final user = !authService.isLoading.value ? authService.user.value : null;
            return user != null && authController != null // Check if user is not null and controller exists
                ? _buildDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () {
                Get.back(); // Close drawer first
                authController.signOut(); // Call signout safely
              } ,
            )
                : const SizedBox.shrink(); // Hide if logged out or controller not ready or loading
          }
          ),
          // ---------------------------------------------------
        ],
      ),
    );
  }

  // Updated header to accept optional user email
  Widget _buildDrawerHeader(String? userEmail) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        // Use a gradient for a nicer look
        gradient: AppColors.primaryGradient,
      ),
      margin: EdgeInsets.zero, // Remove default margin
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjust padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, // Align content to bottom
        crossAxisAlignment: CrossAxisAlignment.start, // Align text left
        children: [
          const Text(
            'ExpensEase',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24, // Slightly smaller size
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Display user email if available, otherwise show Guest
          Text(
            // Show loading indicator briefly if needed, then email or Guest
            (userEmail == null && Get.find<AuthService>().isLoading.value)
                ? "Loading..."
                : (userEmail != null && userEmail.isNotEmpty) ? userEmail : "Guest User",
            style: AppTextStyles.bodyText1.copyWith(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    // Use highlight color on tap for better feedback
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary.withOpacity(0.8)),
      title: Text(text,
          style: AppTextStyles.bodyText1
              .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true, // Make items slightly smaller
      horizontalTitleGap: 0, // Reduce gap between icon and text
    );
  }
}