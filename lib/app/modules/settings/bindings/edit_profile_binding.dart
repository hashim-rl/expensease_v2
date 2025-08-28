import 'package:get/get.dart';
import 'package:expensease/app/modules/settings/controllers/edit_profile_controller.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserRepository>(() => UserRepository());
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}