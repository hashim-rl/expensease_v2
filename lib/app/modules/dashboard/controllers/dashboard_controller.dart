import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'dart:async';

class DashboardController extends GetxController {
  final GroupRepository _groupRepository = Get.find<GroupRepository>();

  // A key to control the Scaffold's state, including the drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final groups = <GroupModel>[].obs;
  final isLoading = true.obs;
  final overallBalance = 0.0.obs;

  final summaryData = <String, double>{
    'Paid': 120.0,
    'Owed': 75.0,
    'Due': 50.0,
  }.obs;

  StreamSubscription? _groupsSubscription;

  RxList<PieChartSectionData> get pieChartSections {
    final List<PieChartSectionData> sections = [];
    final total = summaryData.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return <PieChartSectionData>[].obs;

    sections.add(PieChartSectionData(
      color: Colors.lightBlue,
      value: summaryData['Paid'],
      title: '${((summaryData['Paid']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    sections.add(PieChartSectionData(
      color: Colors.orangeAccent,
      value: summaryData['Owed'],
      title: '${((summaryData['Owed']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
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

  void fetchUserGroups() {
    isLoading.value = true;
    _groupsSubscription?.cancel();

    _groupsSubscription = _groupRepository.getGroupsStream().listen(
          (groupList) {
        groups.value = groupList;
        overallBalance.value = 78.50;
        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar("Error", "Could not fetch your groups. Please try again.");
      },
    );
  }

  // Method to open the drawer
  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  void onClose() {
    _groupsSubscription?.cancel();
    super.onClose();
  }
}