import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/modules/settings/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // We now find the repositories and pass them to the controller's constructor.
    Get.lazyPut<ProfileController>(() => ProfileController(
      userRepository: Get.find<UserRepository>(),
      groupRepository: Get.find<GroupRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}