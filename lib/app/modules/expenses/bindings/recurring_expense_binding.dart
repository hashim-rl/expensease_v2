import 'package:get/get.dart';
import 'package:expensease/app/modules/expenses/controllers/recurring_expense_controller.dart';

class RecurringExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecurringExpenseController>(() => RecurringExpenseController());
  }
}