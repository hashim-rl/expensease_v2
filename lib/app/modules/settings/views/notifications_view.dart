import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/settings/controllers/notifications_controller.dart';
import 'package:expensease/app/shared/widgets/list_shimmer_loader.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a dark background to match the design
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Ensure app bar text and icons are white on the dark background
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          // You can create a dark-themed shimmer loader for a better look
          return const ListShimmerLoader();
        }
        if (controller.notifications.isEmpty) {
          return const Center(
            child: Text("You have no notifications.", style: TextStyle(color: Colors.white70)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              // Use a slightly lighter dark color for the cards
              color: const Color(0xFF2D2D44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.iconColor,
                  child: Icon(notification.icon, color: Colors.black87, size: 20),
                ),
                title: Text(notification.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  notification.timestamp,
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  // TODO: Navigate to the relevant expense or group
                },
              ),
            );
          },
        );
      }),
    );
  }
}