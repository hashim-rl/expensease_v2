import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? senderUid;
  final IconData icon;
  final Color iconColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.senderUid,
    required this.icon,
    required this.iconColor,
  });
}