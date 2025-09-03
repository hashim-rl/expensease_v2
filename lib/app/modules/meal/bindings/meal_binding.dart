import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/modules/meal/controllers/meal_controller.dart';

class MealBinding extends Bindings {
  @override
  void dependencies() {
    // This finds the necessary repositories and passes them to our new controller
    Get.lazyPut<MealController>(() => MealController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}