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

  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();

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
    // --- THIS IS THE FIX ---
    // We delay the initialization by a single frame. This solves a race
    // condition in GetX where the controller's onInit can run *before*
    // Get.arguments is ready. This is the deep issue we were missing.
    Future.delayed(Duration.zero, () {
      _initializeExpenseData();
    });
  }

  Future<void> _initializeExpenseData() async {
    isLoading.value = true;
    try {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      final dynamic args = Get.arguments;
      GroupModel? groupFromArgs;

      if (args == null) {
        throw Exception("Arguments are null. Navigation failed.");
      }

      if (args is GroupModel) {
        groupFromArgs = args;
      } else if (args is Map<String, dynamic>) {
        groupFromArgs = args['group'] as GroupModel?;
        if (args['category'] != null) {
          selectedCategory.value = args['category'] as String;
        }
      }

      if (groupFromArgs == null) {
        throw Exception("Group data is missing from arguments.");
      }

      group = groupFromArgs;

      await _fetchMemberDetails();

      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (currentUserUid != null &&
          members.any((m) => m.uid == currentUserUid)) {
        selectedPayerUid.value = currentUserUid;
      } else if (members.isNotEmpty) {
        selectedPayerUid.value = members.first.uid;
      } else {
        selectedPayerUid.value = null;
      }

      participantShares.assignAll({for (var member in members) member.uid: 1});

      if (group.type == 'Couple' && group.incomeSplitRatio != null) {
        splitMethod.value = 'Proportional';
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize screen: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMemberDetails() async {
    if (group.memberIds.isNotEmpty) {
      final memberDetails =
      await _groupRepository.getMembersDetails(group.memberIds);
      members.value = memberDetails;
    } else {
      members.value = [];
    }
  }

  void addShare(String uid) {
    participantShares[uid] = (participantShares[uid] ?? 0) + 1;
  }

  void removeShare(String uid) {
    if (participantShares[uid] != null && participantShares[uid]! > 0) {
      participantShares[uid] = participantShares[uid]! - 1;
    }
  }

  Future<void> addExpense() async {
    if (isLoading.value) return;
    if (selectedPayerUid.value == null) {
      Get.snackbar('Error', 'Please select who paid.');
      return;
    }

    final double? totalAmount = double.tryParse(amountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    final totalShares =
    participantShares.values.fold(0, (sum, shares) => sum + shares);
    if (totalShares == 0) {
      Get.snackbar('No Participants', 'Please select at least one participant.');
      return;
    }

    isLoading.value = true;
    try {
      double finalAmount = totalAmount;
      if (group.type == 'Trip' && selectedCurrency.value != 'USD') {
        final rate = await _currencyService.getConversionRate(
            selectedCurrency.value, 'USD');
        finalAmount = totalAmount * rate;
      }

      final double perShareAmount = finalAmount / totalShares;
      final Map<String, double> finalSplit = {
        for (var entry in participantShares.entries)
          if (entry.value > 0) entry.key: perShareAmount * entry.value
      };

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