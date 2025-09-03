import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/modules/bills/controllers/bills_controller.dart';

class BillsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillsController>(() => BillsController(
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}