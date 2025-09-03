import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/modules/shared_buys/controllers/shared_buys_controller.dart';

class SharedBuysBinding extends Bindings {
  @override
  void dependencies() {
    // This finds the necessary repositories and passes them to our new controller
    Get.lazyPut<SharedBuysController>(() => SharedBuysController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}