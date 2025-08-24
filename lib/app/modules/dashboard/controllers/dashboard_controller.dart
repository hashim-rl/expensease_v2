import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'dart:async';

class DashboardController extends GetxController {
  final GroupRepository _groupRepository = Get.find<GroupRepository>();

  // --- STATE MANAGEMENT ---
  final groups = <GroupModel>[].obs;
  final isLoading = true.obs;
  final overallBalance = 0.0.obs;
  final isDialOpen = ValueNotifier<bool>(false);

  // New state for the pie chart data
  final summaryData = <String, double>{
    'Paid': 120.0,
    'Owed': 75.0,
    'Due': 50.0,
  }.obs;

  StreamSubscription? _groupsSubscription;

  /// ✅ NEW GETTER: This is what the view needs.
  /// It dynamically creates the pie chart sections based on the summaryData.
  RxList<PieChartSectionData> get pieChartSections {
    final List<PieChartSectionData> sections = [];
    final total = summaryData.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return <PieChartSectionData>[].obs;

    // Create a section for "Paid"
    sections.add(PieChartSectionData(
      color: Colors.lightBlue,
      value: summaryData['Paid'],
      title: '${((summaryData['Paid']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    // Create a section for "Owed"
    sections.add(PieChartSectionData(
      color: Colors.orangeAccent,
      value: summaryData['Owed'],
      title: '${((summaryData['Owed']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    // Create a section for "Due"
    sections.add(PieChartSectionData(
      color: Colors.pinkAccent,
      value: summaryData['Due'],
      title: '${((summaryData['Due']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));

    return sections.obs;
  }


  @override
  void onInit() {
    super.onInit();
    fetchUserGroups();
  }

  /// Fetches all groups the current user is a member of from Firestore.
  void fetchUserGroups() {
    isLoading.value = true;
    _groupsSubscription?.cancel();

    _groupsSubscription = _groupRepository.getGroupsStream().listen(
          (groupList) {
        groups.value = groupList;
        // TODO: Implement logic to calculate the overall balance from all groups
        overallBalance.value = 78.50; // Using placeholder from design
        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar("Error", "Could not fetch your groups. Please try again.");
      },
    );
  }

  @override
  void onClose() {
    isDialOpen.dispose();
    _groupsSubscription?.cancel();
    super.onClose();
  }
}