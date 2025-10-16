import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
// --- NEW IMPORT ---
import 'package:flutter/foundation.dart';
// ------------------

class SpecializedModesController extends GetxController {
  final GroupRepository _groupRepository = Get.find<GroupRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  late final GroupModel group;

  // State for partner details
  final partnerA = Rxn<UserModel>();
  final partnerB = Rxn<UserModel>();

  // State for income sliders and ratio calculation
  final partnerAIncome = 5000.0.obs;
  final partnerBIncome = 5000.0.obs;
  final partnerARatio = 0.5.obs;
  final partnerBRatio = 0.5.obs;

  // State for savings goal
  final monthlySavingsGoal = 1000.0.obs;
  final currentSavings = 300.0.obs; // Placeholder data

  final isLoading = true.obs;
  final isSaving = false.obs; // New state for saving button

  @override
  void onInit() {
    super.onInit();
    final groupArg = Get.arguments as GroupModel?;
    if (groupArg == null) {
      Get.snackbar('Error', 'No group provided for Couples Mode.');
      isLoading.value = false;
      return;
    }
    group = groupArg;
    _fetchPartnerDetails();
  }

  Future<void> _fetchPartnerDetails() async {
    isLoading.value = true;
    // Check if the group is already configured with ratios
    // TODO: Load existing ratios/goals from group.settings field if available

    if (group.memberIds.length != 2) {
      Get.snackbar('Configuration Error', 'Couples Mode requires exactly two members.');
      isLoading.value = false;
      return;
    }

    // Fetch user models for both members
    final members = await _groupRepository.getMembersDetails(group.memberIds);
    if (members.length == 2) {
      partnerA.value = members[0];
      partnerB.value = members[1];
    }
    isLoading.value = false;
  }

  void updatePartnerAIncome(double value) {
    partnerAIncome.value = value;
    _calculateIncomeRatio();
  }

  void updatePartnerBIncome(double value) {
    partnerBIncome.value = value;
    _calculateIncomeRatio();
  }

  void _calculateIncomeRatio() {
    final totalIncome = partnerAIncome.value + partnerBIncome.value;
    if (totalIncome == 0) {
      partnerARatio.value = 0.5;
      partnerBRatio.value = 0.5;
    } else {
      partnerARatio.value = partnerAIncome.value / totalIncome;
      partnerBRatio.value = partnerBIncome.value / totalIncome;
    }
    debugPrint('New Ratio: A: ${partnerARatio.value.toStringAsFixed(2)}, B: ${partnerBRatio.value.toStringAsFixed(2)}');
  }

  void updateMonthlySavingsGoal(double value) {
    monthlySavingsGoal.value = value;
  }

  Future<void> saveCoupleModeSettings() async {
    if (partnerA.value == null || partnerB.value == null) {
      Get.snackbar('Error', 'Partner details are missing. Cannot save.');
      return;
    }

    isSaving.value = true;
    try {
      // --- IMPLEMENTATION OF TODO ---
      final settings = <String, dynamic>{
        // Store the ratios under the group document
        'modeSettings.incomeRatio': {
          partnerA.value!.uid: partnerARatio.value,
          partnerB.value!.uid: partnerBRatio.value,
        },
        // Store the savings goal
        'modeSettings.monthlySavingsGoal': monthlySavingsGoal.value,
        // Mark the group as using the proportional split mode
        'modeSettings.splitType': 'proportional',
      };

      await _groupRepository.updateGroupSettings(group.id, settings);

      Get.back(); // Navigate back to the Group Settings screen
      Get.snackbar('Settings Saved', 'Couples Mode proportional split configured!');
      // -----------------------------

    } catch (e) {
      Get.snackbar('Save Failed', 'Could not save settings: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }
}