import 'package:get/get.dart';
import 'package:expensease/app/modules/settings/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories are now loaded globally, so we only need the controller.
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}