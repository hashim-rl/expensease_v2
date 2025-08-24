import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/user_model.dart' as model;
import 'package:expensease/app/data/models/group_model.dart' as model;
import 'package:expensease/app/data/models/expense_model.dart' as model;
import 'package:expensease/app/data/models/member_model.dart';
import 'package:expensease/app/data/models/family_task_model.dart';
import 'package:expensease/app/data/models/shared_document_model.dart';

class FirebaseProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Public Getters for Firestore Access ---
  FirebaseFirestore get firestore => _firestore;
  CollectionReference<Map<String, dynamic>> get groupsCollection => _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> membersCollection(String groupId) =>
      groupsCollection.doc(groupId).collection('members');

  // --- Auth Methods ---

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
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
    // NOTE: Assuming user_model.dart also has a toFirestore() method.
    // If it's still toJson(), this will need to be updated as well.
    return _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserProfilePicture(String uid, String url) {
    return _firestore.collection('users').doc(uid).update({'profilePicUrl': url});
  }

  Future<void> updateUserName(String uid, String newName) {
    return _firestore.collection('users').doc(uid).update({'fullName': newName});
  }

  Future<QuerySnapshot<Map<String, dynamic>>> findUserByEmail(String email) {
    return _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
  }

  // --- Group Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getGroupsForUser(String uid) {
    return groupsCollection.where('memberIds', arrayContains: uid).snapshots();
  }

  Future<void> createGroup(model.GroupModel group) {
    // FIX: Changed toJson() to toFirestore()
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
    // FIX: Changed toJson() to toFirestore()
    return membersCollection(groupId).doc(member.id).set(member.toFirestore());
  }

  Future<bool> isUserMemberOfGroup(String groupId, String uid) async {
    final doc = await membersCollection(groupId).doc(uid).get();
    return doc.exists;
  }

  // --- Expense Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesForGroup(String groupId) {
    return groupsCollection.doc(groupId).collection('expenses').orderBy('date', descending: true).snapshots();
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
    // NOTE: Assuming expense_model.dart has a toFirestore() method.
    return groupsCollection
        .doc(groupId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toFirestore());
  }

  // --- Family Feature Methods ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getTasksStream(String groupId) {
    return groupsCollection.doc(groupId).collection('tasks').snapshots();
  }

  Future<void> addTask(String groupId, FamilyTaskModel task) {
    // NOTE: Assuming family_task_model.dart has a toFirestore() method.
    return groupsCollection.doc(groupId).collection('tasks').doc(task.id).set(task.toFirestore());
  }

  Future<void> updateTaskStatus(String groupId, String taskId, bool isCompleted) {
    return groupsCollection.doc(groupId).collection('tasks').doc(taskId).update({'isCompleted': isCompleted});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDocumentsStream(String groupId) {
    return groupsCollection.doc(groupId).collection('documents').orderBy('uploadDate', descending: true).snapshots();
  }

  Future<void> addDocument(String groupId, SharedDocumentModel doc) {
    // NOTE: Assuming shared_document_model.dart has a toFirestore() method.
    return groupsCollection.doc(groupId).collection('documents').doc(doc.id).set(doc.toFirestore());
  }
}