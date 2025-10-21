import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_details_controller.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/services/auth_service.dart';

class ExpenseDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseDetailsController>(() => ExpenseDetailsController(
          expenseRepository: Get.find<ExpenseRepository>(),
          authService: Get.find<AuthService>(),
          groupController: Get.find<GroupController>(),
        ));
  }
}