import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String description;
  final double totalAmount;
  final DateTime date;
  final String paidById; // FIX 1: Renamed for clarity
  final Map<String, double> splitBetween; // FIX 2: Renamed for clarity
  final String? category;
  final String? notes;
  final String? receiptUrl;
  final Timestamp createdAt; // FIX 3: Added for better sorting

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
  factory ExpenseModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) { // FIX 4: Renamed
    final data = doc.data() ?? {};

    return ExpenseModel(
      id: doc.id,
      description: data['description'] ?? '',
      totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
      date: (data['date'] as Timestamp? ?? Timestamp.now()).toDate(),
      paidById: data['paidById'] ?? '',
      splitBetween: (data['splitBetween'] is Map)
          ? Map<String, double>.from(data['splitBetween'])
          : {},
      category: data['category'],
      notes: data['notes'],
      receiptUrl: data['receiptUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Converts the ExpenseModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() { // FIX 4: Renamed
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