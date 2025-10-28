import 'dart:async'; // ADDED
import 'package:get/get.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';

class MealController extends GetxController {
  // Repositories
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  // Constructor to receive/inject the repositories
  MealController({
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _groupRepository = groupRepository,
        _expenseRepository = expenseRepository;

  // --- OBSERVABLES FOR UI ---
  final isLoading = true.obs;
  final totalMeals = 0.obs;
  final totalMealCost = 0.0.obs;
  final averageMealCost = 0.0.obs;
  final recentMeals = <ExpenseModel>[].obs;

  // --- ADDED: Listeners to manage real-time data ---
  StreamSubscription? _groupsSubscription;
  final List<StreamSubscription> _expenseSubscriptions = [];
  final RxMap<String, List<ExpenseModel>> _mealsByGroup =
      <String, List<ExpenseModel>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // --- ADDED: When the map of meals changes, re-process the final list & stats ---
    ever(_mealsByGroup, (_) => _processAndSortMeals());
    // --- UPDATED: Call the new real-time listener ---
    _listenToGroupsAndExpenses();
  }

  // --- ADDED: New method to process the map into a sorted list and calculate stats ---
  void _processAndSortMeals() {
    // Flatten the map of lists into a single list of all meals
    final allMealExpenses = _mealsByGroup.values.expand((list) => list).toList();

    // Calculate summary data
    totalMeals.value = allMealExpenses.length;
    // --- UPDATED: Fixed item.amount to item.totalAmount ---
    totalMealCost.value =
        allMealExpenses.fold(0.0, (sum, item) => sum + item.totalAmount);
    if (totalMeals.value > 0) {
      averageMealCost.value = totalMealCost.value / totalMeals.value;
    } else {
      averageMealCost.value = 0.0;
    }

    // Sort meals by date, newest first
    allMealExpenses.sort((a, b) => b.date.compareTo(a.date));
    // Update the final reactive list for the UI
    recentMeals.value = allMealExpenses;
  }

  // --- UPDATED: Renamed from _loadMealData and converted to real-time ---
  void _listenToGroupsAndExpenses() {
    isLoading.value = true;
    _groupsSubscription?.cancel(); // Cancel any old group listener

    _groupsSubscription = _groupRepository.getGroupsStream().listen(
          (groupList) {
        // --- ADDED: Real-time expense listening logic ---
        _cancelExpenseSubscriptions(); // Cancel all old expense listeners
        _mealsByGroup.clear(); // Clear the map (this will trigger _processAndSortMeals)

        if (groupList.isEmpty) {
          isLoading.value = false;
          _processAndSortMeals(); // Ensure list/stats are cleared
          return; // No groups, nothing to listen to
        }

        // For each group, create a new expense listener
        for (var group in groupList) {
          // --- UPDATED: Fixed method name ---
          final sub = _expenseRepository
              .getExpensesStreamForGroup(group.id)
              .listen(
                (groupExpenses) {
              // Filter for meals
              final meals =
              groupExpenses.where((e) => e.category == 'Meal').toList();
              // When expenses for this group update, update our map.
              // This assignment automatically triggers the 'ever' listener.
              _mealsByGroup[group.id] = meals;
            },
            onError: (error) {
              Get.snackbar("Error", "Could not load meals for ${group.name}");
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