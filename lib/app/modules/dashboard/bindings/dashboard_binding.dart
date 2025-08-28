import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories are now loaded globally, so we only need the controller.
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}