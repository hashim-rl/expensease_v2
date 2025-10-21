import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/shared/services/currency_service.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/expenses/controllers/recurring_expense_controller.dart'; // NEW IMPORT

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository;
  final CurrencyService _currencyService = CurrencyService();
  // NEW: Inject Recurring Controller to use its creation method
  final RecurringExpenseController _recurringController = Get.find<RecurringExpenseController>();

  ExpenseController({
    required ExpenseRepository expenseRepository,
  }) : _expenseRepository = expenseRepository;

  // NEW: Form Key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late GroupModel group;

  // Form controllers
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final whatsappNumberController = TextEditingController(); // NEW: For recurring reminders

  // Reactive values
  final isLoading = true.obs;
  final splitMethod = 'Split Equally'.obs;
  final selectedPayerUid = Rx<String?>(null);
  final participantShares = <String, int>{}.obs;
  final members = <UserModel>[].obs;
  final selectedCategory = 'General'.obs;
  final isRecurring = false.obs;
  final selectedCurrency = 'USD'.obs;

  // NEW: Recurring specific fields
  final selectedFrequency = 'Monthly'.obs;
  final selectedNextDueDate = Rx<DateTime?>(null);


  @override
  void onInit() {
    super.onInit();
    _initializeExpenseData();
  }

  void _initializeExpenseData() {
    isLoading.value = true;
    try {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      final args = Get.arguments as Map<String, dynamic>?;

      if (args == null) {
        throw Exception("No arguments passed to the expense screen.");
      }

      // ✅ Extract group and members
      final groupFromArgs = args['group'] as GroupModel?;
      final membersFromArgs = args['members'] as List<UserModel>?;

      if (groupFromArgs == null || membersFromArgs == null) {
        throw Exception("Group or member data missing from arguments.");
      }

      group = groupFromArgs;
      members.assignAll(membersFromArgs);

      // Set default category if provided
      if (args['category'] != null) {
        selectedCategory.value = args['category'] as String;
      }

      // Set default date and next due date
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      selectedNextDueDate.value = DateTime.now().add(const Duration(days: 1)); // Default to tomorrow

      // ✅ Select default payer
      if (currentUserUid != null &&
          members.any((m) => m.uid == currentUserUid)) {
        selectedPayerUid.value = currentUserUid;
      } else if (members.isNotEmpty) {
        selectedPayerUid.value = members.first.uid;
      }

      // Give each member 1 share initially (unless proportional split is active)
      if (group.type != 'Couple' || group.incomeSplitRatio == null) {
        participantShares.assignAll({
          for (var member in members) member.uid: 1,
        });
      } else {
        // Couples mode special case: Default to proportional split
        splitMethod.value = 'Proportional';
        participantShares.assignAll({
          for (var member in members) member.uid: 1, // Still initialize for UI, actual split uses ratio
        });
      }

      debugPrint(
          "ExpenseController initialized with ${members.length} members in group ${group.name}");
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize: \${e.toString()}');
      debugPrint("ERROR initializing ExpenseController: \$e");
    } finally {
      isLoading.value = false;
    }
  }

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
    // 1. Validate form input
    if (formKey.currentState?.validate() == false) return;
    if (isLoading.value) return;

    final totalAmount = double.tryParse(amountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    final totalShares = participantShares.values.fold<int>(0, (sum, shares) => sum + shares);
    if (totalShares == 0 && (group.type != 'Couple' || splitMethod.value != 'Proportional')) {
      Get.snackbar('No Participants', 'Please select at least one participant.');
      return;
    }

    isLoading.value = true;
    try {
      double finalAmount = totalAmount;

      // 2. Currency conversion (Trip groups only)
      if (group.type == 'Trip' && selectedCurrency.value != 'USD') {
        final rate = await _currencyService.getConversionRate(selectedCurrency.value, 'USD');
        finalAmount = totalAmount * rate;
      }

      // 3. Determine final split based on mode
      final Map<String, double> finalSplit = {};

      // --- CRITICAL FIX 1: COUPLES MODE PROPORTIONAL SPLIT ---
      if (group.type == 'Couple' && splitMethod.value == 'Proportional' && group.incomeSplitRatio != null) {
        final ratio = group.incomeSplitRatio!; // Map<UID, Ratio>
        for (var memberId in group.memberIds) {
          finalSplit[memberId] = finalAmount * (ratio[memberId] ?? 0.5); // Default to 50/50 if ratio missing
        }
      } else {
        // --- STANDARD EQUAL/SHARE SPLIT ---
        if (totalShares > 0) {
          final double perShareAmount = finalAmount / totalShares;
          for (var entry in participantShares.entries) {
            if (entry.value > 0) {
              finalSplit[entry.key] = perShareAmount * entry.value;
            }
          }
        }
      }

      // 4. Decide between recurring template creation or single expense
      if (isRecurring.value) {
        // --- CRITICAL FIX 2: RECURRING EXPENSE CREATION ---
        await _recurringController.createRecurringExpense(
          description: descriptionController.text.trim(),
          amount: totalAmount, // Send original amount
          paidBy: selectedPayerUid.value!,
          split: finalSplit,
          frequency: selectedFrequency.value,
          nextDueDate: selectedNextDueDate.value!,
          whatsappNumber: whatsappNumberController.text.trim().isNotEmpty ? whatsappNumberController.text.trim() : null,
        );
      } else {
        // --- SINGLE EXPENSE CREATION ---
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
      debugPrint("ERROR adding expense: \$e");
      Get.snackbar('Error', 'Failed to add expense: \${e.toString()}');
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

  // NEW: Date picker for recurring expense next due date
  void selectNextDueDate() async {
    DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedNextDueDate.value ?? DateTime.now().add(const Duration(days: 1)),
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
    whatsappNumberController.dispose(); // NEW: Dispose new controller
    super.onClose();
  }
}