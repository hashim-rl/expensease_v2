import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/recurring_expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';

class RecurringExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final GroupController _groupController = Get.find<GroupController>();

  final isLoading = true.obs;
  final recurringExpenses = <RecurringExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _bindRecurringExpensesStream();
  }

  void _bindRecurringExpensesStream() {
    // Bind to the active group so we switch lists if the user switches groups
    ever(_groupController.activeGroup, (group) {
      if (group != null && !group.isLocal) {
        isLoading.value = true;
        recurringExpenses.bindStream(_expenseRepository.getRecurringExpensesStream(group.id));
        // --- NEW: Check for due bills whenever the group loads ---
        Future.delayed(const Duration(seconds: 2), () => checkAndProcessDueExpenses());
        isLoading.value = false;
      } else {
        recurringExpenses.clear();
        isLoading.value = false;
      }
    });
  }

  /// --- THE AUTOMATION ENGINE ---
  /// Checks if any template is due. If so, creates a real expense and updates the template.
  Future<void> checkAndProcessDueExpenses() async {
    final groupId = _groupController.activeGroup.value?.id;
    if (groupId == null) return;

    debugPrint("--- RECURRING ENGINE: Checking for due expenses in group $groupId ---");

    final now = DateTime.now();
    // Normalize 'today' to midnight to avoid time-of-day issues
    final today = DateTime(now.year, now.month, now.day);

    for (var template in recurringExpenses) {
      // Normalize due date to midnight
      final due = DateTime(template.nextDueDate.year, template.nextDueDate.month, template.nextDueDate.day);

      if (due.isBefore(today) || due.isAtSameMomentAs(today)) {
        debugPrint("--- RECURRING ENGINE: Processing '${template.description}' (Due: $due) ---");

        try {
          // 1. Create the Real Expense
          await _expenseRepository.addExpense(
            groupId: groupId,
            description: template.description,
            totalAmount: template.amount,
            date: DateTime.now(), // Expense created 'now'
            paidById: template.paidBy,
            splitBetween: template.split,
            category: 'Recurring', // Tag it so we know
          );

          // 2. Calculate Next Due Date
          DateTime nextDate = template.nextDueDate;
          switch (template.frequency.toLowerCase()) {
            case 'weekly':
              nextDate = nextDate.add(const Duration(days: 7));
              break;
            case 'monthly':
            // Logic to handle month overflow (e.g., Jan 31 -> Feb 28)
              int nextMonth = nextDate.month + 1;
              int nextYear = nextDate.year;
              if (nextMonth > 12) {
                nextMonth = 1;
                nextYear++;
              }
              // Get the last day of the next month
              int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
              int day = template.nextDueDate.day;
              if (day > lastDayOfNextMonth) day = lastDayOfNextMonth;

              nextDate = DateTime(nextYear, nextMonth, day);
              break;
            case 'quarterly':
              nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
              break;
            case 'yearly':
              nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
              break;
          }

          // 3. Update the Template
          await _expenseRepository.updateRecurringExpenseTemplate(
            groupId: groupId,
            templateId: template.id,
            updates: {'nextDueDate': nextDate},
          );

          // 4. Notify User (Snackbar is risky if they aren't looking, but good for MVP)
          Get.snackbar(
            'Auto-Expense Generated',
            'Recurring bill "${template.description}" was added automatically.',
            duration: const Duration(seconds: 5),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );

        } catch (e) {
          debugPrint("!!! RECURRING ENGINE ERROR: Failed to process ${template.description}: $e");
        }
      }
    }
  }

  Future<void> createRecurringExpense({
    required String description,
    required double amount,
    required String paidBy,
    required Map<String, double> split,
    required String frequency,
    required DateTime nextDueDate,
    String? whatsappNumber,
  }) async {
    final groupId = _groupController.activeGroup.value?.id;
    if (groupId == null) {
      Get.snackbar('Error', 'Cannot create recurring expense: No active group.');
      return;
    }

    try {
      await _expenseRepository.addRecurringExpenseTemplate(
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        split: split,
        frequency: frequency,
        nextDueDate: nextDueDate,
        whatsappNumber: whatsappNumber,
      );
      Get.back();
      Get.snackbar('Success', 'Recurring expense "$description" scheduled!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save template: ${e.toString()}');
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    final groupId = _groupController.activeGroup.value?.id;
    if (groupId == null) return;
    try {
      await _expenseRepository.deleteRecurringExpenseTemplate(
        groupId: groupId,
        templateId: id,
      );
      Get.snackbar('Success', 'Recurring expense cancelled.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: ${e.toString()}');
    }
  }
}