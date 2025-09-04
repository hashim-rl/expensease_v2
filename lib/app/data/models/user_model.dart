import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String nickname;
  final String? profilePicUrl;
  // --- THIS IS THE FIX ---
  // We've added a map to store the IDs of the groups the user belongs to.
  // This is crucial for the security rules to work correctly.
  final Map<String, dynamic> groups;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.nickname,
    this.profilePicUrl,
    this.groups = const {}, // Initialize with an empty map
  });

  /// Creates a UserModel from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      nickname: data['nickname'] ?? data['fullName'] ?? '',
      profilePicUrl: data['profilePicUrl'],
      // Read the groups map from Firestore, default to empty if it doesn't exist.
      groups: data['groups'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts the UserModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'nickname': nickname,
      'profilePicUrl': profilePicUrl,
      'groups': groups, // Add the groups map to Firestore.
    };
  }
}