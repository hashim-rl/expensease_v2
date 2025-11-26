import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/expenses/controllers/recurring_expense_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import 'package:expensease/app/routes/app_routes.dart';
// --- NEW: Import GroupController to check active group status ---
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:expensease/app/shared/widgets/list_shimmer_loader.dart';

class RecurringExpenseView extends GetView<RecurringExpenseController> {
  const RecurringExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject GroupController to check if a group is actually selected
    final groupController = Get.find<GroupController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        // 1. CRITICAL FIX: Check if there is an active group first.
        // If not, show a specific "No Group" message instead of loading forever.
        if (groupController.activeGroup.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Group Selected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Please create or join a group first.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        // 2. Check loading state (Using your Shimmer Loader)
        if (controller.isLoading.value) {
          return const ListShimmerLoader();
        }

        // 3. Check empty state (Using your Empty State Widget)
        if (controller.recurringExpenses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.event_repeat,
            title: 'No Recurring Expenses',
            subtitle: 'You can set up recurring bills from the "Add Expense" screen.',
          );
        }

        // 4. Render the List
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.recurringExpenses.length,
          itemBuilder: (context, index) {
            final expense = controller.recurringExpenses[index];
            final nextDueDate = expense.nextDueDate;

            final frequencyText = expense.frequency.isNotEmpty
                ? expense.frequency[0].toUpperCase() + expense.frequency.substring(1)
                : 'Unknown Frequency';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.autorenew, color: AppColors.primaryBlue),
                ),
                title: Text(expense.description, style: AppTextStyles.bodyBold),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('$frequencyText • Next: ${DateFormat.yMMMd().format(nextDueDate)}'),
                    // Show WhatsApp indicator if present
                    if (expense.whatsappNumber != null && expense.whatsappNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.message, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('WhatsApp Enabled', style: TextStyle(fontSize: 10, color: Colors.green[700])),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(expense.amount),
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryBlue, fontSize: 16),
                ),
                onTap: () {
                  _showOptionsDialog(context, expense.id, expense.description);
                },
              ),
            );
          },
        );
      }),
      // 5. Floating Action Button (Conditional)
      floatingActionButton: Obx(() {
        return groupController.activeGroup.value != null
            ? FloatingActionButton(
          backgroundColor: AppColors.primaryBlue,
          onPressed: () {
            // Navigate to Add Expense, passing the current group context
            Get.toNamed(
                Routes.ADD_EXPENSE,
                arguments: {
                  'group': groupController.activeGroup.value,
                  'members': groupController.groups.firstWhere((g) => g.id == groupController.activeGroup.value!.id).memberIds
                }
            );
            Get.snackbar('Tip', 'To add a recurring expense, toggle "Recurring Expense" in the form.');
          },
          child: const Icon(Icons.add),
        )
            : const SizedBox.shrink();
      }),
    );
  }

  void _showOptionsDialog(BuildContext context, String expenseId, String description) {
    Get.defaultDialog(
        title: description,
        titleStyle: AppTextStyles.headline2,
        middleText: "Manage this recurring expense:",
        middleTextStyle: AppTextStyles.bodyText1,
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text("Delete Template", style: TextStyle(color: AppColors.red)),
              onTap: () {
                Get.back();
                _showDeleteConfirmation(context, expenseId, description);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Get.back(),
          ),
        ]
    );
  }

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