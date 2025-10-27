import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/split_setup_controller.dart';

class SplitSetupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplitSetupController>(() => SplitSetupController());
  }
}