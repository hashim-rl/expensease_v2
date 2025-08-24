import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/settle_up_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/services/user_service.dart';

class SettleUpView extends GetView<SettleUpController> {
  const SettleUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDebtResolverCard(),
            const SizedBox(height: 24),
            _buildMemberBalancesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtResolverCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debt Loop Resolver',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Simplified transactions to settle all debts.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // This displays the simplified payment plan in a grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.transactions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final transaction = controller.transactions[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${transaction.from} pays ${transaction.to}\n\$${transaction.amount.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberBalancesList() {
    final UserService userService = UserService();
    // This list shows who owes what and provides the "Record a payment" button
    return Obx(() => ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.memberBalances.length,
      itemBuilder: (context, index) {
        final uid = controller.memberBalances.keys.elementAt(index);
        final balance = controller.memberBalances[uid]!;
        if (balance >= 0) return const SizedBox.shrink(); // Only show people who owe

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            // TODO: Replace uid with actual user name
            title: Text(uid, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("You owe \$${balance.abs().toStringAsFixed(2)}"),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Call controller.recordPayment with the correct details
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('Record a payment'),
            ),
          ),
        );
      },
    ));
  }
}