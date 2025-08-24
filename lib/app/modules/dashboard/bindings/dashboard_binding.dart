import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // The GroupRepository must be available before the controller that uses it.
    // This makes the repository instance accessible to the entire dashboard feature.
    Get.lazyPut<GroupRepository>(() => GroupRepository());

    // The DashboardController depends on the GroupRepository, which it will
    // now be able to find using Get.find().
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}