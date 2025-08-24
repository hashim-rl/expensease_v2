import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

// This binding ensures the AuthController is available for the authentication screens.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
          () => AuthController(),
    );
  }
}