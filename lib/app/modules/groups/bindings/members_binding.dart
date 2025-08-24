import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/members_controller.dart';

class MembersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MembersController>(() => MembersController());
  }
}