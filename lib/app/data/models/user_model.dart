import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String nickname;
  final String? profilePicUrl;
  final Map<String, dynamic> groups;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.nickname,
    this.profilePicUrl,
    this.groups = const {},
  });

  /// --- THIS IS THE BULLETPROOF FIX for data parsing ---
  /// This factory constructor will never fail. It safely checks the type of
  /// every single field from Firestore and provides a default value if a
  /// field is null or the wrong type. This prevents a single bad user
  /// document from causing the entire member list to fail.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper to safely get a string, providing a default value if null or not a string.
    String safeGetString(String key, {String defaultValue = ''}) {
      final value = data[key];
      return value is String ? value.isNotEmpty ? value : defaultValue : defaultValue;
    }

    // Safely get the nickname, falling back to fullName if it's missing or empty.
    String getNickname() {
      final nickname = safeGetString('nickname');
      if (nickname.isNotEmpty) return nickname;
      return safeGetString('fullName', defaultValue: 'Unnamed Member');
    }

    // Safely get the groups map.
    Map<String, dynamic> getGroups() {
      final groupsData = data['groups'];
      return groupsData is Map<String, dynamic> ? Map<String, dynamic>.from(groupsData) : {};
    }

    try {
      return UserModel(
        uid: doc.id,
        email: safeGetString('email', defaultValue: 'no-email@example.com'),
        fullName: safeGetString('fullName', defaultValue: 'Unnamed Member'),
        nickname: getNickname(),
        profilePicUrl: safeGetString('profilePicUrl'),
        groups: getGroups(),
      );
    } catch (e) {
      debugPrint("!!! CRITICAL ERROR: FAILED to parse UserModel for doc ID: ${doc.id}. Error: $e");
      // Return a valid, but clearly marked, default user to prevent app crash.
      return UserModel(
        uid: doc.id,
        email: 'error@example.com',
        fullName: 'Parsing Error User',
        nickname: 'Error User',
      );
    }
  }
  // --- END OF FIX ---

  /// Converts the UserModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'nickname': nickname,
      'profilePicUrl': profilePicUrl,
      'groups': groups,
    };
  }
}