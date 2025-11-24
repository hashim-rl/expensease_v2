import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/groups/controllers/settle_up_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';

class SettleUpView extends GetView<SettleUpController> {
  const SettleUpView({super.key});

  // Helper for Dynamic Currency
  NumberFormat _getCurrencyFormat() {
    final currencyCode = controller.getCurrency();
    String symbol = '\$';
    if (currencyCode == 'EUR') symbol = '€';
    else if (currencyCode == 'GBP') symbol = '£';
    else if (currencyCode == 'JPY') symbol = '¥';

    return NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settle Up', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        // --- ADDED: Loading State to prevent "All Settled" flash ---
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        if (controller.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.green, size: 80),
                const SizedBox(height: 16),
                Text('All Settled Up!', style: AppTextStyles.headline2),
                const SizedBox(height: 8),
                Text('No debts pending in this group.', style: AppTextStyles.bodyText1),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSimplifiedPaymentsCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSimplifiedPaymentsCard() {
    final currencyFormat = _getCurrencyFormat();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Plan',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 8),
            Text(
              'The most efficient way to settle all debts.',
              style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            Obx(() => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 30),
              itemBuilder: (context, index) {
                final transaction = controller.transactions[index];
                final fromName = controller.getMemberName(transaction.from);
                final toName = controller.getMemberName(transaction.to);

                return Row(
                  children: [
                    // Left Side: Who Pays
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyText1.copyWith(color: Colors.black87),
                              children: [
                                TextSpan(text: fromName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const TextSpan(text: ' pays '),
                                TextSpan(text: toName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(transaction.amount),
                            style: AppTextStyles.title.copyWith(color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),

                    // Right Side: Action Button
                    Obx(() => ElevatedButton(
                      onPressed: controller.isSettling.value
                          ? null
                          : () => controller.recordPayment(
                        transaction.from,
                        transaction.to,
                        transaction.amount,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: controller.isSettling.value
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Mark Paid'),
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
}