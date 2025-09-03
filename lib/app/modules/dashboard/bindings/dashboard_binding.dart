import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/modules/bills/controllers/bills_controller.dart';
import 'package:expensease/app/modules/meal/controllers/meal_controller.dart';
// Import the new SharedBuysController
import 'package:expensease/app/modules/shared_buys/controllers/shared_buys_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register the DashboardController
    Get.lazyPut<DashboardController>(() => DashboardController());

    // Register the MealController
    Get.lazyPut<MealController>(() => MealController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));

    // Register the SharedBuysController
    Get.lazyPut<SharedBuysController>(() => SharedBuysController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));

    // --- THIS IS THE NEW CODE ---
    // Register the BillsController here as well.
    Get.lazyPut<BillsController>(() => BillsController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}