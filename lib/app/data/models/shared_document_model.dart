import 'package:cloud_firestore/cloud_firestore.dart';

class SharedDocumentModel {
  final String id;
  final String fileName;
  final String downloadUrl;
  final String uploadedBy;
  final Timestamp uploadDate;

  SharedDocumentModel({
    required this.id,
    required this.fileName,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.uploadDate,
  });

  /// This factory constructor builds a SharedDocumentModel from a Firestore document.
  factory SharedDocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedDocumentModel(
      id: doc.id,
      fileName: data['fileName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadDate: data['uploadDate'] ?? Timestamp.now(),
    );
  }

  /// This method converts the model into a format that can be saved to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'uploadedBy': uploadedBy,
      'uploadDate': uploadDate,
    };
  }
}