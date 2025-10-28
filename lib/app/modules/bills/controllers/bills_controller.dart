import 'dart:async'; // ADDED
import 'package:get/get.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';

class BillsController extends GetxController {
  // Repositories
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  // Constructor
  BillsController({
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _groupRepository = groupRepository,
        _expenseRepository = expenseRepository;

  // Observables for UI state
  final isLoading = true.obs;
  final billExpenses = <ExpenseModel>[].obs;

  // --- ADDED: Listeners to manage real-time data ---
  StreamSubscription? _groupsSubscription;
  final List<StreamSubscription> _expenseSubscriptions = [];
  final RxMap<String, List<ExpenseModel>> _billsByGroup =
      <String, List<ExpenseModel>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // --- ADDED: When the map of bills changes, re-process the final list ---
    ever(_billsByGroup, (_) => _processAndSortBills());
    // --- UPDATED: Call the new real-time listener ---
    _listenToGroupsAndExpenses();
  }

  // --- ADDED: New method to process the map into a sorted list ---
  void _processAndSortBills() {
    // Flatten the map of lists into a single list of all bills
    final allBills = _billsByGroup.values.expand((list) => list).toList();
    // Sort by date, newest first
    allBills.sort((a, b) => b.date.compareTo(a.date));
    // Update the final reactive list for the UI
    billExpenses.value = allBills;
  }

  // --- UPDATED: Renamed from _loadBillsData and converted to real-time ---
  void _listenToGroupsAndExpenses() {
    isLoading.value = true;
    _groupsSubscription?.cancel(); // Cancel any old group listener

    _groupsSubscription = _groupRepository.getGroupsStream().listen(
          (groupList) {
        // --- ADDED: Real-time expense listening logic ---
        _cancelExpenseSubscriptions(); // Cancel all old expense listeners
        _billsByGroup.clear(); // Clear the map (this will trigger _processAndSortBills)

        if (groupList.isEmpty) {
          isLoading.value = false;
          _processAndSortBills(); // Ensure list is cleared if no groups
          return; // No groups, nothing to listen to
        }

        // For each group, create a new expense listener
        for (var group in groupList) {
          // --- UPDATED: Fixed method name ---
          final sub = _expenseRepository
              .getExpensesStreamForGroup(group.id)
              .listen(
                (groupExpenses) {
              // Filter for bills
              final bills =
              groupExpenses.where((e) => e.category == 'Bill').toList();
              // When expenses for this group update, update our map.
              // This assignment automatically triggers the 'ever' listener.
              _billsByGroup[group.id] = bills;
            },
            onError: (error) {
              Get.snackbar("Error", "Could not load bills for ${group.name}");
            },
          );

          _expenseSubscriptions.add(sub); // Add new listener to our list
        }
        // --- End of added logic ---

        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar("Error", "Could not fetch your groups. Please try again.");
      },
    );
  }

  // --- ADDED: Helper to cancel all expense listeners ---
  void _cancelExpenseSubscriptions() {
    for (final sub in _expenseSubscriptions) {
      sub.cancel();
    }
    _expenseSubscriptions.clear();
  }

  // --- ADDED: Cancel all listeners on close ---
  @override
  void onClose() {
    _groupsSubscription?.cancel();
    _cancelExpenseSubscriptions();
    super.onClose();
  }
}