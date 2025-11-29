import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id; // Firebase Auth UID for real users, or a random ID for placeholders
  final String name;
  final String? email;
  final bool isPlaceholder; // True if they were added by name only
  final String role; // e.g., 'Admin', 'Editor', 'Viewer'

  MemberModel({
    required this.id,
    required this.name,
    this.email,
    this.isPlaceholder = false,
    this.role = 'Viewer',
  });

  /// Creates a MemberModel from a Firestore document snapshot.
  /// UPDATED: Accepts a generic DocumentSnapshot and safely casts data.
  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    // We safely cast the data to a Map, providing an empty map fallback if null.
    // This fixes the "type 'DocumentSnapshot<Object?>' is not a subtype of..." error.
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MemberModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      isPlaceholder: data['isPlaceholder'] ?? false,
      role: data['role'] ?? 'Viewer',
    );
  }

  /// Converts the MemberModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      // The ID is the document key, so it's not needed inside the document data.
      'name': name,
      'email': email,
      'isPlaceholder': isPlaceholder,
      'role': role,
    };
  }
}