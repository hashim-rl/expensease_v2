import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:expensease/app/modules/shared_buys/controllers/shared_buys_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';

class SharedBuysView extends GetView<SharedBuysController> {
  // FIX 1: Removed 'const' from the constructor
  SharedBuysView({super.key});

  // FIX 2: Moved Get.find() outside of build() to prevent timing/const issues
  final DashboardController dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    // Removed the inline Get.find<DashboardController>()

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.sharedBuyExpenses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.shopping_cart_outlined,
            title: 'No Shared Buys',
            subtitle: 'Tap the + button to add a shared purchase!',
          );
        }
        return ListView.builder(
          itemCount: controller.sharedBuyExpenses.length,
          itemBuilder: (context, index) {
            final expense = controller.sharedBuyExpenses[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.shopping_cart),
                ),
                title: Text(
                  expense.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(expense.date),
                ),
                trailing: Text(
                  '\$${expense.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Use the initialized final field
          dashboardController.showGroupSelectionDialog(category: 'Shared Buy');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
