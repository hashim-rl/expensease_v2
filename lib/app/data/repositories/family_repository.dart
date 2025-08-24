import 'package:expensease/app/data/models/family_task_model.dart';
import 'package:expensease/app/data/models/shared_document_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyRepository {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // --- Task Methods ---
  Stream<List<FamilyTaskModel>> getTasksStream(String groupId) {
    return _firebaseProvider.getTasksStream(groupId).map((snapshot) =>
        snapshot.docs.map((doc) => FamilyTaskModel.fromFirestore(doc)).toList()); // FIX: Renamed fromSnapshot
  }

  Future<void> addTask(String groupId, String title) async {
    if (_uid == null) return;
    final task = FamilyTaskModel(
      id: FirebaseFirestore.instance.collection('tmp').doc().id,
      title: title,
      createdBy: _uid!,
      isCompleted: false,
    );
    await _firebaseProvider.addTask(groupId, task);
  }

  Future<void> updateTaskStatus(String groupId, String taskId, bool isCompleted) {
    return _firebaseProvider.updateTaskStatus(groupId, taskId, isCompleted);
  }

  // --- Document Methods ---
  Stream<List<SharedDocumentModel>> getDocumentsStream(String groupId) {
    return _firebaseProvider.getDocumentsStream(groupId).map((snapshot) =>
        snapshot.docs.map((doc) => SharedDocumentModel.fromFirestore(doc)).toList()); // FIX: Renamed fromSnapshot
  }

  Future<void> saveDocumentMetadata(String groupId, String fileName, String downloadUrl) async {
    if (_uid == null) return;
    final doc = SharedDocumentModel(
      id: FirebaseFirestore.instance.collection('tmp').doc().id,
      fileName: fileName,
      downloadUrl: downloadUrl,
      uploadedBy: _uid!,
      uploadDate: Timestamp.now(),
    );
    await _firebaseProvider.addDocument(groupId, doc);
  }
}