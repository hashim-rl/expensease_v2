import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'dart:async';

class GroupDashboardController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final Rx<GroupModel?> group = Rx<GroupModel?>(null);
  final expenses = <ExpenseModel>[].obs;
  final memberBalances = <String, double>{}.obs;
  final isLoading = true.obs;
  StreamSubscription? _expenseSubscription;

  final totalGroupSpent = 0.0.obs;
  final currentUserShare = 0.0.obs;
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

  void _fetchGroupExpenses() {
    isLoading.value = true;
    _expenseSubscription?.cancel();

    _expenseSubscription = _expenseRepository
        .getExpensesStreamForGroup(group.value!.id)
        .listen((expenseList) {
      expenses.value = expenseList;
      _processExpenseData();
      isLoading.value = false;
    }, onError: (error) {
      // ✅ This will now print the detailed error to your console for better debugging.
      print("Firestore Error: $error");
      isLoading.value = false;
      Get.snackbar("Error", "Failed to load expenses. Check console for details.");
    });
  }

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

      if (newBalances.containsKey(expense.paidById)) {
        newBalances[expense.paidById] =
            newBalances[expense.paidById]! + expense.totalAmount;
      }
      for (var entry in expense.splitBetween.entries) {
        final participantId = entry.key;
        final share = entry.value;
        if (newBalances.containsKey(participantId)) {
          newBalances[participantId] =
              newBalances[participantId]! - share;
        }
        if (participantId == _currentUserId) {
          newUserShare += share;
        }
      }
    }
    totalGroupSpent.value = newTotalSpent;
    currentUserShare.value = newUserShare;
    memberBalances.value = newBalances;
  }

  void updateIncomeRatio(double newPartnerARatio) {
    partnerARatio.value = newPartnerARatio;
    partnerBRatio.value = 1.0 - newPartnerARatio;
  }

  @override
  void onClose() {
    _expenseSubscription?.cancel();
    super.onClose();
  }
}