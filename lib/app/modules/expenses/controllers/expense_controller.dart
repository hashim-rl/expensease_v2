import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/shared/services/currency_service.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository;
  final GroupRepository _groupRepository;
  final CurrencyService _currencyService = CurrencyService();

  ExpenseController({
    required ExpenseRepository expenseRepository,
    required GroupRepository groupRepository,
  })  : _expenseRepository = expenseRepository,
        _groupRepository = groupRepository;

  late GroupModel group;

  // Form controllers
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();

  // Reactive values
  final isLoading = true.obs;
  final splitMethod = 'Split Equally'.obs;
  final selectedPayerUid = Rx<String?>(null);
  final participantShares = <String, int>{}.obs;
  final members = <UserModel>[].obs;
  final selectedCategory = 'General'.obs;
  final isRecurring = false.obs;
  final selectedCurrency = 'USD'.obs;

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

      // Set default date
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // ✅ Select default payer
      if (currentUserUid != null &&
          members.any((m) => m.uid == currentUserUid)) {
        selectedPayerUid.value = currentUserUid;
      } else if (members.isNotEmpty) {
        selectedPayerUid.value = members.first.uid;
      }

      // Give each member 1 share initially
      participantShares.assignAll({
        for (var member in members) member.uid: 1,
      });

      // Couples mode special case
      if (group.type == 'Couple' && group.incomeSplitRatio != null) {
        splitMethod.value = 'Proportional';
      }

      debugPrint(
          "ExpenseController initialized with ${members.length} members in group ${group.name}");
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize: ${e.toString()}');
      debugPrint("ERROR initializing ExpenseController: $e");
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
    if (isLoading.value) return;
    if (selectedPayerUid.value == null) {
      Get.snackbar('Error', 'Please select who paid.');
      return;
    }

    final totalAmount = double.tryParse(amountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    final totalShares =
    participantShares.values.fold<int>(0, (sum, shares) => sum + shares);
    if (totalShares == 0) {
      Get.snackbar('No Participants', 'Please select at least one participant.');
      return;
    }

    isLoading.value = true;
    try {
      double finalAmount = totalAmount;

      // ✅ Currency conversion (Trip groups only)
      if (group.type == 'Trip' && selectedCurrency.value != 'USD') {
        final rate = await _currencyService.getConversionRate(
            selectedCurrency.value, 'USD');
        finalAmount = totalAmount * rate;
      }

      // ✅ Split shares
      final Map<String, double> finalSplit = {};
      if (totalShares > 0) {
        final double perShareAmount = finalAmount / totalShares;
        for (var entry in participantShares.entries) {
          if (entry.value > 0) {
            finalSplit[entry.key] = perShareAmount * entry.value;
          }
        }
      }

      await _expenseRepository.addExpense(
        groupId: group.id,
        description: descriptionController.text.trim(),
        totalAmount: finalAmount,
        date: DateFormat('yyyy-MM-dd').parse(dateController.text),
        paidById: selectedPayerUid.value!,
        splitBetween: finalSplit,
        category: selectedCategory.value,
      );

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

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.onClose();
  }
}
