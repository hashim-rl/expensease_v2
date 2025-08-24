import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/notification_model.dart';

class NotificationsController extends GetxController {
  final isLoading = true.obs;
  final notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  void fetchNotifications() {
    isLoading.value = true;
    // TODO: Replace this with a real call to fetch notifications from Firestore
    // For now, we use mock data that matches the design
    Future.delayed(const Duration(seconds: 1), () {
      notifications.value = [
        NotificationModel(
          icon: Icons.receipt_long,
          iconColor: Colors.orange.shade100,
          title: "John Doe added a new bill 'Groceries'",
          timestamp: "2 hours ago",
        ),
        NotificationModel(
          icon: Icons.payment,
          iconColor: Colors.purple.shade100,
          title: "John Doe added a payment",
          timestamp: "2 hours ago",
        ),
        NotificationModel(
          icon: Icons.credit_card,
          iconColor: Colors.blue.shade100,
          title: "You received a payment of \$20 from Jane Smith",
          timestamp: "2 hours ago",
        ),
        NotificationModel(
          icon: Icons.wallet_giftcard,
          iconColor: Colors.yellow.shade100,
          title: "ExpensEase: Your monthly report is ready.",
          timestamp: "2 hours ago",
        ),
      ];
      isLoading.value = false;
    });
  }
}