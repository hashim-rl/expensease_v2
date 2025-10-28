import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String description;
  final double totalAmount;
  final DateTime date;
  final String paidById;
  final Map<String, double> splitBetween;
  final String? category;
  final String? notes;
  final String? receiptUrl;
  final Timestamp createdAt;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.date,
    required this.paidById,
    required this.splitBetween,
    this.category,
    this.notes,
    this.receiptUrl,
    required this.createdAt,
  });

  /// Creates an ExpenseModel from a Firestore document snapshot.
  // --- UPDATED: Renamed 'fromSnapshot' to 'fromFirestore' ---
  factory ExpenseModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ExpenseModel(
      id: doc.id,
      description: data['description'] ?? '',
      totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
      date: (data['date'] as Timestamp? ?? Timestamp.now()).toDate(),
      paidById: data['paidById'] ?? '',
      splitBetween: (data['splitBetween'] is Map)
          ? Map<String, double>.from(
          data['splitBetween'].map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble())))
          : {},
      category: data['category'],
      notes: data['notes'],
      receiptUrl: data['receiptUrl'],
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt']
          : Timestamp.now(),
    );
  }

  /// Converts the ExpenseModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'totalAmount': totalAmount,
      'date': Timestamp.fromDate(date),
      'paidById': paidById,
      'splitBetween': splitBetween,
      'category': category,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt,
    };
  }
}