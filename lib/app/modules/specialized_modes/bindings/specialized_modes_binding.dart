import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/family_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import '../controllers/family_mode_controller.dart';
import '../controllers/specialized_modes_controller.dart';

class SpecializedModesBinding extends Bindings {
  @override
  void dependencies() {
    // For Couples Mode
    Get.lazyPut<UserRepository>(() => UserRepository());
    Get.lazyPut<GroupRepository>(() => GroupRepository());
    Get.lazyPut<SpecializedModesController>(() => SpecializedModesController());

    // --- NEW DEPENDENCIES FOR FAMILY MODE ---
    Get.lazyPut<FamilyRepository>(() => FamilyRepository());
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository());
    Get.lazyPut<FamilyModeController>(() => FamilyModeController());
  }
}