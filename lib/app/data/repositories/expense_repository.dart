import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';

/// ExpenseRepository handles all data operations related to expenses,
/// such as creating, fetching, and managing them within a group.
class ExpenseRepository {
  final FirebaseProvider _firebaseProvider;

  /// Constructor uses dependency injection for better testability and structure.
  ExpenseRepository({FirebaseProvider? provider})
      : _firebaseProvider = provider ?? FirebaseProvider();

  /// Returns a live stream of all expenses for a given group ID.
  Stream<List<ExpenseModel>> getExpensesStreamForGroup(String groupId) {
    try {
      return _firebaseProvider.getExpensesForGroup(groupId).map((snapshot) {
        return snapshot.docs
            .map((doc) => ExpenseModel.fromSnapshot(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to get expenses stream: $e');
    }
  }

  /// Fetches a list of expenses within a specific date range for reporting.
  Future<List<ExpenseModel>> getExpensesForReport({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firebaseProvider.getExpensesForDateRange(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      return snapshot.docs
          .map((doc) => ExpenseModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load report data: $e');
    }
  }

  /// Creates a new expense document in the 'expenses' sub-collection of a group.
  Future<void> addExpense({
    required String groupId,
    required String description,
    required double totalAmount,
    required DateTime date,
    required String paidById,
    required Map<String, double> splitBetween,
    String? category,
    String? notes,
    String? receiptUrl,
  }) async {
    try {
      // Generate a new document reference in the expenses sub-collection
      final expenseRef = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .doc();

      final newExpense = ExpenseModel(
        id: expenseRef.id, // ✅ use Firestore-generated ID
        description: description,
        totalAmount: totalAmount,
        date: date,
        paidById: paidById,
        splitBetween: splitBetween,
        category: category,
        notes: notes,
        receiptUrl: receiptUrl,
        createdAt: Timestamp.now(),
      );

      // Write to Firestore
      await expenseRef.set(newExpense.toFirestore());

      // Debug print for development
      print("Expense added: ${newExpense.description} "
          "Amount=${newExpense.totalAmount} "
          "Group=$groupId ID=${expenseRef.id}");
    } catch (e) {
      print("Error adding expense: $e");
      throw Exception('Failed to add expense. Please try again.');
    }
  }
}