import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'dart:async';

import '../../../routes/app_routes.dart'; // Import app_routes

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
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    sections.add(PieChartSectionData(
      color: Colors.orangeAccent,
      value: summaryData['Owed'],
      title: '${((summaryData['Owed']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    sections.add(PieChartSectionData(
      color: Colors.pinkAccent,
      value: summaryData['Due'],
      title: '${((summaryData['Due']! / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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

  // --- REUSABLE FUNCTION WITH FIX ---
  // This function shows the group selection dialog.
  void showGroupSelectionDialog({String? category}) {
    if (groups.isEmpty) {
      Get.snackbar(
          "No Groups Available", "Create a group before adding an expense.");
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Select a Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() => ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.name),
                onTap: () async {
                  Get.back(); // Close the dialog first
                  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false); // Show loading indicator

                  try {
                    // Fetch the COMPLETE group object from the repository
                    final fullGroup =
                    await _groupRepository.getGroupById(group.id);
                    Get.back(); // Close the loading indicator

                    if (fullGroup != null) {
                      // Navigate to Add Expense screen with the COMPLETE group object
                      Get.toNamed(
                        Routes.ADD_EXPENSE,
                        arguments: {
                          // --- THIS IS THE FIX ---
                          // Changed 'full-group' to 'fullGroup'
                          'group': fullGroup,
                          'category': category,
                        },
                      );
                    } else {
                      Get.snackbar("Error", "Could not load group details.");
                    }
                  } catch (e) {
                    Get.back(); // Close loading indicator on error
                    Get.snackbar("Error", "An error occurred: $e");
                  }
                },
              );
            },
          )),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _groupsSubscription?.cancel();
    super.onClose();
  }
}