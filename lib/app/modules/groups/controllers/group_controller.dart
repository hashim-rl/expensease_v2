import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/models/user_model.dart';

class GroupController extends GetxController {
  final GroupRepository _groupRepository = GroupRepository();

  final groupNameController = TextEditingController();
  final isLoading = true.obs;

  // Observables for live data
  final groups = <GroupModel>[].obs;
  final groupBalances = <String, double>{}.obs;

  // Holds the currently selected group type
  final selectedGroupType = 'Flatmates'.obs;

  // --- NEW: Holds the selected currency for Trip groups ---
  final selectedCurrency = 'USD'.obs;
  // -------------------------------------------------------

  // Guest/Active Group Management
  final activeGroup = Rx<GroupModel?>(null);
  final localUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    groups.bindStream(_groupRepository.getGroupsStream());

    debounce(groups, (_) {
      _calculateAllBalances();
      isLoading.value = false;
    }, time: const Duration(seconds: 1));
  }

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
  }

  void _calculateAllBalances() {
    final balances = <String, double>{};
    for (var group in groups) {
      // Placeholder for future cross-group balance logic
      balances[group.id] = 0.0;
    }
    groupBalances.value = balances;
  }

  void createGroup() async {
    if (groupNameController.text.isEmpty) {
      Get.snackbar('Error', 'Group name cannot be empty.');
      return;
    }

    isLoading.value = true;
    try {
      // Determine the currency to save
      // If it's not a trip, default to USD (or your app's base currency)
      final currencyToSave = selectedGroupType.value == 'Trip'
          ? selectedCurrency.value
          : 'USD';

      // --- UPDATED CALL TO REPOSITORY ---
      await _groupRepository.createGroup(
        groupNameController.text.trim(),
        selectedGroupType.value,
        currency: currencyToSave, // Pass the currency
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
    super.onClose();
  }
}