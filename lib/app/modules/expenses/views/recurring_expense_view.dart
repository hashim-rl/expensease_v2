import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/expenses/controllers/recurring_expense_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:expensease/app/shared/widgets/list_shimmer_loader.dart';

class RecurringExpenseView extends GetView<RecurringExpenseController> {
  const RecurringExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ListShimmerLoader();
        }
        if (controller.recurringExpenses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.event_repeat,
            title: 'No Recurring Expenses',
            subtitle: 'You can set up recurring bills from the "Add Expense" screen.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: controller.recurringExpenses.length,
          itemBuilder: (context, index) {
            final expense = controller.recurringExpenses[index];
            final nextDueDate = expense.nextDueDate.toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.event_repeat)),
                title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Next due on: ${DateFormat.yMMMd().format(nextDueDate)}'),
                trailing: Text('\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                onTap: () {
                  // Show options to edit or delete
                  _showOptionsDialog(context, expense.id);
                },
              ),
            );
          },
        );
      }),
    );
  }

  void _showOptionsDialog(BuildContext context, String expenseId) {
    Get.defaultDialog(
      title: "Manage Recurring Expense",
      middleText: "What would you like to do?",
      actions: [
        TextButton(
          child: const Text("Edit"),
          onPressed: () {
            Get.back();
            // TODO: Navigate to an edit screen for this recurring expense
          },
        ),
        TextButton(
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
          onPressed: () {
            Get.back();
            _showDeleteConfirmation(context, expenseId);
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, String expenseId) {
    Get.defaultDialog(
      title: "Are you sure?",
      middleText: "This will permanently delete the recurring expense. This action cannot be undone.",
      confirm: TextButton(
        child: const Text("Delete", style: TextStyle(color: Colors.red)),
        onPressed: () {
          controller.deleteRecurringExpense(expenseId);
          Get.back();
        },
      ),
      cancel: TextButton(
        child: const Text("Cancel"),
        onPressed: () => Get.back(),
      ),
    );
  }
}