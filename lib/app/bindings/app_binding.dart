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
    // --- THIS IS THE DEFINITIVE FIX FOR DEPENDENCY INJECTION ---
    // This binding now uses `Get.lazyPut` without `fenix` or `permanent`.
    // Services will be created when needed and disposed of automatically when
    // no longer in use, which is a more efficient use of memory.
    // The critical AuthService is already handled permanently in main.dart.

    // Core Provider
    Get.lazyPut(() => FirebaseProvider());

    // Core Repositories - they are created on-demand.
    Get.lazyPut(() => AuthRepository(Get.find()));
    Get.lazyPut(() => UserRepository());
    Get.lazyPut(() => GroupRepository());
    Get.lazyPut(() => ExpenseRepository());
    Get.lazyPut(() => FamilyRepository());

    // Authentication Controller
    Get.lazyPut(() => AuthController());
  }
}