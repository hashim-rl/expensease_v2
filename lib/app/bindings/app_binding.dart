import 'package:get/get.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
// --- NEW IMPORTS FOR DASHBOARD DEPENDENCIES ---
import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:expensease/app/modules/meal/controllers/meal_controller.dart';
import 'package:expensease/app/modules/shared_buys/controllers/shared_buys_controller.dart';
import 'package:expensease/app/modules/bills/controllers/bills_controller.dart';
// ----------------------------------------------

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // --- CORE DEPENDENCIES ---
    // These are the heart of the app, loaded immediately.
    Get.lazyPut(() => FirebaseProvider());

    Get.lazyPut(() => AuthRepository(Get.find()));
    Get.lazyPut(() => UserRepository());
    Get.lazyPut(() => GroupRepository());
    Get.lazyPut(() => ExpenseRepository());

    // Global Controllers
    Get.lazyPut(() => GroupController());
    Get.lazyPut(() => AuthController());

    // --- DASHBOARD DEPENDENCIES (Moved here to fix Home Wrapper crash) ---
    // Since main.dart might load DashboardView() directly in the 'home' widget,
    // we must ensure its controller is available right away.

    Get.lazyPut(() => DashboardController());

    // Sub-feature controllers for the Dashboard tabs
    Get.lazyPut(() => MealController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));

    Get.lazyPut(() => SharedBuysController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));

    Get.lazyPut(() => BillsController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}