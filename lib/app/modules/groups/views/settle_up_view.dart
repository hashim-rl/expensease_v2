import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:expensease/app/modules/groups/controllers/settle_up_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart'; // Needed for SimpleTransaction type
// --- NEW IMPORT to get member names easily ---
import 'package:expensease/app/modules/groups/controllers/group_dashboard_controller.dart';
// ------------------------------------------

class SettleUpView extends GetView<SettleUpController> {
  const SettleUpView({super.key});

  // Helper to get member names (assumes GroupDashboardController is available)
  String _getMemberName(String uid) {
    try {
      final dashboardController = Get.find<GroupDashboardController>();
      return dashboardController.getMemberName(uid);
    } catch (_) {
      // Fallback if controller not found or member not in list
      return uid.substring(0, 6); // Show short UID as fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // REMOVED 'const' from here as AppColors.background is not a compile-time constant
        title: const Text('Settle Up'),
        backgroundColor: AppColors.background, // This line was causing the error
        elevation: 0,
      ),
      body: Obx(() {
        // Show loading or empty state if transactions haven't loaded
        if (controller.transactions.isEmpty && controller.memberBalances.isNotEmpty) {
          // This means balances exist, but simplification resulted in no payments needed
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.green, size: 60),
                const SizedBox(height: 16),
                Text('Everyone is settled up!', style: AppTextStyles.headline2),
                Text('No payments are needed in this group.', style: AppTextStyles.bodyText1),
              ],
            ),
          );
        } else if (controller.transactions.isEmpty && controller.memberBalances.isEmpty) {
          // This suggests an error or no data passed
          return Center(
            child: Text('Calculating settlement...', style: AppTextStyles.bodyText1),
            // Or show CircularProgressIndicator if you have an isLoading state
          );
        }

        // --- Main Content ---
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSimplifiedPaymentsCard(),
              const SizedBox(height: 24),
              // Optional: You could still show the original balances list if needed
              // _buildOriginalBalancesCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSimplifiedPaymentsCard() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simplified Payments',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 4),
            Text(
              'Make these payments to settle all debts:',
              style: AppTextStyles.bodyText1,
            ),
            const SizedBox(height: 20),
            // Use ListView.builder for the list of payments
            Obx(() => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final transaction = controller.transactions[index];
                final fromName = _getMemberName(transaction.from);
                final toName = _getMemberName(transaction.to);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Payment details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$fromName pays $toName',
                            style: AppTextStyles.bodyBold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(transaction.amount),
                            style: AppTextStyles.title.copyWith(color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action Button
                    Obx(() => ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark Paid'),
                      onPressed: controller.isSettling.value
                          ? null // Disable button while processing
                          : () => controller.recordPayment(
                        transaction.from,
                        transaction.to,
                        transaction.amount,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )),
                  ],
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  // Optional: Keep this if you want to show the original balances too
  Widget _buildOriginalBalancesCard() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Balances', style: AppTextStyles.headline2),
            const SizedBox(height: 16),
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.memberBalances.length,
              itemBuilder: (context, index) {
                final uid = controller.memberBalances.keys.elementAt(index);
                final balance = controller.memberBalances[uid]!;
                final name = _getMemberName(uid);
                final bool owes = balance < -0.01;
                final bool owed = balance > 0.01;
                final color = owes ? AppColors.red : (owed ? AppColors.green : AppColors.textSecondary);
                final text = owes ? 'Owes ${currencyFormat.format(balance.abs())}' :
                (owed ? 'Is owed ${currencyFormat.format(balance)}' : 'Settled up');

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  title: Text(name, style: AppTextStyles.bodyBold),
                  trailing: Text(
                    text,
                    style: AppTextStyles.bodyText1.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}