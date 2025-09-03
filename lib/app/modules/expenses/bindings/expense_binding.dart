import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import '../controllers/expense_controller.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    // We now find the required repositories and pass them to the controller
    Get.lazyPut<ExpenseController>(() => ExpenseController(
      expenseRepository: Get.find<ExpenseRepository>(),
      groupRepository: Get.find<GroupRepository>(),
    ));
  }
}