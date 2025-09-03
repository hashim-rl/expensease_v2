import 'dart:developer'; // Import the developer library for logging
import 'package:get/get.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';

class ProfileController extends GetxController {
  // Repositories
  final UserRepository _userRepository;
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  // Constructor to receive/inject the repositories
  ProfileController({
    required UserRepository userRepository,
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _userRepository = userRepository,
        _groupRepository = groupRepository,
        _expenseRepository = expenseRepository;

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
    try {
      currentUser.value = await _userRepository.getCurrentUser();

      if (currentUser.value != null) {
        final groups = await _groupRepository.getGroupsStream().first;
        final allExpenses = <ExpenseModel>[];

        for (var group in groups) {
          try {
            log('Processing Group ID: ${group.id}'); // DEBUG LOG
            final groupExpenses = await _expenseRepository
                .getExpensesStreamForGroup(group.id)
                .first;
            allExpenses.addAll(groupExpenses);
          } catch (e) {
            log('Error loading expenses for group ${group.id}: $e'); // ERROR LOG
            // Continue to the next group instead of crashing
          }
        }

        _calculateFinancialSummary(allExpenses);
        // Sort expenses only after calculation
        allExpenses.sort((a, b) {
          // Add null checks for date comparison to be safe
          final dateA = a.date;
          final dateB = b.date;
          return dateB.compareTo(dateA);
        });
        recentExpenses.value = allExpenses.take(10).toList();
      }
    } catch (e) {
      log('Error in loadAllProfileData: $e'); // TOP-LEVEL ERROR LOG
      // You might want to show a user-friendly error message here
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
      try {
        log('Processing Expense ID: ${expense.id}'); // DEBUG LOG
        // Defensive check for null on totalAmount
        final totalAmount = expense.totalAmount;

        if (expense.paidById == userId) {
          calculatedNetBalance += totalAmount;
        }

        // Defensive check for null on splitBetween map and the user's share
        final userShare = expense.splitBetween[userId] ?? 0.0;
        calculatedNetBalance -= userShare;
        calculatedTotalSpent += userShare;
      } catch (e) {
        log('Error calculating summary for expense ${expense.id}: $e'); // ERROR LOG
        // Continue to the next expense
      }
    }

    netBalance.value = calculatedNetBalance;
    totalSpent.value = calculatedTotalSpent;
  }
}