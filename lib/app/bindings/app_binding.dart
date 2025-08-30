import 'package:get/get.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/data/repositories/family_repository.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Core Providers & Services
    Get.put(FirebaseProvider(), permanent: true);

    // Core Repositories (make them permanent so they are always available)
    Get.put(AuthRepository(Get.find()), permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(GroupRepository(), permanent: true);
    Get.put(ExpenseRepository(), permanent: true);
    Get.put(FamilyRepository(), permanent: true);

    // Core Controllers (also permanent and always available)
    Get.put(AuthController(), permanent: true);
  }
}