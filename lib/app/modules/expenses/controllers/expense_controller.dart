import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/shared/services/currency_service.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _repository = ExpenseRepository();
  final CurrencyService _currencyService = CurrencyService();

  late final GroupModel group;

  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();

  final isLoading = false.obs;
  final splitMethod = 'Split Equally'.obs;
  final selectedPayerUid = ''.obs;
  final participantShares = <String, int>{}.obs;

  // Note: Currency and recurring fields are not used in the updated addExpense method,
  // but can be kept here for UI state if needed later.
  final isRecurring = false.obs;
  final selectedCurrency = 'USD'.obs;


  @override
  void onInit() {
    super.onInit();
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    group = Get.arguments as GroupModel;

    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (currentUserUid != null) {
      selectedPayerUid.value = currentUserUid;
    }

    participantShares.assignAll({
      for (var memberId in group.memberIds) memberId: 1
    });

    // FIX 1: Changed groupType to type
    if (group.type == 'Couple' && group.incomeSplitRatio != null) {
      splitMethod.value = 'Proportional';
    }
  }

  void toggleParticipant(String uid) {
    participantShares[uid] = (participantShares[uid]! > 0) ? 0 : 1;
  }

  void toggleGuestStatus(String uid) {
    if (participantShares[uid]! == 1) {
      participantShares[uid] = 2;
    } else if (participantShares[uid]! == 2) {
      participantShares[uid] = 1;
    }
  }

  Future<void> addExpense() async {
    if (isLoading.value) return;

    final double? totalAmount = double.tryParse(amountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    final totalShares = participantShares.values.fold(0, (sum, shares) => sum + shares);
    if (totalShares == 0) {
      Get.snackbar('No Participants', 'Please select at least one participant.');
      return;
    }

    isLoading.value = true;
    try {
      // Currency conversion logic can remain if needed for UI, but won't be saved directly
      double finalAmount = totalAmount;
      if (group.type == 'Trip' && selectedCurrency.value != 'USD') {
        final rate = await _currencyService.getConversionRate(selectedCurrency.value, 'USD');
        finalAmount = totalAmount * rate;
      }

      final double perShareAmount = finalAmount / totalShares;
      final Map<String, double> finalSplit = {
        for (var entry in participantShares.entries)
          if (entry.value > 0) entry.key: perShareAmount * entry.value
      };

      await _repository.addExpense(
        groupId: group.id,
        description: descriptionController.text.trim(),
        totalAmount: finalAmount,
        date: DateFormat('yyyy-MM-dd').parse(dateController.text),
        // FIX 2: Renamed paidBy to paidById
        paidById: selectedPayerUid.value,
        // FIX 3: Renamed split to splitBetween
        splitBetween: finalSplit,
        // FIX 4: Removed parameters that no longer exist in the repository method
        // originalAmount, originalCurrency, isRecurring are no longer passed
      );

      Get.back();
      Get.snackbar('Success!', 'Expense added successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void selectDate() async {
    DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.onClose();
  }
}