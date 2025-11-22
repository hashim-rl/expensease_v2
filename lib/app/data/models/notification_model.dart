import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;        // Added to match View
  final DateTime createdAt; // Renamed from 'timestamp' to match View
  final bool isRead;
  final String type;        // e.g., 'expense', 'settlement'
  final String? senderUid;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.senderUid,
  });

  // Factory to create a NotificationModel from Firestore data
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      // Handle both Firestore Timestamp and standard DateTime strings
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'info',
      senderUid: map['senderUid'],
    );
  }

  // Convert to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type,
      'senderUid': senderUid,
    };
  }
}