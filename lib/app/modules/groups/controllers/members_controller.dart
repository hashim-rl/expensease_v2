import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/member_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
// --- FIX: IMPORT THE DASHBOARD CONTROLLER ---
import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart';


class MembersController extends GetxController {
  // Get the repository instance from the bindings
  final GroupRepository _groupRepository = Get.find<GroupRepository>();

  // --- STATE MANAGEMENT ---
  final Rx<GroupModel> group = (Get.arguments as GroupModel).obs;
  final members = <MemberModel>[].obs;
  final isLoading = true.obs;
  final isAddingMember = false.obs;
  final RxString currentUserRole = 'Viewer'.obs;

  // --- FORM CONTROLLERS ---
  late TextEditingController addMemberInputController;
  late TextEditingController groupNameController;
  StreamSubscription? _membersSubscription;

  @override
  void onInit() {
    super.onInit();
    addMemberInputController = TextEditingController();
    groupNameController = TextEditingController(text: group.value.name);

    // Listen to the stream of members from the repository
    _membersSubscription = _groupRepository
        .getMembersStream(group.value.id)
        .listen((memberList) {
      members.value = memberList;
      _updateCurrentUserRole();
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar("Error", "Could not load members.");
    });
  }

  /// Determines and updates the role of the currently logged-in user.
  void _updateCurrentUserRole() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final currentUserMember = members.firstWhere(
          (m) => m.id == currentUserId,
      orElse: () =>
          MemberModel(id: '', name: '', role: 'Viewer', isPlaceholder: true),
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
      Get.snackbar('Success', 'Group name updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update group name.');
    }
  }

  /// Adds a member to the group by email or as a placeholder.
  Future<void> addMember() async {
    final String input = addMemberInputController.text.trim();
    if (input.isEmpty) {
      Get.snackbar('Error', 'Name or email cannot be empty.');
      return;
    }
    isAddingMember.value = true;
    try {
      String result;
      if (GetUtils.isEmail(input)) {
        result = await _groupRepository.addMemberByEmail(
            groupId: group.value.id, email: input);
      } else {
        result = await _groupRepository.addPlaceholderMember(
            groupId: group.value.id, name: input);
      }
      Get.back(); // Close the add member dialog

      // --- THIS IS THE FIX ---
      // After successfully adding a member to the database, we find the
      // DashboardController that is running in the background and tell it
      // to re-fetch its list of groups. This ensures the UI always has
      // the most up-to-date data.
      Get.find<DashboardController>().fetchUserGroups();

      Get.snackbar('Success', result,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error Adding Member', e.toString());
    } finally {
      isAddingMember.value = false;
      addMemberInputController.clear();
    }
  }

  /// Removes a member from the current group.
  Future<void> removeMember(String memberId) async {
    Get.defaultDialog(
      title: "Remove Member",
      middleText: "Are you sure you want to remove this member?",
      textConfirm: "Remove",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        try {
          await _groupRepository.removeMemberFromGroup(
              groupId: group.value.id, memberId: memberId);
          // --- GOOD PRACTICE: REFRESH ON REMOVE TOO ---
          Get.find<DashboardController>().fetchUserGroups();
          Get.snackbar('Success', 'Member has been removed.',
              backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Error', 'Failed to remove member: ${e.toString()}');
        }
      },
    );
  }

  /// ✅ NEW FUNCTION: Updates a member's role in Firestore.
  Future<void> updateMemberRole(String memberId, String newRole) async {
    try {
      // This method needs to be added to the repository
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