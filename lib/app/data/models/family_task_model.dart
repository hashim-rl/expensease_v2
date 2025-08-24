import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyTaskModel {
  final String id;
  final String title;
  final bool isCompleted;
  final String createdBy;

  FamilyTaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdBy,
  });

  /// This factory constructor builds a FamilyTaskModel from a Firestore document.
  factory FamilyTaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FamilyTaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// This method converts the model into a format that can be saved to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
    };
  }
}