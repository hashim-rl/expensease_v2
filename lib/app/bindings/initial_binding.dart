import 'package:get/get.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart'; // Import the provider
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Step 1: Make the FirebaseProvider available first.
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);

    // Step 2: Now, create the AuthRepository and give it the FirebaseProvider it needs.
    Get.lazyPut<AuthRepository>(
          () => AuthRepository(Get.find<FirebaseProvider>()),
      fenix: true,
    );

    // Step 3: The AuthController can now be created because its dependency (AuthRepository) is available.
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}