import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/settings/controllers/notifications_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:intl/intl.dart'; // For date formatting

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear All",
            onPressed: () {
              if (controller.notifications.isNotEmpty) {
                _showClearConfirmation();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notifications_off_outlined,
            title: 'No Notifications',
            subtitle: 'You are all caught up!',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final isRead = notification.isRead;

            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: AppColors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                // Optionally implement delete-one logic here
                // controller.deleteNotification(notification.id);
              },
              child: Container(
                color: isRead ? Colors.transparent : AppColors.primaryBlue.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey.shade200 : AppColors.primaryLight,
                    child: Icon(
                      _getIconForType(notification.type),
                      color: isRead ? Colors.grey : AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: isRead
                        ? AppTextStyles.bodyText1
                        : AppTextStyles.bodyBold,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  onTap: () => controller.markAsRead(notification.id),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showClearConfirmation() {
    Get.defaultDialog(
      title: "Clear Notifications",
      middleText: "Are you sure you want to delete all notifications?",
      textConfirm: "Clear All",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.red,
      onConfirm: () {
        controller.clearAll();
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'expense': return Icons.receipt_long;
      case 'group': return Icons.group_add;
      case 'settlement': return Icons.handshake;
      case 'alert': return Icons.warning_amber;
      default: return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat.MMMd().format(time);
    }
  }
}