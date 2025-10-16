import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String expenseId;
  final String authorUid;
  final String text;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.expenseId,
    required this.authorUid,
    required this.text,
    required this.timestamp,
  });

  // Factory method to create a CommentModel from a Firestore DocumentSnapshot
  factory CommentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      expenseId: data['expenseId'] ?? '',
      authorUid: data['authorUid'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Method to convert the model to a Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'authorUid': authorUid,
      'text': text,
      'timestamp': timestamp,
    };
  }
}