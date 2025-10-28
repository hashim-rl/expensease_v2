import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'dart:async';

// --- ADDED Imports ---ss
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/services/auth_service.dart';
// --- REMOVED: collection package no longer needed ---
// import 'package:collection/collection.dart';

import '../../../routes/app_routes.dart'; // Import app_routes

class DashboardController extends GetxController {
  // --- ADDED Dependencies ---
  final GroupRepository _groupRepository = Get.find<GroupRepository>();
  late final ExpenseRepository _expenseRepository;
  late final AuthService _authService;
  late final String _currentUserId;

  // A key to control the Scaffold's state, including the drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final groups = <GroupModel>[].obs;
  final isLoading = true.obs;
  final overallBalance = 0.0.obs;

  // --- UPDATED: This is now calculated, not hardcoded ---
  final summaryData = <String, double>{
    'Paid': 0.0,
    'Owed': 0.0,
    'Due': 0.0,
  }.obs;

  // --- ADDED: Listeners to manage real-time data ---
  StreamSubscription? _groupsSubscription;
  final List<StreamSubscription> _expenseSubscriptions = [];
  final RxMap<String, List<ExpenseModel>> _expensesByGroup =
      <String, List<ExpenseModel>>{}.obs;

  RxList<PieChartSectionData> get pieChartSections {
    final List<PieChartSectionData> sections = [];
    // --- UPDATED: Use null-aware operator for safety ---
    final total = (summaryData['Paid'] ?? 0) +
        (summaryData['Owed'] ?? 0) +
        (summaryData['Due'] ?? 0);
    if (total == 0) {
      // Return a default "empty" state for the pie chart
      return [
        PieChartSectionData(
          color: Colors.blueGrey[100],
          value: 1,
          title: '0%',
          radius: 50,
          titleStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        )
      ].obs;
    }

    // --- UPDATED: Handle potential nulls and division by zero ---
    final paidValue = summaryData['Paid'] ?? 0;
    final owedValue = summaryData['Owed'] ?? 0;
    final dueValue = summaryData['Due'] ?? 0;

    sections.add(PieChartSectionData(
      color: Colors.lightBlue,
      value: paidValue,
      title: '${((paidValue / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    sections.add(PieChartSectionData(
      color: Colors.orangeAccent,
      value: owedValue,
      title: '${((owedValue / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));
    sections.add(PieChartSectionData(
      color: Colors.pinkAccent,
      value: dueValue,
      title: '${((dueValue / total) * 100).toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ));

    return sections.obs;
  }

  @override
  void onInit() {
    // --- ADDED: Initialize dependencies and get current user ID ---
    _authService = Get.find<AuthService>();
    _expenseRepository = Get.find<ExpenseRepository>();
    // Ensure user is not null. In a real app, this controller should
    // only be initialized *after* user is authenticated.
    // --- UPDATED: Fixed _authService.currentUser to _authService.user ---
    _currentUserId = _authService.user.value!.uid;

    super.onInit();

    // --- ADDED: Set up reactive listeners ---
    // 1. When expenses map changes, recalculate the summary
    ever(_expensesByGroup, (_) => _calculateSummary());
    // 2. When summary data changes, recalculate the overall balance
    ever(summaryData, (_) => _calculateOverallBalance());

    // --- UPDATED: This function now does much more ---
    _listenToGroupsAndExpenses();
  }

  // --- ADDED: New method to dynamically calculate the overall balance ---
  void _calculateOverallBalance() {
    final owed = summaryData['Owed'] ?? 0.0;
    final due = summaryData['Due'] ?? 0.0;
    overallBalance.value = owed - due;
  }

  // --- ADDED: New method to calculate summary from all expenses ---
  void _calculateSummary() {
    double totalPaid = 0;
    double totalOwed = 0;
    double totalDue = 0;

    // Flatten the map of lists into a single list of all expenses
    final allExpenses = _expensesByGroup.values.expand((list) => list).toList();

    for (var expense in allExpenses) {
      // 1. Calculate 'Paid': Total amount I physically paid
      if (expense.paidById == _currentUserId) {
        totalPaid += expense.totalAmount;
      }

      // 2. Calculate 'Owed' (what others owe me) and 'Due' (what I owe others)
      // --- UPDATED: Access the Map directly by key ---
      final double? userShare = expense.splitBetween[_currentUserId];

      // If I'm not part of this expense split, skip it
      if (userShare == null) continue;

      // --- UPDATED: userShare is already the double value ---
      // (No need for userSplit.share)

      if (expense.paidById == _currentUserId) {
        // I paid. I am owed what others were supposed to pay.
        // (Total Amount - My Share) is what others owe me for this bill.
        totalOwed += (expense.totalAmount - userShare);
      } else {
        // Someone else paid. I owe my share.
        totalDue += userShare;
      }
    }

    // Update the reactive summaryData, which will trigger pie chart
    // and overallBalance to update automatically.
    summaryData.value = {
      'Paid': totalPaid,
      'Owed': totalOwed,
      'Due': totalDue,
    };
  }

  // --- RENAMED & UPDATED: from fetchUserGroups to _listenToGroupsAndExpenses ---
  void _listenToGroupsAndExpenses() {
    isLoading.value = true;
    _groupsSubscription?.cancel(); // Cancel any old group listener

    _groupsSubscription = _groupRepository.getGroupsStream().listen(
          (groupList) {
        groups.value = groupList;

        // --- ADDED: Real-time expense listening logic ---
        _cancelExpenseSubscriptions(); // Cancel all old expense listeners
        _expensesByGroup
            .clear(); // Clear the map (this will trigger _calculateSummary)

        if (groupList.isEmpty) {
          isLoading.value = false;
          // --- ADDED: clear summary if no groups ---
          _calculateSummary();
          return; // No groups, nothing to listen to
        }

        // For each group, create a new expense listener
        for (var group in groupList) {
          final sub = _expenseRepository
              .getExpensesStreamForGroup(group.id)
              .listen((groupExpenses) {
            // When expenses for this group update, update our map.
            // This assignment automatically triggers the 'ever' listener.
            _expensesByGroup[group.id] = groupExpenses;
          }, onError: (error) {
            // --- UPDATED: Added debugPrint to see the REAL error ---
            debugPrint("!!!! ERROR loading expenses for ${group.name} (ID: ${group.id}): $error");
            Get.snackbar("Error", "Could not load expenses for ${group.name}");
          });

          _expenseSubscriptions.add(sub); // Add new listener to our list
        }
        // --- End of added logic ---

        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        debugPrint("!!!! ERROR loading groups: $error"); // --- ADDED debugPrint ---
        Get.snackbar("Error", "Could not fetch your groups. Please try again.");
      },
    );
  }

  // Method to open the drawer
  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  // --- THIS IS THE UPDATED FUNCTION WITH LOGGING ---
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
                  Get.dialog(const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false); // Show loading indicator

                  try {
                    // 1. Fetch the complete group details to get the full memberIds list.
                    final fullGroup =
                    await _groupRepository.getGroupById(group.id);
                    if (fullGroup == null) {
                      throw Exception("Could not load group details.");
                    }

                    // 2. Fetch all member details using their IDs.
                    final members = await _groupRepository
                        .getMembersDetails(fullGroup.memberIds);
                    Get.back(); // Close the loading indicator

                    // --- TRACER BULLETS START ---
                    debugPrint(
                        "--- TRACER: Navigating to Add Expense Screen ---");
                    debugPrint(
                        "--- TRACER: Group Name: ${fullGroup.name}");
                    debugPrint(
                        "--- TRACER: Group Member IDs: ${fullGroup.memberIds}");
                    debugPrint(
                        "--- TRACER: Members being passed (${members.length}): ${members.map((m) => m.nickname).toList()}");
                    // --- TRACER BULLETS END ---

                    // 3. Navigate with ALL the necessary data.
                    Get.toNamed(
                      Routes.ADD_EXPENSE,
                      arguments: {
                        'group': fullGroup,
                        'members': members, // Pass the full member list here
                        'category': category,
                      },
                    );
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

  // --- ADDED: Helper to cancel all expense listeners ---
  void _cancelExpenseSubscriptions() {
    for (final sub in _expenseSubscriptions) {
      sub.cancel();
    }
    _expenseSubscriptions.clear();
  }

  @override
  void onClose() {
    _groupsSubscription?.cancel();
    _cancelExpenseSubscriptions(); // --- ADDED ---
    super.onClose();
  }
}