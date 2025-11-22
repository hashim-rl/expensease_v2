import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:expensease/app/data/models/comment_model.dart';
import 'package:expensease/app/data/models/recurring_expense_model.dart';

/// ExpenseRepository handles all data operations related to expenses,
/// such as creating, fetching, and managing them within a group.
class ExpenseRepository {
  final FirebaseProvider _firebaseProvider;

  /// Constructor uses dependency injection for better testability and structure.
  ExpenseRepository({FirebaseProvider? provider})
      : _firebaseProvider = provider ?? FirebaseProvider();

  // ----------------------------------------------------
  // CORE EXPENSE METHODS
  // ----------------------------------------------------

  /// Returns a live stream of all expenses for a given group ID.
  Stream<List<ExpenseModel>> getExpensesStreamForGroup(String groupId) {
    try {
      return _firebaseProvider.getExpensesForGroup(groupId).map((snapshot) {
        return snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to get expenses stream: $e');
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
        id: expenseRef.id,
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

    } catch (e) {
      throw Exception('Failed to add expense. Please try again.');
    }
  }

  // ----------------------------------------------------
  // RECURRING EXPENSE METHODS
  // ----------------------------------------------------

  /// Returns a live stream of all recurring expense templates for a given group ID.
  Stream<List<RecurringExpenseModel>> getRecurringExpensesStream(String groupId) {
    try {
      // Points to the recurringExpenses subcollection under the group
      final recurringQuery = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('recurringExpenses')
          .orderBy('nextDueDate', descending: false);

      return recurringQuery.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => RecurringExpenseModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to get recurring expenses stream: $e');
    }
  }

  /// Adds a new recurring expense template to the subcollection.
  Future<void> addRecurringExpenseTemplate({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required Map<String, double> split,
    required String frequency,
    required DateTime nextDueDate,
    String? whatsappNumber,
  }) async {
    try {
      final templateRef = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('recurringExpenses')
          .doc();

      final data = {
        'groupId': groupId,
        'description': description,
        'totalAmount': amount,
        'paidBy': paidBy,
        'split': split,
        'frequency': frequency,
        'nextDueDate': Timestamp.fromDate(nextDueDate),
        'whatsappNumber': whatsappNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await templateRef.set(data);

    } catch (e) {
      throw Exception('Failed to save recurring expense template.');
    }
  }

  /// Deletes a recurring expense template.
  Future<void> deleteRecurringExpenseTemplate({
    required String groupId,
    required String templateId,
  }) async {
    try {
      final templateRef = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('recurringExpenses')
          .doc(templateId);

      await templateRef.delete();
    } catch (e) {
      throw Exception('Failed to delete recurring expense template.');
    }
  }

  // --- NEW: Updates specific fields of a recurring expense template ---
  // This is essential for the automation engine to update 'nextDueDate'
  Future<void> updateRecurringExpenseTemplate({
    required String groupId,
    required String templateId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final templateRef = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('recurringExpenses')
          .doc(templateId);

      // Sanitize updates: Convert DateTime to Timestamp for Firestore
      final sanitizedUpdates = <String, dynamic>{};
      updates.forEach((key, value) {
        if (value is DateTime) {
          sanitizedUpdates[key] = Timestamp.fromDate(value);
        } else {
          sanitizedUpdates[key] = value;
        }
      });

      await templateRef.update(sanitizedUpdates);
    } catch (e) {
      throw Exception('Failed to update recurring expense: $e');
    }
  }
  // ------------------------------------------------------------------

  // ----------------------------------------------------
  // REPORTING & COMMENTS
  // ----------------------------------------------------

  /// Returns a live stream of all comments for a given expense.
  Stream<List<CommentModel>> getCommentsStreamForExpense(
      String groupId, String expenseId) {
    try {
      final commentsQuery = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .doc(expenseId)
          .collection('comments')
          .orderBy('timestamp', descending: true);

      return commentsQuery.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => CommentModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to get comments stream: $e');
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
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load report data: $e');
    }
  }

  /// Adds a new comment to the 'comments' sub-collection of an expense.
  Future<void> addComment({
    required String groupId,
    required String expenseId,
    required String authorUid,
    required String text,
  }) async {
    try {
      final commentsRef = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .doc(expenseId)
          .collection('comments');

      final newCommentData = {
        'expenseId': expenseId,
        'authorUid': authorUid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await commentsRef.add(newCommentData);

    } catch (e) {
      throw Exception('Failed to post comment. Please try again.');
    }
  }

  /// Adds a new expense document to record a debt settlement payment.
  Future<void> addPaymentExpense({
    required String groupId,
    required String payerUid,
    required String recipientUid,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Payment amount must be positive.');
      }

      final expenseRef = _firebaseProvider.firestore
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .doc();

      final newExpense = ExpenseModel(
        id: expenseRef.id,
        description: 'Payment from $payerUid to $recipientUid',
        totalAmount: amount,
        date: DateTime.now(),
        paidById: payerUid,
        splitBetween: {recipientUid: amount},
        category: 'Payment',
        notes: 'Settlement for simplified debt.',
        receiptUrl: null,
        createdAt: Timestamp.now(),
      );

      await expenseRef.set(newExpense.toFirestore());

    } catch (e) {
      throw Exception('Failed to record payment settlement. Please try again.');
    }
  }
}