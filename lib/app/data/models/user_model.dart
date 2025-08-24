import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? profilePicUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.profilePicUrl,
  });

  /// Creates a UserModel from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      profilePicUrl: data['profilePicUrl'],
    );
  }

  /// Converts the UserModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      // The uid is the document ID, so we don't need to store it inside the document.
      'email': email,
      'fullName': fullName,
      'profilePicUrl': profilePicUrl,
    };
  }
}