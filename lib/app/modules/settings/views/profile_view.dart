import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/settings/controllers/profile_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import 'package:expensease/app/routes/app_routes.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('User Profile', style: AppTextStyles.title),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Get.toNamed(Routes.EDIT_PROFILE);
              if (result == true) {
                controller.loadAllProfileData();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.currentUser.value == null) {
          return const Center(child: Text('Could not load user data.'));
        }
        return _buildProfileContent();
      }),
    );
  }

  Widget _buildProfileContent() {
    final user = controller.currentUser.value!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 20),
        _buildProfileHeader(user),
        const SizedBox(height: 30),
        _buildSummaryCards(),
        const SizedBox(height: 30),
        Text('Recent Expenses',
            style: AppTextStyles.headline2.copyWith(fontSize: 20)),
        const SizedBox(height: 10),
        _buildRecentExpenses(),
      ],
    );
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        // This Obx will make the avatar refresh automatically
        Obx(() => CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
          backgroundImage:
          controller.currentUser.value?.profilePicUrl != null
              ? NetworkImage(controller.currentUser.value!.profilePicUrl!)
              : null,
          child: controller.currentUser.value?.profilePicUrl == null
              ? Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
            style: AppTextStyles.headline1.copyWith(color: AppColors.primaryBlue),
          )
              : null,
        )),
        const SizedBox(height: 16),
        Text(user.fullName, style: AppTextStyles.headline2),
        Text(user.email, style: AppTextStyles.bodyText1),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Your Balance',
            amount: currencyFormat.format(controller.netBalance.value),
            color:
            controller.netBalance.value >= 0 ? AppColors.green : AppColors.red,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            title: 'Total Spent',
            amount: currencyFormat.format(controller.totalSpent.value),
            color: AppColors.textPrimary,
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.bodyText1),
            const SizedBox(height: 4),
            Text(amount, style: AppTextStyles.headline2.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Obx(() {
      if (controller.recentExpenses.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Center(child: Text('No recent expenses found.')),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recentExpenses.length,
        itemBuilder: (context, index) {
          final expense = controller.recentExpenses[index];
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.shopping_cart_outlined,
                    color: AppColors.primaryBlue),
              ),
              title: Text(expense.description, style: AppTextStyles.bodyBold),
              subtitle: Text(DateFormat.yMMMd().format(expense.date)),
              trailing: Text(
                currencyFormat.format(expense.totalAmount),
                style: AppTextStyles.bodyBold,
              ),
              onTap: () =>
                  Get.toNamed(Routes.EXPENSE_DETAILS, arguments: expense),
            ),
          );
        },
      );
    });
  }
}