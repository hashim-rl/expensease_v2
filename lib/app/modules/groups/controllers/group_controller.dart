import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user logic
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/models/user_model.dart';
// --- NEW IMPORT ---
import 'package:expensease/app/data/repositories/expense_repository.dart';
// -------------------

class GroupController extends GetxController {
  final GroupRepository _groupRepository = GroupRepository();
  // --- NEW INJECTION: Required to fetch expenses for calculations ---
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  // -----------------------------------------------------------------

  final groupNameController = TextEditingController();
  final isLoading = true.obs;

  // Observables for live data
  final groups = <GroupModel>[].obs;

  // Stores the Net Balance for each group: { 'groupId': 50.00 }
  // Positive = You are owed. Negative = You owe.
  final groupBalances = <String, double>{}.obs;

  // Holds the currently selected group type
  final selectedGroupType = 'Flatmates'.obs;

  // Holds the selected currency for Trip groups
  final selectedCurrency = 'USD'.obs;

  // Guest/Active Group Management
  final activeGroup = Rx<GroupModel?>(null);
  final localUser = Rx<UserModel?>(null);

  // --- NEW: Subscription Management ---
  StreamSubscription? _groupsSubscription;
  final Map<String, StreamSubscription> _groupExpenseSubscriptions = {};
  // ------------------------------------

  @override
  void onInit() {
    super.onInit();
    // Replaced bindStream with a manual listener to handle nested logic
    _listenToGroups();
  }

  // --- NEW LOGIC ENGINE ---
  void _listenToGroups() {
    isLoading.value = true;
    _groupsSubscription?.cancel();

    _groupsSubscription = _groupRepository.getGroupsStream().listen((groupList) {
      groups.value = groupList;

      // Whenever groups update, we update the expense listeners for them
      _updateExpenseListeners(groupList);

      isLoading.value = false;
    }, onError: (e) {
      print("Error fetching groups: $e");
      isLoading.value = false;
    });
  }

  void _updateExpenseListeners(List<GroupModel> currentGroups) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    // Safety check: if no user is logged in, we can't calculate balances
    if (currentUid == null) return;

    // 1. Cleanup: Cancel listeners for groups that no longer exist
    final currentGroupIds = currentGroups.map((g) => g.id).toSet();
    _groupExpenseSubscriptions.removeWhere((groupId, subscription) {
      if (!currentGroupIds.contains(groupId)) {
        subscription.cancel();
        return true;
      }
      return false;
    });

    // 2. Add Listeners: Calculate balance for each group
    for (var group in currentGroups) {
      if (!_groupExpenseSubscriptions.containsKey(group.id)) {
        final sub = _expenseRepository.getExpensesStreamForGroup(group.id).listen((expenses) {

          double totalPaidByMe = 0.0;
          double myTotalShare = 0.0;

          for (var expense in expenses) {
            // How much money left my pocket?
            if (expense.paidById == currentUid) {
              totalPaidByMe += expense.totalAmount;
            }

            // How much of this expense was "for me"?
            if (expense.splitBetween.containsKey(currentUid)) {
              myTotalShare += expense.splitBetween[currentUid]!;
            }
          }

          // THE FORMULA: Net Balance = (What I Paid) - (What I Consumed)
          final netBalance = totalPaidByMe - myTotalShare;

          // Update the observable map
          groupBalances[group.id] = netBalance;

        });
        _groupExpenseSubscriptions[group.id] = sub;
      }
    }
  }
  // ------------------------

  void setActiveGroup(GroupModel group) {
    activeGroup.value = group;
  }

  void setLocalUser(UserModel user) {
    localUser.value = user;
  }

  void clearActiveGroup() {
    activeGroup.value = null;
    localUser.value = null;
    groups.clear();
    groupBalances.clear(); // Clear balances too
  }

  void createGroup() async {
    if (groupNameController.text.isEmpty) {
      Get.snackbar('Error', 'Group name cannot be empty.');
      return;
    }

    isLoading.value = true;
    try {
      // Determine the currency to save
      final currencyToSave = selectedGroupType.value == 'Trip'
          ? selectedCurrency.value
          : 'USD';

      // --- UPDATED CALL TO REPOSITORY ---
      await _groupRepository.createGroup(
        groupNameController.text.trim(),
        selectedGroupType.value,
        currency: currencyToSave,
      );
      // ----------------------------------

      Get.back();
      Get.snackbar('Success', "'${groupNameController.text}' group created!");
      groupNameController.clear();
      selectedGroupType.value = 'Flatmates'; // Reset defaults
      selectedCurrency.value = 'USD';

    } catch (e) {
      Get.snackbar('Error', 'Failed to create group: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    groupNameController.dispose();
    // Cancel all listeners to prevent memory leaks
    _groupsSubscription?.cancel();
    for (var sub in _groupExpenseSubscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }
}