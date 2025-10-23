import 'package:get/get.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/data/repositories/family_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart'; // Import GroupController

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // --- THIS IS THE DEFINITIVE FIX FOR DEPENDENCY INJECTION ---
    // This binding now uses `Get.lazyPut` without `fenix` or `permanent`.

    // Core Provider
    Get.lazyPut(() => FirebaseProvider());

    // Core Repositories - they are created on-demand.
    Get.lazyPut(() => AuthRepository(Get.find()));
    Get.lazyPut(() => UserRepository());
    Get.lazyPut(() => GroupRepository());
    Get.lazyPut(() => ExpenseRepository());
    Get.lazyPut(() => FamilyRepository());

    // Group Controller (CRITICAL FIX)
    // Registering the GroupController here ensures AuthController and other
    // controllers that depend on it via Get.find() can access it immediately.
    Get.lazyPut(() => GroupController());

    // Authentication Controller
    Get.lazyPut(() => AuthController());
  }
}
