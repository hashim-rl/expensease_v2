import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';

class UserRepository {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<UserModel?> getCurrentUser() async {
    if (_uid == null) return null;
    final doc = await _firebaseProvider.getUserDocument(_uid);
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<String?> uploadProfilePicture(XFile image) async {
    if (_uid == null) return null;
    try {
      final file = File(image.path);
      final ref = FirebaseStorage.instance.ref('profile_pictures/$_uid');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      await _firebaseProvider.updateUserProfilePicture(_uid, downloadUrl);
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserName(String newName) async {
    if (_uid == null) return;
    await _firebaseProvider.updateUserName(_uid, newName);
  }

  // --- NEW METHOD ADDED HERE ---
  /// A simple method to get the current logged-in user's ID.
  String? getCurrentUserId() {
    return _uid;
  }
}