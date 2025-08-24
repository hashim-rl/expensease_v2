import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'dart:async';

class GroupDashboardController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // --- STATE MANAGEMENT ---
  final Rx<GroupModel?> group = Rx<GroupModel?>(null);
  final expenses = <ExpenseModel>[].obs;
  final memberBalances = <String, double>{}.obs;
  final isLoading = true.obs;
  StreamSubscription? _expenseSubscription;

  // ✅ NEW: State variables for the stylish header card
  final totalGroupSpent = 0.0.obs;
  final currentUserShare = 0.0.obs;

  // --- COUPLES MODE STATE ---
  final partnerARatio = 0.5.obs;
  final partnerBRatio = 0.5.obs;
  final monthlySavingsGoal = 1000.0.obs;
  final currentSavings = 300.0.obs;

  @override
  void onInit() {
    super.onInit();
    final groupArg = Get.arguments as GroupModel?;
    if (groupArg == null) {
      isLoading.value = false;
      Get.snackbar("Error", "Could not load group data. Please go back.");
      return;
    }
    group.value = groupArg;
    _fetchGroupExpenses();
  }

  /// Fetches a live stream of expenses for the current group.
  void _fetchGroupExpenses() {
    isLoading.value = true;
    _expenseSubscription?.cancel();

    _expenseSubscription = _expenseRepository
        .getExpensesStreamForGroup(group.value!.id)
        .listen((expenseList) {
      expenses.value = expenseList;
      // This single function now calculates everything we need.
      _processExpenseData();
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to load expenses.");
    });
  }

  /// ✅ NEW: A single function to calculate all derived data from the expense list.
  void _processExpenseData() {
    if (group.value == null) return;

    double newTotalSpent = 0.0;
    double newUserShare = 0.0;
    final newBalances = <String, double>{};

    for (var memberId in group.value!.memberIds) {
      newBalances[memberId] = 0.0;
    }

    for (var expense in expenses) {
      newTotalSpent += expense.totalAmount;

      // Calculate balances
      if (newBalances.containsKey(expense.paidById)) {
        newBalances[expense.paidById] = newBalances[expense.paidById]! + expense.totalAmount;
      }
      for (var entry in expense.splitBetween.entries) {
        final participantId = entry.key;
        final share = entry.value;
        if (newBalances.containsKey(participantId)) {
          newBalances[participantId] = newBalances[participantId]! - share;
        }
        // Calculate current user's share
        if (participantId == _currentUserId) {
          newUserShare += share;
        }
      }
    }
    // Update all state variables at once
    totalGroupSpent.value = newTotalSpent;
    currentUserShare.value = newUserShare;
    memberBalances.value = newBalances;
  }

  void updateIncomeRatio(double newPartnerARatio) {
    partnerARatio.value = newPartnerARatio;
    partnerBRatio.value = 1.0 - newPartnerARatio;
    // TODO: Add logic to save this ratio to the group in Firestore
  }

  @override
  void onClose() {
    _expenseSubscription?.cancel();
    super.onClose();
  }
}