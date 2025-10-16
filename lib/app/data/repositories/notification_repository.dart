import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/notification_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/services/auth_service.dart';

class NotificationRepository {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final AuthService _authService = Get.find<AuthService>();

  String? get _uid => _authService.currentUser.value?.uid;

  /// Returns a live stream of all unread notifications for the current user,
  /// ordered by timestamp (newest first).
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_uid == null) {
      return Stream.value([]);
    }

    // Notifications are typically stored in a sub-collection under the user's document
    // e.g., /users/{userId}/notifications
    final notificationsQuery = _firebaseProvider.firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false) // Filter for unread notifications
        .orderBy('timestamp', descending: true);

    return notificationsQuery.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _notificationFromSnapshot(doc)).toList();
    });
  }

  // Helper function to convert Firestore snapshot to model (simplified for this context)
  NotificationModel _notificationFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Return a placeholder or handle error
      return NotificationModel(
        id: doc.id,
        title: 'Error Loading Notification',
        timestamp: DateTime.now(),
        isRead: true,
        type: 'error',
        senderUid: '',
      );
    }

    // NOTE: This assumes a complete NotificationModel implementation.
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'New Alert',
      senderUid: data['senderUid'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'general',
    );
  }

  /// Marks a specific notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_uid == null) return;
    try {
      await _firebaseProvider.firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print("Error marking notification $notificationId as read: $e");
      throw Exception('Failed to update notification status.');
    }
  }

  /// Clears all unread notifications for the current user.
  Future<void> clearAllNotifications() async {
    if (_uid == null) return;
    try {
      // Find all unread notifications in a batch and mark them as read
      final batch = _firebaseProvider.firestore.batch();
      final snapshot = await _firebaseProvider.firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print("Error clearing all notifications: $e");
      throw Exception('Failed to clear notifications.');
    }
  }
}