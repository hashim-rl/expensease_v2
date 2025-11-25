import 'dart:developer';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository;
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  ProfileController({
    required UserRepository userRepository,
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _userRepository = userRepository,
        _groupRepository = groupRepository,
        _expenseRepository = expenseRepository;

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

  /// Fetches user data and aggregates financials from ALL groups.
  /// This gives the "Global" view of the user's financial health.
  Future<void> loadAllProfileData() async {
    isLoading.value = true;
    try {
      currentUser.value = await _userRepository.getCurrentUser();

      if (currentUser.value != null) {
        // 1. Get all groups the user is in
        final groups = await _groupRepository.getGroupsStream().first;
        final allExpenses = <ExpenseModel>[];

        // 2. Iterate groups to fetch expenses (MVP Approach)
        // In a large-scale app, we would calculate this server-side.
        for (var group in groups) {
          try {
            final groupExpenses = await _expenseRepository
                .getExpensesStreamForGroup(group.id)
                .first;
            allExpenses.addAll(groupExpenses);
          } catch (e) {
            log('Error loading expenses for group ${group.id}: $e');
          }
        }

        // 3. Calculate Totals
        _calculateFinancialSummary(allExpenses);

        // 4. Sort and Store Recent
        allExpenses.sort((a, b) => b.date.compareTo(a.date));
        recentExpenses.value = allExpenses.take(10).toList();
      }
    } catch (e) {
      log('Error in loadAllProfileData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateFinancialSummary(List<ExpenseModel> allExpenses) {
    double calculatedNetBalance = 0.0;
    double calculatedTotalSpent = 0.0;
    final userId = _userRepository.getCurrentUserId();

    if (userId == null) return;

    for (var expense in allExpenses) {
      // Skip payment records for "Spending" calculation, but keep for "Balance"
      final isPayment = expense.category == 'Payment';

      // How much did I pay?
      if (expense.paidById == userId) {
        calculatedNetBalance += expense.totalAmount;
      }

      // How much was I responsible for?
      final myShare = expense.splitBetween[userId] ?? 0.0;

      if (myShare > 0) {
        calculatedNetBalance -= myShare;
        if (!isPayment) {
          calculatedTotalSpent += myShare;
        }
      }
    }

    netBalance.value = calculatedNetBalance;
    totalSpent.value = calculatedTotalSpent;
  }
}