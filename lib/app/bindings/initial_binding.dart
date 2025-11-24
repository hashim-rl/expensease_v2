import 'package:get/get.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
// --- NEW IMPORTS (CRITICAL FOR APP STABILITY) ---
import 'package:expensease/app/services/auth_service.dart';
import 'package:expensease/app/shared/services/user_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // --- STEP 0: SERVICES (EAGER LOAD) ---
    // These must be alive immediately when the app starts.
    // UserService is needed for Reports to show names instead of UIDs.
    Get.put(AuthService());
    Get.put(UserService());

    // --- STEP 1: PROVIDERS ---
    // Core provider for Firebase communication.
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);

    // --- STEP 2: REPOSITORIES ---
    // We put all repositories the app needs to function.

    Get.lazyPut<AuthRepository>(
          () => AuthRepository(Get.find<FirebaseProvider>()),
      fenix: true,
    );

    Get.lazyPut<UserRepository>(() => UserRepository(), fenix: true);
    Get.lazyPut<GroupRepository>(() => GroupRepository(), fenix: true);
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(), fenix: true);

    // --- STEP 3: CONTROLLERS ---
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}