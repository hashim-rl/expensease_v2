import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
// --- NEW IMPORT ---
import 'package:expensease/app/data/models/user_model.dart';
// ------------------

class GroupController extends GetxController {
  final GroupRepository _groupRepository = GroupRepository();

  final groupNameController = TextEditingController();
  final isLoading = true.obs; // Start in loading state

  // Observables for live data
  final groups = <GroupModel>[].obs;
  final groupBalances = <String, double>{}.obs;

  // Holds the currently selected group type when creating a new group
  final selectedGroupType = 'Flatmates'.obs;

  // --- NEW FIELDS FOR GUEST/ACTIVE GROUP MANAGEMENT ---
  final activeGroup = Rx<GroupModel?>(null);
  final localUser = Rx<UserModel?>(null);
  // ---------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    // Bind the groups list to the real-time stream from Firestore
    groups.bindStream(_groupRepository.getGroupsStream());

    // When the stream gives us the first set of data, stop loading and calculate balances
    // NOTE: This will only run for authenticated users. Guest users will rely on setActiveGroup.
    debounce(groups, (_) {
      _calculateAllBalances();
      isLoading.value = false;
    }, time: const Duration(seconds: 1));
  }

  // --- NEW METHODS ---
  // Sets the currently active group, used for navigation/context
  void setActiveGroup(GroupModel group) {
    activeGroup.value = group;
  }

  // Sets the local user model for guest mode operations
  void setLocalUser(UserModel user) {
    localUser.value = user;
  }

  // Clears the active group and user when signing out/exiting guest mode
  void clearActiveGroup() {
    activeGroup.value = null;
    localUser.value = null;
    groups.clear(); // Clear local list when logging out
  }
  // -------------------

  // This function would calculate the user's balance for each group
  // In GroupController, replace the existing _calculateAllBalances method with this one

  void _calculateAllBalances() {
    final balances = <String, double>{};
    for (var group in groups) {
      // For now, we will set the balance to 0.0 until we implement
      // the full cross-group balance calculation in a later step.
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
      // Call the repository to create the group in Firebase
      await _groupRepository.createGroup(
        groupNameController.text.trim(),
        selectedGroupType.value,
      );
      Get.back(); // Close the creation dialog
      Get.snackbar('Success', "'${groupNameController.text}' group created!");
      groupNameController.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to create group: ${e.toString()}');
    } finally {
      // A small delay to allow the UI to update before hiding any loaders
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