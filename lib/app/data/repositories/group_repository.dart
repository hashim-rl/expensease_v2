import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/member_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';

/// GroupRepository handles all data operations related to groups,
/// such as creating, fetching, and managing members.
class GroupRepository {
  final FirebaseProvider _firebaseProvider;
  final FirebaseAuth _auth;

  /// Constructor uses dependency injection for better testability and structure.
  GroupRepository({
    FirebaseProvider? provider,
    FirebaseAuth? auth,
  })  : _firebaseProvider = provider ?? FirebaseProvider(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Private getter for the current user's ID for convenience.
  String? get _uid => _auth.currentUser?.uid;

  /// Fetches a live stream of all groups the current user is a member of.
  Stream<List<GroupModel>> getGroupsStream() {
    if (_uid == null) {
      return Stream.value([]);
    }
    return _firebaseProvider.getGroupsForUser(_uid!).map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    });
  }

  /// Fetches a live stream of all members for a specific group.
  Stream<List<MemberModel>> getMembersStream(String groupId) {
    return _firebaseProvider.getMembersStream(groupId).map((snapshot) {
      return snapshot.docs.map((doc) => MemberModel.fromFirestore(doc)).toList();
    });
  }

  /// Creates a new group and adds the current user as the first member (Admin)
  /// using an atomic batch write to ensure data consistency.
  Future<void> createGroup(String groupName, String groupType) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final newGroupRef = _firebaseProvider.groupsCollection.doc();
    // FIX: Corrected the typo from newGroup-Ref.id to newGroupRef.id
    final newMemberRef = _firebaseProvider.membersCollection(newGroupRef.id).doc(user.uid);

    final newGroup = GroupModel(
      id: newGroupRef.id,
      name: groupName,
      type: groupType,
      memberIds: [user.uid],
      createdAt: Timestamp.now(),
    );

    final creatorAsMember = MemberModel(
      id: user.uid,
      name: user.displayName ?? 'Admin',
      email: user.email,
      role: 'Admin',
    );

    final batch = _firebaseProvider.firestore.batch();
    batch.set(newGroupRef, newGroup.toFirestore());
    batch.set(newMemberRef, creatorAsMember.toFirestore());

    await batch.commit();
  }

  /// Finds a registered user by email and adds them to a group.
  Future<String> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    final userQuery = await _firebaseProvider.findUserByEmail(email);

    if (userQuery.docs.isEmpty) {
      throw 'User with email "$email" not found.';
    }

    final userDoc = userQuery.docs.first;
    final userId = userDoc.id;
    final userData = userDoc.data() as Map<String, dynamic>;
    final userName = userData['fullName'] ?? 'New Member';

    final isAlreadyMember = await _firebaseProvider.isUserMemberOfGroup(groupId, userId);
    if (isAlreadyMember) {
      throw '"$userName" is already in this group.';
    }

    final newMember = MemberModel(id: userId, name: userName, email: email);

    final batch = _firebaseProvider.firestore.batch();
    final newMemberRef = _firebaseProvider.membersCollection(groupId).doc(userId);
    final groupRef = _firebaseProvider.groupsCollection.doc(groupId);

    batch.set(newMemberRef, newMember.toFirestore());
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([userId])
    });

    await batch.commit();

    return '"$userName" was successfully added to the group!';
  }

  /// Adds a new non-registered member to a group by name only.
  Future<String> addPlaceholderMember({
    required String groupId,
    required String name,
  }) async {
    final newMemberRef = _firebaseProvider.membersCollection(groupId).doc();
    final newMember = MemberModel(
      id: newMemberRef.id,
      name: name,
      isPlaceholder: true,
    );

    final batch = _firebaseProvider.firestore.batch();
    final groupRef = _firebaseProvider.groupsCollection.doc(groupId);

    batch.set(newMemberRef, newMember.toFirestore());
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([newMember.id])
    });

    await batch.commit();

    return '"$name" was successfully added as a placeholder!';
  }

  /// Removes a member from a group using an atomic batch write.
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    try {
      final batch = _firebaseProvider.firestore.batch();
      final groupRef = _firebaseProvider.groupsCollection.doc(groupId);
      final memberRef = _firebaseProvider.membersCollection(groupId).doc(memberId);

      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([memberId])
      });
      batch.delete(memberRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove member.');
    }
  }

  /// Updates the name of a group document in Firestore.
  Future<void> updateGroupName({
    required String groupId,
    required String newName,
  }) async {
    try {
      final groupRef = _firebaseProvider.groupsCollection.doc(groupId);
      await groupRef.update({'name': newName});
    } catch (e) {
      throw Exception('Failed to update group name.');
    }
  }
}