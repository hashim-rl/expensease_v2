import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/member_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
// REMOVED: Unnecessary DashboardController import
// import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart';

class MembersController extends GetxController {
  final GroupRepository _groupRepository = Get.find<GroupRepository>();

  final Rx<GroupModel> group = (Get.arguments as GroupModel).obs;
  final members = <MemberModel>[].obs;
  final isLoading = true.obs;
  final isAddingMember = false.obs;
  final RxString currentUserRole = 'Viewer'.obs;

  late TextEditingController addMemberInputController;
  late TextEditingController groupNameController;
  StreamSubscription? _membersSubscription;

  @override
  void onInit() {
    super.onInit();
    addMemberInputController = TextEditingController();
    groupNameController = TextEditingController(text: group.value.name);

    // Listen to the live stream of members from the repository
    _membersSubscription =
        _groupRepository.getMembersStream(group.value.id).listen(
              (memberList) {
            members.value = memberList;
            _updateCurrentUserRole();
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar("Error", "Could not load members in real-time.");
          },
        );
  }

  /// Determines and updates the role of the currently logged-in user.
  void _updateCurrentUserRole() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final currentUserMember = members.firstWhere(
          (m) => m.id == currentUserId,
      orElse: () => MemberModel(
          id: '', name: '', role: 'Viewer', isPlaceholder: true),
    );
    currentUserRole.value = currentUserMember.role;
  }

  /// Updates the group's name in Firestore.
  Future<void> updateGroupName() async {
    final newName = groupNameController.text.trim();
    if (newName.isEmpty || newName == group.value.name) {
      return;
    }
    try {
      await _groupRepository.updateGroupName(
        groupId: group.value.id,
        newName: newName,
      );
      group.update((val) {
        val?.name = newName;
      });
      // REMOVED: Unnecessary call to fetchUserGroups
      // Get.find<DashboardController>().fetchUserGroups();
      Get.snackbar('Success', 'Group name updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update group name.');
    }
  }

  /// Adds a member to the group by email or as a placeholder.
  Future<void> addMember({required bool byEmail}) async {
    final String input = addMemberInputController.text.trim();
    if (input.isEmpty) {
      Get.snackbar('Input Required', 'Please enter a name or email.');
      return;
    }

    // If adding by email, validate the format first
    if (byEmail && !GetUtils.isEmail(input)) {
      Get.snackbar('Invalid Input', 'Please enter a valid email address.');
      return;
    }

    isAddingMember.value = true;
    try {
      String result;
      if (byEmail) {
        result = await _groupRepository.addMemberByEmail(
            groupId: group.value.id, email: input);
      } else {
        result = await _groupRepository.addPlaceholderMember(
            groupId: group.value.id, name: input);
      }
      Get.back(); // Close the add member dialog

      // REMOVED: Unnecessary call to fetchUserGroups
      // Get.find<DashboardController>().fetchUserGroups();

      Get.snackbar('Success', result,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error Adding Member', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isAddingMember.value = false;
      addMemberInputController.clear();
    }
  }

  /// Shows a confirmation dialog and then removes a member from the group.
  Future<void> removeMember(String memberId, String memberName) async {
    // Prevent the user from removing themselves
    if (memberId == FirebaseAuth.instance.currentUser?.uid) {
      Get.snackbar(
          'Action Not Allowed', 'You cannot remove yourself from the group.');
      return;
    }

    Get.defaultDialog(
      title: "Remove Member",
      middleText:
      "Are you sure you want to remove '$memberName' from this group? This action cannot be undone.",
      textConfirm: "Remove",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back(); // Close the confirmation dialog
        try {
          await _groupRepository.removeMemberFromGroup(
              groupId: group.value.id, memberId: memberId);

          // REMOVED: Unnecessary call to fetchUserGroups
          // Get.find<DashboardController>().fetchUserGroups();

          Get.snackbar('Success', "'$memberName' has been removed.",
              backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Error', 'Failed to remove member: ${e.toString()}',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  /// Updates a member's role in Firestore.
  Future<void> updateMemberRole(String memberId, String newRole) async {
    try {
      await _groupRepository.updateMemberRole(
        groupId: group.value.id,
        memberId: memberId,
        newRole: newRole,
      );
      Get.snackbar('Success', "Member's role updated to $newRole.");
    } catch (e) {
      Get.snackbar('Error', "Failed to update member's role.");
    }
  }

  @override
  void onClose() {
    addMemberInputController.dispose();
    groupNameController.dispose();
    _membersSubscription?.cancel();
    super.onClose();
  }
}