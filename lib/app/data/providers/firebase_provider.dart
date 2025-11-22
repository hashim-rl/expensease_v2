import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/user_model.dart' as model;
import 'package:expensease/app/data/models/group_model.dart' as model;
import 'package:expensease/app/data/models/expense_model.dart' as model;
import 'package:expensease/app/data/models/member_model.dart';

class FirebaseProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Public Getters for Firestore Access ---
  FirebaseFirestore get firestore => _firestore;

  CollectionReference<Map<String, dynamic>> get groupsCollection =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> membersCollection(String groupId) =>
      groupsCollection.doc(groupId).collection('members');

  // --- FIXED: Added missing helper for Expenses ---
  CollectionReference<Map<String, dynamic>> expensesCollection(String groupId) =>
      groupsCollection.doc(groupId).collection('expenses');

  // --- FIXED: Added missing helper for Notifications ---
  CollectionReference<Map<String, dynamic>> notificationsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // --- Auth Methods ---

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> logInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // --- User Methods ---

  Future<void> createUserDocument(model.UserModel user) {
    return _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserProfilePicture(String uid, String url) {
    return _firestore
        .collection('users')
        .doc(uid)
        .update({'profilePicUrl': url});
  }

  Future<void> updateUserName(String uid, String newName) {
    return _firestore.collection('users').doc(uid).update({'fullName': newName});
  }

  Future<QuerySnapshot<Map<String, dynamic>>> findUserByEmail(String email) {
    return _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
  }

  // --- Group Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getGroupsForUser(String uid) {
    return groupsCollection
        .where('memberIds', arrayContains: uid)
        .orderBy('createdAt', descending: true) // Sorted Newest First
        .snapshots();
  }

  Future<void> createGroup(model.GroupModel group) {
    return groupsCollection.doc(group.id).set(group.toFirestore());
  }

  Future<void> updateGroupMemberIds(String groupId, String uid) {
    return groupsCollection.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([uid])
    });
  }

  // --- Member Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getMembersStream(String groupId) {
    return membersCollection(groupId).snapshots();
  }

  Future<void> createMemberInGroup(String groupId, MemberModel member) {
    return membersCollection(groupId).doc(member.id).set(member.toFirestore());
  }

  Future<bool> isUserMemberOfGroup(String groupId, String uid) async {
    final doc = await membersCollection(groupId).doc(uid).get();
    return doc.exists;
  }

  // --- Expense Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesForGroup(
      String groupId) {
    return expensesCollection(groupId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getExpensesForDateRange({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return expensesCollection(groupId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .get();
  }

  Future<void> addExpense(String groupId, model.ExpenseModel expense) {
    return expensesCollection(groupId)
        .doc(expense.id)
        .set(expense.toFirestore());
  }

  // --- NEW: Notification Methods (Required for Feature Completion) ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream(String uid) {
    return notificationsCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) {
    return notificationsCollection(uid).doc(notificationId).update({'isRead': true});
  }

  Future<void> clearAllNotifications(String uid) async {
    final batch = _firestore.batch();
    final snapshots = await notificationsCollection(uid).get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}