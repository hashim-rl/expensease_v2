import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_dashboard_controller.dart';

class GroupDashboardBinding extends Bindings {
  @override
  void dependencies() {
    // The ExpenseRepository must be made available before the controller that uses it.
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository());

    // The GroupDashboardController depends on the ExpenseRepository, which it can
    // now access using Get.find().
    Get.lazyPut<GroupDashboardController>(() => GroupDashboardController());
  }
}