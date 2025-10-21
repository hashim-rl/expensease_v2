import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String frequency; // e.g., 'Weekly', 'Monthly'
  final DateTime nextDueDate;

  RecurringExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
  });

  factory RecurringExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RecurringExpenseModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      frequency: data['frequency'] ?? '',
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
    };
  }
}