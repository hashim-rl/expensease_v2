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

  // --- NEW OBSERVABLES FOR UI ---
  final isLoading = true.obs;
  final totalMeals = 0.obs;
  final totalMealCost = 0.0.obs;
  final averageMealCost = 0.0.obs;
  final recentMeals = <ExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load data when the controller is initialized
    _loadMealData();
  }

  // --- NEW DATA LOADING FUNCTION ---
  Future<void> _loadMealData() async {
    try {
      isLoading.value = true;
      // Get all groups the user is a part of
      final groups = await _groupRepository.getGroupsStream().first;
      final allMealExpenses = <ExpenseModel>[];

      // Loop through each group to get its expenses
      for (var group in groups) {
        final groupExpenses =
        await _expenseRepository.getExpensesStreamForGroup(group.id).first;
        // Filter for expenses in the "Meal" category
        allMealExpenses
            .addAll(groupExpenses.where((e) => e.category == 'Meal'));
      }

      // Calculate summary data
      totalMeals.value = allMealExpenses.length;
      totalMealCost.value =
          allMealExpenses.fold(0.0, (sum, item) => sum + item.totalAmount);
      if (totalMeals.value > 0) {
        averageMealCost.value = totalMealCost.value / totalMeals.value;
      } else {
        averageMealCost.value = 0.0;
      }

      // Sort meals by date and get the most recent ones
      allMealExpenses.sort((a, b) => b.date.compareTo(a.date));
      recentMeals.value = allMealExpenses;

    } catch (e) {
      Get.snackbar('Error', 'Failed to load meal data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}