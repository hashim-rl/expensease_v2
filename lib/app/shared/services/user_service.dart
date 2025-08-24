import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final Map<String, String> _userNames = {}; // Simple cache

  // Gets a user's name from their UID, caching the result.
  Future<String> getUserName(String uid) async {
    if (_userNames.containsKey(uid)) {
      return _userNames[uid]!;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['fullName'] ?? 'Unknown User';
        _userNames[uid] = name;
        return name;
      }
    } catch (e) {
      return 'Unknown User';
    }
    return 'Unknown User';
  }
}