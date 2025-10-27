import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
// REMOVED unused user_repository.dart import

class SplitSetupController extends GetxController {
  final GroupRepository _groupRepository = Get.find<GroupRepository>();
  // REMOVED unused _userRepository

  late GroupModel group;
  final members = <UserModel>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;

  // Map to hold the text controllers for each member's percentage
  final memberControllers = <String, TextEditingController>{}.obs;
  // Observable for the current total percentage
  final totalPercentage = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final groupArg = Get.arguments as GroupModel?;
    if (groupArg == null) {
      Get.snackbar('Error', 'No group data provided.');
      isLoading.value = false;
      return;
    }
    group = groupArg;
    _fetchMembersAndInitControllers();
  }

  Future<void> _fetchMembersAndInitControllers() async {
    isLoading.value = true;
    // --- FIX 1: Use getMembersDetails from GroupRepository ---
    final memberDetails =
    await _groupRepository.getMembersDetails(group.memberIds);
    members.value = memberDetails;
    _initializeControllers();
    isLoading.value = false;
  }

  void _initializeControllers() {
    final existingRatios = group.incomeSplitRatio;
    final tempControllers = <String, TextEditingController>{};

    for (var member in members) {
      String initialValue;
      if (existingRatios != null && existingRatios.containsKey(member.uid)) {
        // If a ratio exists, convert it to a percentage string (e.g., 0.4 -> "40.0")
        initialValue = (existingRatios[member.uid]! * 100).toStringAsFixed(1);
      } else {
        // Default to "0" if no ratio is set
        initialValue = "0";
      }

      final controller = TextEditingController(text: initialValue);
      // Add a listener to each controller to update the total percentage
      controller.addListener(_updateTotalPercentage);
      tempControllers[member.uid] = controller;
    }

    memberControllers.value = tempControllers;
    _updateTotalPercentage(); // Calculate initial total
  }

  // Called by listeners to update the total percentage reactively
  void _updateTotalPercentage() {
    double total = 0.0;
    memberControllers.forEach((_, controller) {
      total += double.tryParse(controller.text) ?? 0.0;
    });
    totalPercentage.value = total;
  }

  // Sets all percentages to be equal
  void setEqualSplit() {
    if (members.isEmpty) return;
    final equalPercentage = 100.0 / members.length;
    final equalPercentageString = equalPercentage.toStringAsFixed(2);

    // To handle rounding errors for 3, 6, etc. members
    double runningTotal = 0.0;

    for (int i = 0; i < members.length; i++) {
      final member = members[i];
      if (i == members.length - 1) {
        // Last member gets the remainder to ensure it's exactly 100
        final remainder = 100.0 - runningTotal;
        memberControllers[member.uid]?.text = remainder.toStringAsFixed(2);
      } else {
        final percentage = double.parse(equalPercentageString);
        memberControllers[member.uid]?.text = equalPercentageString;
        runningTotal += percentage;
      }
    }
  }

  Future<void> saveSplitRatios() async {
    // 1. Validate the total
    if (totalPercentage.value != 100.0) {
      Get.snackbar(
        'Validation Error',
        'Total percentage must be exactly 100%. Current total is ${totalPercentage.value}%.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isSaving.value = true;

    try {
      // 2. Create the ratio map for Firestore (e.g., "40.0" -> 0.40)
      final newRatioMap = <String, double>{};
      memberControllers.forEach((uid, controller) {
        newRatioMap[uid] = (double.tryParse(controller.text) ?? 0.0) / 100.0;
      });

      // 3. Save to Firestore
      // --- FIX 2: Use updateGroupSettings instead of updateGroupData ---
      await _groupRepository.updateGroupSettings(group.id, {
        'incomeSplitRatio': newRatioMap,
      });

      // 4. Update the local group object to reflect the change
      group.incomeSplitRatio?.clear();
      // Ensure the map is not null before adding to it
      if (group.incomeSplitRatio == null) {
        group.incomeSplitRatio = {};
      }
      group.incomeSplitRatio!.addAll(newRatioMap);

      isSaving.value = false;
      Get.back(); // Go back to the settings screen
      Get.snackbar(
        'Success',
        'Proportional split ratios have been saved!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isSaving.value = false;
      Get.snackbar('Error', 'Could not save ratios: ${e.toString()}');
    }
  }

  @override
  void onClose() {
    // Dispose all text controllers to prevent memory leaks
    memberControllers.forEach((_, controller) {
      controller.removeListener(_updateTotalPercentage);
      controller.dispose();
    });
    super.onClose();
  }
}