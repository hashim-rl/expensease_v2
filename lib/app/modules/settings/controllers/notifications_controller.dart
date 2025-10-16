import 'package:get/get.dart';
import 'package:expensease/app/data/models/notification_model.dart';
// --- NEW IMPORT ---
import 'package:expensease/app/data/repositories/notification_repository.dart';
// ------------------

class NotificationsController extends GetxController {
  // --- INJECTED DEPENDENCY ---
  final NotificationRepository _repository = Get.find<NotificationRepository>();
  // ---------------------------

  final isLoading = true.obs;
  // CHANGED: List type should match the repository's model, not the mock data
  final notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Bind notifications to a live stream from the repository
    _bindNotificationsStream();
  }

  // UPDATED: Use stream binding instead of one-time fetch with mock data
  void _bindNotificationsStream() {
    isLoading.value = true;
    try {
      // Stream only unread notifications
      notifications.bindStream(_repository.getNotificationsStream());
    } catch (e) {
      Get.snackbar('Error', 'Failed to load notifications: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // NOTE: fetchNotifications is no longer needed.

  // --- NEW METHOD: Mark a single notification as read/dismissed ---
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);
      // The notification will automatically disappear from the list via the stream filter
      Get.snackbar('Dismissed', 'Notification dismissed.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to dismiss notification.');
    }
  }

  // --- NEW METHOD: Clear all notifications ---
  Future<void> clearAllNotifications() async {
    try {
      await _repository.clearAllNotifications();
      // The entire list will clear automatically via the stream filter
      Get.snackbar('Success', 'All notifications cleared.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear all notifications.');
    }
  }
}