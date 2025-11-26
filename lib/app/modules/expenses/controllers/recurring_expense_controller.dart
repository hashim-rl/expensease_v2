import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/recurring_expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/shared/services/notification_service.dart'; // Import NotificationService

class RecurringExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final GroupController _groupController = Get.find<GroupController>();
  // Assuming NotificationService is available or registered. If not, remove this line and the usage below.
  // Based on previous steps, we added it.
  final NotificationService _notificationService = NotificationService();

  final isLoading = true.obs;
  final recurringExpenses = <RecurringExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    // If GroupController is still loading its initial groups, we should wait or listen to its loading state.
    // Ideally, we listen to activeGroup.

    ever(_groupController.activeGroup, _loadDataForGroup);

    // Initial load attempt
    _loadDataForGroup(_groupController.activeGroup.value);
  }

  void _loadDataForGroup(GroupModel? group) {
    if (group != null) {
      isLoading.value = true;

      // Bind the stream
      recurringExpenses.bindStream(
          _expenseRepository.getRecurringExpensesStream(group.id)
      );

      // Check for due bills with a slight delay
      Future.delayed(const Duration(seconds: 1), () {
        checkAndProcessDueExpenses();
        isLoading.value = false;
      });

    } else {
      // NO GROUP SELECTED
      recurringExpenses.clear();
      isLoading.value = false; // Stop loading immediately
    }
  }

  Future<void> checkAndProcessDueExpenses() async {
    final groupId = _groupController.activeGroup.value?.id;
    if (groupId == null) return;

    if (recurringExpenses.isEmpty) return;

    debugPrint("--- RECURRING ENGINE: Checking for due expenses in group $groupId ---");

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var template in recurringExpenses) {
      final due = DateTime(template.nextDueDate.year, template.nextDueDate.month, template.nextDueDate.day);

      if (due.isBefore(today) || due.isAtSameMomentAs(today)) {
        debugPrint("--- RECURRING ENGINE: Processing '${template.description}' ---");

        try {
          // 1. Create the Real Expense
          await _expenseRepository.addExpense(
            groupId: groupId,
            description: template.description,
            totalAmount: template.amount,
            date: DateTime.now(),
            paidById: template.paidBy,
            splitBetween: template.split,
            category: 'Recurring',
          );

          // 2. Calculate Next Due Date
          DateTime nextDate = template.nextDueDate;
          switch (template.frequency.toLowerCase()) {
            case 'weekly':
              nextDate = nextDate.add(const Duration(days: 7));
              break;
            case 'monthly':
              int nextMonth = nextDate.month + 1;
              int nextYear = nextDate.year;
              if (nextMonth > 12) {
                nextMonth = 1;
                nextYear++;
              }
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

          Get.snackbar('Auto-Expense', 'Recurring bill "${template.description}" generated.');

          // 5. TRIGGER WHATSAPP REMINDER (Premium Feature Logic)
          if (template.whatsappNumber != null && template.whatsappNumber!.isNotEmpty) {
            Get.defaultDialog(
                title: "Send Reminder?",
                middleText: "Do you want to notify the group via WhatsApp regarding '${template.description}'?",
                textConfirm: "Open WhatsApp",
                textCancel: "No",
                confirmTextColor: Colors.white,
                buttonColor: Colors.green,
                onConfirm: () {
                  Get.back(); // Close dialog
                  _notificationService.sendWhatsAppMessage(
                      phoneNumber: template.whatsappNumber!,
                      message: "ExpensEase Alert: The recurring bill '${template.description}' of \$${template.amount} has been automatically recorded. Please check your balances."
                  );
                }
            );
          }

        } catch (e) {
          debugPrint("!!! RECURRING ERROR: $e");
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
      Get.snackbar('Error', 'No active group found.');
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
      Get.snackbar('Success', 'Recurring expense scheduled!');
    } catch (e) {
      Get.snackbar('Error', e.toString());
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
      Get.snackbar('Success', 'Recurring expense deleted.');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}