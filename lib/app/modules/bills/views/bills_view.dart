import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/bills/controllers/bills_controller.dart';
import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';

class BillsView extends GetView<BillsController> {
  const BillsView({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboardController = Get.find<DashboardController>();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.billExpenses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'No Bills Logged',
            subtitle: 'Tap the + button to add a recurring bill!',
          );
        }
        return ListView.builder(
          itemCount: controller.billExpenses.length,
          itemBuilder: (context, index) {
            final expense = controller.billExpenses[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long),
                ),
                title: Text(
                  expense.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Due on: ${DateFormat.yMMMd().format(expense.date)}',
                ),
                trailing: Text(
                  '\$${expense.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purpleAccent,
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Use the reusable dialog to add a 'Bill'
          dashboardController.showGroupSelectionDialog(category: 'Bill');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}