import 'package:get/get.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
// --- FIX: IMPORT THE MISSING REPOSITORIES ---
import 'package:expensease/app/data/repositories/user_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true ensures that the service is re-initialized if it's ever accidentally removed.

    // Step 1: Core provider for Firebase communication.
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);

    // --- THIS IS THE FIX ---
    // We were only putting the AuthRepository. Now we are putting ALL the
    // repositories that the application needs to function. This is the
    // root cause of the "no members found" bug.

    // Step 2: Authentication services.
    Get.lazyPut<AuthRepository>(
          () => AuthRepository(Get.find<FirebaseProvider>()),
      fenix: true,
    );
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);

    // Step 3: Core data repositories for the main application logic.
    // These were completely missing before.
    Get.lazyPut<UserRepository>(() => UserRepository(), fenix: true);
    Get.lazyPut<GroupRepository>(() => GroupRepository(), fenix: true);
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(), fenix: true);
  }
}