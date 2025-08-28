import 'package:get/get.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';

class ProfileController extends GetxController {
  // Repositories
  final UserRepository _userRepository = Get.find<UserRepository>();
  final GroupRepository _groupRepository = Get.find<GroupRepository>();
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();

  // Observables for UI state
  final isLoading = true.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final recentExpenses = <ExpenseModel>[].obs;
  final netBalance = 0.0.obs;
  final totalSpent = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllProfileData();
  }

  Future<void> loadAllProfileData() async {
    isLoading.value = true;

    currentUser.value = await _userRepository.getCurrentUser();

    if (currentUser.value != null) {
      final groups = await _groupRepository.getGroupsStream().first;
      final allExpenses = <ExpenseModel>[];

      for (var group in groups) {
        final groupExpenses =
        await _expenseRepository.getExpensesStreamForGroup(group.id).first;
        allExpenses.addAll(groupExpenses);
      }

      _calculateFinancialSummary(allExpenses);
      allExpenses.sort((a, b) => b.date.compareTo(a.date));
      recentExpenses.value = allExpenses.take(10).toList();
    }

    isLoading.value = false;
  }

  void _calculateFinancialSummary(List<ExpenseModel> allExpenses) {
    double calculatedNetBalance = 0.0;
    double calculatedTotalSpent = 0.0;
    final userId = _userRepository.getCurrentUserId();

    if (userId == null) return;

    for (var expense in allExpenses) {
      if (expense.paidById == userId) {
        calculatedNetBalance += expense.totalAmount;
      }
      final userShare = expense.splitBetween[userId] ?? 0.0;
      calculatedNetBalance -= userShare;
      calculatedTotalSpent += userShare;
    }

    netBalance.value = calculatedNetBalance;
    totalSpent.value = calculatedTotalSpent;
  }
}