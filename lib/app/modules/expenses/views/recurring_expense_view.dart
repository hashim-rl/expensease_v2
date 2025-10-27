import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/expenses/controllers/recurring_expense_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:expensease/app/shared/widgets/list_shimmer_loader.dart';
// --- Add AppColors for consistency ---
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';


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
            final nextDueDate = expense.nextDueDate;
            // --- Determine frequency text ---
            final frequencyText = expense.frequency.isNotEmpty
                ? expense.frequency[0].toUpperCase() + expense.frequency.substring(1)
                : 'Unknown Frequency';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              // --- Add some subtle elevation and shape ---
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                // --- Use a more specific icon and consistent color ---
                leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.autorenew, color: AppColors.primaryBlue)
                ),
                title: Text(expense.description, style: AppTextStyles.bodyBold),
                // --- Show frequency along with next due date ---
                subtitle: Text('$frequencyText • Next: ${DateFormat.yMMMd().format(nextDueDate)}'),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(expense.amount), // Use currency format
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                ),
                onTap: () {
                  _showOptionsDialog(context, expense.id, expense.description); // Pass description for context
                },
              ),
            );
          },
        );
      }),
    );
  }

  // --- Pass description for better dialog titles ---
  void _showOptionsDialog(BuildContext context, String expenseId, String description) {
    Get.defaultDialog(
        title: description, // Use expense name as title
        titleStyle: AppTextStyles.headline2,
        middleText: "Manage this recurring expense:",
        middleTextStyle: AppTextStyles.bodyText1,
        // --- Use Column for actions for better layout ---
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Edit Details"),
              onTap: () {
                Get.back();
                Get.snackbar("Info", "Editing recurring expenses is not yet implemented.");
                // TODO: Navigate to an edit screen for this recurring expense
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.red),
              title: Text("Delete Template", style: TextStyle(color: AppColors.red)),
              onTap: () {
                Get.back();
                _showDeleteConfirmation(context, expenseId, description);
              },
            ),
          ],
        ),
        // --- Remove default actions, handled by content ---
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Get.back(),
          ),
        ]
    );
  }

  // --- Pass description for better confirmation text ---
  void _showDeleteConfirmation(BuildContext context, String expenseId, String description) {
    Get.defaultDialog(
      title: "Delete Recurring Expense?",
      titleStyle: AppTextStyles.headline2.copyWith(color: AppColors.red),
      middleText: "Are you sure you want to permanently delete the template for \"$description\"? This action cannot be undone.",
      middleTextStyle: AppTextStyles.bodyText1,
      confirm: TextButton(
        child: const Text("Delete", style: TextStyle(color: Colors.red)),
        onPressed: () {
          controller.deleteRecurringExpense(expenseId);
          Get.back(); // Close confirmation dialog
        },
      ),
      cancel: TextButton(
        child: const Text("Cancel"),
        onPressed: () => Get.back(),
      ),
    );
  }
}