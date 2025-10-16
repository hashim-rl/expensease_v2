import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensease/app/data/models/recurring_expense_model.dart';
// --- NEW IMPORTS ---
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/services/auth_service.dart';
// -------------------

class RecurringExpenseController extends GetxController {
  // --- INJECTED DEPENDENCIES ---
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final GroupController _groupController = Get.find<GroupController>();
  final AuthService _authService = Get.find<AuthService>();
  // -----------------------------

  final isLoading = true.obs;
  final recurringExpenses = <RecurringExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Bind the recurringExpenses list to the real-time stream from the repository
    _bindRecurringExpensesStream();
  }

  // New binding method to handle group changes
  void _bindRecurringExpensesStream() {
    // Only bind if an active group is selected (standard or guest mode)
    ever(_groupController.activeGroup, (group) {
      if (group != null && !group.isLocal) {
        isLoading.value = true;
        recurringExpenses.bindStream(_expenseRepository.getRecurringExpensesStream(group.id));
        isLoading.value = false;
      } else {
        // Clear list if no group or in guest mode (recurring expenses aren't local)
        recurringExpenses.clear();
        isLoading.value = false;
      }
    });

    // Manually trigger the binding if a group is already active on init
    if (_groupController.activeGroup.value != null && !_groupController.activeGroup.value!.isLocal) {
      _bindRecurringExpensesStream();
    }
  }

  // --- NEW METHOD: Create recurring expense template ---
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
    if (groupId == null || _groupController.activeGroup.value!.isLocal) {
      Get.snackbar('Error', 'Cannot create recurring expense outside of a live group.');
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
      Get.back(); // Assuming this is called from a modal/creation view
      Get.snackbar('Success', 'Recurring expense "${description}" has been scheduled!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save recurring expense: ${e.toString()}');
    }
  }
  // ---------------------------------------------------

  // --- Delete logic ---
  Future<void> deleteRecurringExpense(String id) async {
    final groupId = _groupController.activeGroup.value?.id;
    if (groupId == null || _groupController.activeGroup.value!.isLocal) {
      Get.snackbar('Error', 'Cannot delete recurring expense outside of a live group.');
      return;
    }
    try {
      await _expenseRepository.deleteRecurringExpenseTemplate(
        groupId: groupId,
        templateId: id,
      );
      // The stream will handle the removal from the list automatically
      Get.snackbar('Success', 'Recurring expense template has been deleted.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete template: ${e.toString()}');
    }
  }
}