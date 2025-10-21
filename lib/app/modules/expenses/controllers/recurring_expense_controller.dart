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
    ever(_groupController.activeGroup, (group) {
      if (group != null && !group.isLocal) {
        isLoading.value = true;
        recurringExpenses.bindStream(_expenseRepository.getRecurringExpensesStream(group.id));
        isLoading.value = false;
      } else {
        recurringExpenses.clear();
        isLoading.value = false;
      }
    });

    final initialGroup = _groupController.activeGroup.value;
    if (initialGroup != null && !initialGroup.isLocal) {
      isLoading.value = true;
      recurringExpenses.bindStream(_expenseRepository.getRecurringExpensesStream(initialGroup.id));
      isLoading.value = false;
    } else {
      recurringExpenses.clear();
      isLoading.value = false;
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
      Get.back(); 
      Get.snackbar('Success', 'Recurring expense "$description" has been scheduled!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save recurring expense: ${e.toString()}');
    }
  }

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
      Get.snackbar('Success', 'Recurring expense template has been deleted.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete template: ${e.toString()}');
    }
  }
}