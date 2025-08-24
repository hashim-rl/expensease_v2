import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart'; // Assuming a repo exists to save the data

class SpecializedModesController extends GetxController {
  final GroupRepository _groupRepository = GroupRepository();
  final GroupModel group = Get.arguments;

  final partnerAIncomeController = TextEditingController();
  final partnerBIncomeController = TextEditingController();

  final incomeRatio = '50% / 50%'.obs;

  /// Calculates the income ratio for Couples Mode
  void calculateIncomeRatio() {
    final incomeA = double.tryParse(partnerAIncomeController.text) ?? 0;
    final incomeB = double.tryParse(partnerBIncomeController.text) ?? 0;

    if (incomeA + incomeB == 0) {
      incomeRatio.value = '50% / 50%';
      return;
    }

    final totalIncome = incomeA + incomeB;
    final ratioA = (incomeA / totalIncome * 100).round();
    final ratioB = 100 - ratioA;

    incomeRatio.value = '$ratioA% / $ratioB%';
  }

  void saveCoupleModeSettings() async {
    // THIS IS THE FIX: We now get the partner UIDs from the group.memberIds list
    if (group.memberIds.length != 2) {
      Get.snackbar('Error', 'A couple group must have exactly two members.');
      return;
    }

    final String partnerA_uid = group.memberIds[0];
    final String partnerB_uid = group.memberIds[1];

    final incomeA = double.tryParse(partnerAIncomeController.text) ?? 0;
    final incomeB = double.tryParse(partnerBIncomeController.text) ?? 0;

    if (incomeA + incomeB == 0) {
      Get.snackbar('Error', 'Total income cannot be zero.');
      return;
    }

    final totalIncome = incomeA + incomeB;
    final ratioA = incomeA / totalIncome;
    final ratioB = incomeB / totalIncome;

    final Map<String, double> ratioMap = {
      partnerA_uid: ratioA,
      partnerB_uid: ratioB,
    };

    // TODO: Call a repository method to save `ratioMap` to the group document in Firestore
    // await _groupRepository.updateGroupRatio(group.id, ratioMap);

    Get.back();
    Get.snackbar('Success', 'Couples Mode setup complete! Ratio is ${incomeRatio.value}');
  }
}