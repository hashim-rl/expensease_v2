import 'dart:async'; // Added for Timer (Debounce)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/shared/services/currency_service.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/expenses/controllers/recurring_expense_controller.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository;
  final CurrencyService _currencyService = CurrencyService();
  final RecurringExpenseController _recurringController =
  Get.find<RecurringExpenseController>();

  ExpenseController({
    required ExpenseRepository expenseRepository,
  }) : _expenseRepository = expenseRepository;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late GroupModel group;

  // Form controllers
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final whatsappNumberController = TextEditingController();

  // --- NEW: Controllers for Unequal Split (Exact Amounts) ---
  final unequalSplitControllers = <String, TextEditingController>{}.obs;
  final remainingAmount = 0.0.obs; // To show user how much is left to assign
  Timer? _debounce;
  // -----------------------------------------------------------

  // Reactive values
  final isLoading = true.obs;
  final splitMethod = 'Split Equally'.obs;
  final selectedPayerUid = Rx<String?>(null);
  final participantShares = <String, int>{}.obs;
  final members = <UserModel>[].obs;
  final selectedCategory = 'General'.obs;
  final isRecurring = false.obs;
  final selectedCurrency = 'USD'.obs; // The currency of the RECEIPT

  // Recurring specific fields
  final selectedFrequency = 'Monthly'.obs;
  final selectedNextDueDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeExpenseData();

    // Listen to amount changes to update "remaining" calculation for unequal splits
    amountController.addListener(_updateRemainingAmount);
  }

  void _initializeExpenseData() {
    isLoading.value = true;
    try {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      final args = Get.arguments as Map<String, dynamic>?;

      if (args == null) throw Exception("No arguments passed.");

      final groupFromArgs = args['group'] as GroupModel?;
      final membersFromArgs = args['members'] as List<UserModel>?;

      if (groupFromArgs == null || membersFromArgs == null) {
        throw Exception("Group details missing.");
      }

      group = groupFromArgs;
      members.assignAll(membersFromArgs);

      if (args['category'] != null) {
        selectedCategory.value = args['category'] as String;
      }

      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      selectedNextDueDate.value = DateTime.now().add(const Duration(days: 1));

      // Default Payer
      if (currentUserUid != null && members.any((m) => m.uid == currentUserUid)) {
        selectedPayerUid.value = currentUserUid;
      } else if (members.isNotEmpty) {
        selectedPayerUid.value = members.first.uid;
      }

      // Initialize Split Method
      if (group.incomeSplitRatio != null && group.incomeSplitRatio!.isNotEmpty) {
        splitMethod.value = 'Proportional';
      } else {
        splitMethod.value = 'Split Equally';
      }

      // Initialize Shares (for "By Shares")
      participantShares.assignAll({
        for (var member in members) member.uid: 1,
      });

      // --- NEW: Initialize Unequal Controllers ---
      for (var member in members) {
        unequalSplitControllers[member.uid] = TextEditingController(text: '0.00');
        // Add listener to recalculate remaining amount when user types
        unequalSplitControllers[member.uid]!.addListener(_updateRemainingAmount);
      }
      // -------------------------------------------

    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // --- NEW: Helper to calculate remaining amount for Unequal splits ---
  void _updateRemainingAmount() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (splitMethod.value == 'Unequally') {
        double total = double.tryParse(amountController.text) ?? 0.0;
        double assigned = 0.0;
        unequalSplitControllers.forEach((_, controller) {
          assigned += double.tryParse(controller.text) ?? 0.0;
        });
        remainingAmount.value = total - assigned;
      }
    });
  }
  // -------------------------------------------------------------------

  void addShare(String uid) {
    participantShares[uid] = (participantShares[uid] ?? 0) + 1;
    participantShares.refresh();
  }

  void removeShare(String uid) {
    if ((participantShares[uid] ?? 0) > 0) {
      participantShares[uid] = participantShares[uid]! - 1;
      participantShares.refresh();
    }
  }

  Future<void> addExpense() async {
    if (formKey.currentState?.validate() == false) return;
    if (isLoading.value) return;

    final inputAmount = double.tryParse(amountController.text);
    if (inputAmount == null || inputAmount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    // Validation for Unequal Splits
    if (splitMethod.value == 'Unequally') {
      // Use a small epsilon for float comparison
      if (remainingAmount.value.abs() > 0.01) {
        Get.snackbar('Split Mismatch', 'The assigned amounts do not match the total. Remaining: ${remainingAmount.value.toStringAsFixed(2)}');
        return;
      }
    } else if (splitMethod.value != 'Proportional') {
      final totalShares = participantShares.values.fold<int>(0, (sum, shares) => sum + shares);
      if (totalShares == 0) {
        Get.snackbar('No Participants', 'Please select at least one participant.');
        return;
      }
    }

    isLoading.value = true;
    try {
      double finalAmount = inputAmount;

      // --- UPDATED: Dynamic Currency Conversion ---
      // Assumes group.currency exists (e.g., 'EUR', 'GBP').
      // If GroupModel doesn't have 'currency', add it or default to 'USD'.
      String targetCurrency = group.currency ?? 'USD';

      if (group.type == 'Trip' && selectedCurrency.value != targetCurrency) {
        final rate = await _currencyService.getConversionRate(
            selectedCurrency.value, targetCurrency);
        finalAmount = inputAmount * rate;
      }
      // ---------------------------------------------

      final Map<String, double> finalSplit = {};

      // --- LOGIC BRANCHING ---
      if (splitMethod.value == 'Proportional' &&
          group.incomeSplitRatio != null &&
          group.incomeSplitRatio!.isNotEmpty) {

        final ratio = group.incomeSplitRatio!;
        for (var memberId in group.memberIds) {
          finalSplit[memberId] = finalAmount * (ratio[memberId] ?? 0.0);
        }

      } else if (splitMethod.value == 'Unequally') {
        // --- NEW: Handle Unequal Logic ---
        // We must normalize the unequal amounts if currency conversion happened
        // Or simply apply the ratio of (UserAmount / TotalInput) * FinalAmount

        unequalSplitControllers.forEach((uid, controller) {
          double userAmount = double.tryParse(controller.text) ?? 0.0;
          if (userAmount > 0) {
            if (finalAmount != inputAmount) {
              // If currency was converted, we calculate the percentage and apply to final
              double percent = userAmount / inputAmount;
              finalSplit[uid] = finalAmount * percent;
            } else {
              finalSplit[uid] = userAmount;
            }
          }
        });
        // --------------------------------

      } else {
        // Standard Equal/Shares
        final totalShares = participantShares.values.fold<int>(0, (sum, shares) => sum + shares);
        if (totalShares > 0) {
          final double perShareAmount = finalAmount / totalShares;
          for (var entry in participantShares.entries) {
            if (entry.value > 0) {
              finalSplit[entry.key] = perShareAmount * entry.value;
            }
          }
        }
      }

      // Create Expense (Recurring or Single)
      if (isRecurring.value) {
        await _recurringController.createRecurringExpense(
          description: descriptionController.text.trim(),
          amount: finalAmount, // Store the converted amount
          paidBy: selectedPayerUid.value!,
          split: finalSplit,
          frequency: selectedFrequency.value,
          nextDueDate: selectedNextDueDate.value!,
          whatsappNumber: whatsappNumberController.text.trim().isNotEmpty
              ? whatsappNumberController.text.trim()
              : null,
        );
      } else {
        await _expenseRepository.addExpense(
          groupId: group.id,
          description: descriptionController.text.trim(),
          totalAmount: finalAmount,
          date: DateFormat('yyyy-MM-dd').parse(dateController.text),
          paidById: selectedPayerUid.value!,
          splitBetween: finalSplit,
          category: selectedCategory.value,
        );
      }

      Get.back();
      Get.snackbar('Success!', 'Expense added successfully.');
    } catch (e) {
      debugPrint("ERROR adding expense: $e");
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

  void selectNextDueDate() async {
    DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedNextDueDate.value ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      selectedNextDueDate.value = picked;
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    dateController.dispose();
    whatsappNumberController.dispose();
    // Dispose dynamic controllers
    for (var controller in unequalSplitControllers.values) {
      controller.dispose();
    }
    _debounce?.cancel();
    super.onClose();
  }
}