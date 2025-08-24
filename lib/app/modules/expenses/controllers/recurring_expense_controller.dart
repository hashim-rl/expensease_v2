import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/data/models/recurring_expense_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class RecurringExpenseController extends GetxController {
  final isLoading = true.obs;
  final recurringExpenses = <RecurringExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecurringExpenses();
  }

  void fetchRecurringExpenses() {
    isLoading.value = true;
    // TODO: Replace with a real repository call to fetch data from Firestore
    Future.delayed(const Duration(seconds: 1), () {
      recurringExpenses.value = [
        RecurringExpenseModel(
          id: '1',
          groupId: 'g1',
          description: 'Monthly Rent',
          amount: 600.0,
          frequency: 'Monthly',
          nextDueDate: Timestamp.fromDate(DateTime(2025, 9, 1)),
        ),
        RecurringExpenseModel(
          id: '2',
          groupId: 'g1',
          description: 'Netflix Subscription',
          amount: 15.99,
          frequency: 'Monthly',
          nextDueDate: Timestamp.fromDate(DateTime(2025, 8, 15)),
        ),
      ];
      isLoading.value = false;
    });
  }

  void deleteRecurringExpense(String id) {
    // TODO: Call repository to delete this recurring expense template from Firestore
    recurringExpenses.removeWhere((expense) => expense.id == id);
    Get.snackbar('Success', 'Recurring expense has been deleted.');
  }
}