import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String frequency; // e.g., 'Weekly', 'Monthly'
  final DateTime nextDueDate;

  // --- NEW FIELDS ADDED ---
  final String paidBy;
  final Map<String, double> split;
  final String? whatsappNumber;

  RecurringExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.paidBy,
    required this.split,
    this.whatsappNumber,
  });

  factory RecurringExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely parse the split map
    Map<String, double> splitMap = {};
    if (data['split'] != null) {
      data['split'].forEach((key, value) {
        splitMap[key] = (value as num).toDouble();
      });
    }

    return RecurringExpenseModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['totalAmount'] ?? data['amount'] ?? 0).toDouble(), // Handle both keys just in case
      frequency: data['frequency'] ?? '',
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      // Map new fields
      paidBy: data['paidBy'] ?? '',
      split: splitMap,
      whatsappNumber: data['whatsappNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount, // Can be used interchangeably with totalAmount
      'totalAmount': amount,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'paidBy': paidBy,
      'split': split,
      'whatsappNumber': whatsappNumber,
    };
  }
}