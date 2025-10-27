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
    return groupsCollection.where('memberIds', arrayContains: uid).snapshots();
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

  // REMOVED 'PLAYA' from here
  Future<bool> isUserMemberOfGroup(String groupId, String uid) async {
    final doc = await membersCollection(groupId).doc(uid).get();
    return doc.exists;
  }

  // --- Expense Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesForGroup(
      String groupId) {
    return groupsCollection
        .doc(groupId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getExpensesForDateRange({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return groupsCollection
        .doc(groupId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: false)
        .get();
  }

  Future<void> addExpense(String groupId, model.ExpenseModel expense) {
    return groupsCollection
        .doc(groupId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toFirestore());
  }

// --- Family Feature Methods (REMOVED) ---
}