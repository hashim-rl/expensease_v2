import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // All dependencies are global now, so we only need to load the controller itself.
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}