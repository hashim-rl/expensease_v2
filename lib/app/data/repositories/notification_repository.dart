import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensease/app/data/models/notification_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/services/auth_service.dart';
import 'package:get/get.dart';

class NotificationRepository {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final AuthService _authService = Get.find<AuthService>();

  String? get _uid => _authService.user.value?.uid;

  /// Returns a live stream of ALL notifications (read and unread) for the current user,
  /// ordered by creation time (newest first).
  Stream<List<NotificationModel>> getUserNotificationsStream() {
    if (_uid == null) {
      return Stream.value([]);
    }

    final notificationsQuery = _firebaseProvider.firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true); // Matches Model 'createdAt'

    return notificationsQuery.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Use the Factory constructor we created in the Model
        return NotificationModel.fromMap(
            doc.data(),
            doc.id
        );
      }).toList();
    });
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
      throw Exception('Failed to update notification status: $e');
    }
  }

  /// Deletes all notifications for the current user.
  /// Used when the user clicks "Clear All" in the View.
  Future<void> clearAllNotifications() async {
    if (_uid == null) return;
    try {
      final collectionRef = _firebaseProvider.firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications');

      final snapshot = await collectionRef.get();

      // Batch delete for efficiency and atomicity
      final batch = _firebaseProvider.firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear notifications: $e');
    }
  }
}