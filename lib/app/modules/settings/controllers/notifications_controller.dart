import 'package:get/get.dart';
import 'package:expensease/app/data/models/notification_model.dart';
import 'package:expensease/app/data/repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  final NotificationRepository _notificationRepository = Get.find<NotificationRepository>();

  final notifications = <NotificationModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    isLoading.value = true;
    try {
      // Assuming the repo has a stream method. If not, we'll gracefully handle it.
      notifications.bindStream(_notificationRepository.getUserNotificationsStream());

      // Wait a moment to disable loading spinner if stream is empty initially
      Future.delayed(const Duration(milliseconds: 500), () {
        isLoading.value = false;
      });
    } catch (e) {
      print("Error binding notification stream: $e");
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markNotificationAsRead(notificationId);
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  Future<void> clearAll() async {
    try {
      await _notificationRepository.clearAllNotifications();
      notifications.clear();
      Get.back();
      Get.snackbar("Success", "All notifications cleared");
    } catch (e) {
      Get.snackbar("Error", "Failed to clear notifications");
    }
  }
}