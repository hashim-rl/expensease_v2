import 'package:expensease/app/data/models/family_task_model.dart';
import 'package:expensease/app/data/models/shared_document_model.dart';
// Note: Keeping FirebaseProvider import, but directly using Firestore instance
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyRepository {
  // Using direct Firestore access for full transparency and portability
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // --- Utility to get sub-collection references ---
  CollectionReference _tasksCollection(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('tasks');

  CollectionReference _documentsCollection(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('documents');

  // --- Task Methods ---

  @Deprecated('Use direct collection methods for clarity and robustness.')
  Stream<List<FamilyTaskModel>> getTasksStream(String groupId) {
    // Orders tasks by creation time, with completed items usually last (by default, false < true)
    return _tasksCollection(groupId)
        .orderBy('isCompleted')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => FamilyTaskModel.fromFirestore(doc)).toList());
  }

  Future<void> addTask(String groupId, String title) async {
    if (_uid == null) throw Exception("User not authenticated.");

    final taskData = {
      'title': title,
      'createdBy': _uid,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _tasksCollection(groupId).add(taskData);
  }

  Future<void> updateTaskStatus(String groupId, String taskId, bool isCompleted) {
    return _tasksCollection(groupId).doc(taskId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  // --- Document Methods ---

  @Deprecated('Use direct collection methods for clarity and robustness.')
  Stream<List<SharedDocumentModel>> getDocumentsStream(String groupId) {
    return _documentsCollection(groupId)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => SharedDocumentModel.fromFirestore(doc)).toList());
  }

  Future<void> saveDocumentMetadata(String groupId, String fileName, String downloadUrl) async {
    if (_uid == null) throw Exception("User not authenticated.");

    final docData = {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'uploadedBy': _uid,
      'uploadDate': FieldValue.serverTimestamp(),
    };
    await _documentsCollection(groupId).add(docData);
  }
}