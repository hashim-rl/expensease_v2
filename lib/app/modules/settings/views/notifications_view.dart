import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/settings/controllers/notifications_controller.dart';
import 'package:expensease/app/shared/widgets/list_shimmer_loader.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  // Helper to determine icon and color based on notification type
  Map<String, dynamic> _getIconData(String type) {
    switch (type) {
      case 'expense_added':
        return {'icon': Icons.receipt_long, 'color': Colors.orange};
      case 'payment_received':
        return {'icon': Icons.credit_card, 'color': Colors.green};
      case 'payment_sent':
        return {'icon': Icons.payment, 'color': Colors.redAccent};
      case 'report_ready':
        return {'icon': Icons.analytics, 'color': Colors.blue};
      default:
        return {'icon': Icons.notifications, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Obx(() => controller.notifications.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Clear All Notifications',
            onPressed: controller.clearAllNotifications,
          )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ListShimmerLoader();
        }
        if (controller.notifications.isEmpty) {
          return const Center(
            child: Text("You have no unread notifications.", style: TextStyle(color: Colors.white70)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final iconData = _getIconData(notification.type);

            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                color: Colors.red,
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              onDismissed: (direction) {
                // Calls the controller to mark it as read/deleted in Firestore
                controller.markNotificationAsRead(notification.id);
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: const Color(0xFF2D2D44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconData['color']?.withOpacity(0.2) ?? Colors.grey.shade700,
                    child: Icon(iconData['icon'], color: iconData['color'], size: 20),
                  ),
                  title: Text(notification.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    // Format the DateTime timestamp
                    DateFormat('MMM d, h:mm a').format(notification.timestamp),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    // TODO: Implement navigation logic based on notification.type
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}