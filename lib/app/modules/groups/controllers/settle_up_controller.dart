import 'package:flutter/material.dart'; // Added for Colors/Snackbar
import 'package:get/get.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/models/expense_model.dart'; // Added

class SettleUpController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();

  final transactions = <SimpleTransaction>[].obs;
  final isSettling = false.obs;
  final isLoading = true.obs; // Added loading state

  // Local context data
  late GroupModel group;
  late List<UserModel> members;

  // Raw balances for reference: { 'userUid': 50.0 }
  final memberBalances = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() {
    final args = Get.arguments as Map<String, dynamic>?;

    if (args == null) {
      Get.snackbar('Error', 'Initialization failed. No arguments passed.');
      return;
    }

    try {
      // 1. Extract Context
      group = args['group'] as GroupModel;
      members = args['members'] as List<UserModel>;

      // 2. Fetch Fresh Data & Calculate
      _calculateDebts();

    } catch (e) {
      Get.snackbar('Error', 'Failed to load settlement data: $e');
    }
  }

  Future<void> _calculateDebts() async {
    isLoading.value = true;
    try {
      // Fetch all expenses for this group fresh from the DB
      // We assume getExpensesForReport (or similar) fetches all expenses
      // If you don't have a direct "getAll" method, we can listen to the stream once.
      final expensesStream = _expenseRepository.getExpensesStreamForGroup(group.id);
      final expenses = await expensesStream.first; // Get current snapshot

      final balances = <String, double>{};

      // Initialize all members with 0.0
      for (var member in members) {
        balances[member.uid] = 0.0;
      }

      // --- THE CORE MATH ---
      for (var expense in expenses) {
        // Payer gets POSITIVE balance (They are owed money)
        final payerId = expense.paidById;
        balances[payerId] = (balances[payerId] ?? 0.0) + expense.totalAmount;

        // Splitters get NEGATIVE balance (They owe money)
        expense.splitBetween.forEach((uid, amount) {
          balances[uid] = (balances[uid] ?? 0.0) - amount;
        });
      }

      memberBalances.value = balances;

      // 3. Simplify
      if (balances.isNotEmpty) {
        transactions.value = DebtSimplifier.simplify(balances);
      }

    } catch (e) {
      print("Calculation Error: $e");
      Get.snackbar('Error', 'Could not calculate debts.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordPayment(String fromUid, String toUid, double amount) async {
    isSettling.value = true;

    try {
      await _expenseRepository.addPaymentExpense(
        groupId: group.id,
        payerUid: fromUid,
        recipientUid: toUid,
        amount: amount,
      );

      // Refresh data after payment
      await _calculateDebts();

      Get.snackbar('Success', 'Payment recorded successfully.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Payment Failed', e.toString());
    } finally {
      isSettling.value = false;
    }
  }

  // --- Helpers for the View ---

  String getCurrency() {
    return group.currency ?? 'USD';
  }

  String getMemberName(String uid) {
    final member = members.firstWhere(
          (m) => m.uid == uid,
      orElse: () => UserModel(uid: uid, email: '', fullName: 'Unknown', nickname: 'User'),
    );
    return member.nickname;
  }
}