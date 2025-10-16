import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/reports/controllers/reports_controller.dart';
import 'package:expensease/app/shared/services/user_service.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';
// Note: Assuming UserService is bound/available via Get.find()

class MonthlyReportView extends GetView<ReportsController> {
  const MonthlyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the UserService instance to resolve UIDs to names
    final UserService userService = Get.find<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
              : IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: controller.generateAndPreviewPdf,
            tooltip: 'Generate PDF Report',
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.spendingByCategory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalSpending = controller.spendingByCategory.values.fold(0.0, (sum, amount) => sum + amount);
        final settlementPlan = DebtSimplifier.simplify(controller.memberBalances.value);

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTotalSpendingCard(totalSpending),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Spending Breakdown'),
            _buildSpendingBreakdown(context, userService),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Current Balances & Settlement'),
            _buildMemberBalances(context, userService),

            const SizedBox(height: 24),
            _buildSettlementPlan(context, userService, settlementPlan),
            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTotalSpendingCard(double total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('TOTAL GROUP SPENDING (This Month)', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingBreakdown(BuildContext context, UserService userService) {
    if (controller.spendingByCategory.isEmpty) {
      return const Text("No tracked expenses found for this period.");
    }

    return Column(
      children: controller.spendingByCategory.entries.map((entry) {
        return ListTile(
          leading: const Icon(Icons.category, color: Colors.blueGrey),
          title: Text(entry.key),
          trailing: Text(
            '\$${entry.value.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberBalances(BuildContext context, UserService userService) {
    if (controller.memberBalances.isEmpty) {
      return const Text("No member balance data available.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: controller.memberBalances.entries.map((entry) {
        final uid = entry.key;
        final balance = entry.value;

        return FutureBuilder<String>(
          future: userService.getUserName(uid),
          builder: (context, snapshot) {
            final name = snapshot.data ?? uid;
            final isOwed = balance > 0;
            final color = isOwed ? Colors.green.shade700 : (balance < 0 ? Colors.red.shade700 : Colors.black87);

            return ListTile(
              leading: CircleAvatar(child: Text(name.substring(0, 1))),
              title: Text(name),
              subtitle: Text(isOwed ? 'Gets back' : (balance < 0 ? 'Owes' : 'Settled')),
              trailing: Text(
                '\$${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSettlementPlan(BuildContext context, UserService userService, List<SimpleTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Card(
        color: Colors.greenAccent,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'All settled up! No transfers needed.',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Suggested Transfers'),
        Card(
          child: Column(
            children: transactions.map((t) {
              return FutureBuilder<List<String>>(
                // Fetch names for both the payer (from) and recipient (to)
                future: Future.wait([userService.getUserName(t.from), userService.getUserName(t.to)]),
                builder: (context, snapshot) {
                  final fromName = snapshot.data?[0] ?? t.from;
                  final toName = snapshot.data?[1] ?? t.to;
                  return ListTile(
                    leading: const Icon(Icons.send_rounded, color: Colors.blue),
                    title: Text('$fromName pays $toName'),
                    trailing: Text(
                      '\$${t.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    subtitle: const Text('Tap to record payment'),
                    onTap: () => controller.recordPayment(t.from, t.to, t.amount),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}