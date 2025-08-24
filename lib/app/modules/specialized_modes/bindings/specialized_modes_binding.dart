import 'package:get/get.dart';
import '../controllers/specialized_modes_controller.dart';

class SpecializedModesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpecializedModesController>(() => SpecializedModesController());
  }
}