import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String frequency; // e.g., 'Weekly', 'Monthly'
  final Timestamp nextDueDate;

  RecurringExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
  });

// TODO: Add fromSnapshot and toJson methods
}