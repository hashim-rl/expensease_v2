import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/member_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/providers/firebase_provider.dart';

class GroupRepository {
  final FirebaseProvider _firebaseProvider;
  final FirebaseAuth _auth;

  GroupRepository({
    FirebaseProvider? provider,
    FirebaseAuth? auth,
  })  : _firebaseProvider = provider ?? FirebaseProvider(),
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<GroupModel>> getGroupsStream() {
    if (_uid == null) {
      return Stream.value([]);
    }
    return _firebaseProvider.getGroupsForUser(_uid!).map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    });
  }

  // NEW METHOD: Fetches a single, complete group document by its ID.
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final docSnapshot = await _firebaseProvider.groupsCollection.doc(groupId).get();
      if (docSnapshot.exists) {
        return GroupModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching group by ID: $e");
      return null;
    }
  }

  Stream<List<MemberModel>> getMembersStream(String groupId) {
    return _firebaseProvider.getMembersStream(groupId).map((snapshot) {
      return snapshot.docs.map((doc) => MemberModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<UserModel>> getMembersDetails(List<String> memberIds) async {
    debugPrint("--- Fetching Member Details ---");
    debugPrint("Attempting to find users with these IDs: $memberIds");

    if (memberIds.isEmpty) {
      debugPrint("Member IDs list is empty. Returning empty list.");
      return [];
    }
    try {
      final snapshot = await _firebaseProvider.firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      debugPrint("Firestore query returned ${snapshot.docs.length} documents.");
      if (snapshot.docs.isEmpty) {
        debugPrint("WARNING: No matching user documents found in the 'users' collection.");
      } else {
        final foundIds = snapshot.docs.map((d) => d.id).toList();
        debugPrint("Found user documents with these IDs: $foundIds");
      }
      debugPrint("-----------------------------");

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching member details: $e");
      return [];
    }
  }

  Future<void> createGroup(String groupName, String groupType) async {
    // ... existing code ...
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final userDocRef = _firebaseProvider.firestore.collection('users').doc(user.uid);
    final userDocSnapshot = await userDocRef.get();
    String userName;

    if (!userDocSnapshot.exists) {
      final selfHealedUser = UserModel(
        uid: user.uid,
        email: user.email ?? 'No Email',
        fullName: user.displayName ?? user.email ?? 'New User',
      );
      await userDocRef.set(selfHealedUser.toFirestore());
      userName = selfHealedUser.fullName;
    } else {
      userName = userDocSnapshot.data()?['fullName'] as String? ?? user.email ?? 'Member';
    }

    final newGroupRef = _firebaseProvider.groupsCollection.doc();
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
      name: userName,
      email: user.email,
      role: 'Admin',
    );

    final batch = _firebaseProvider.firestore.batch();
    batch.set(newGroupRef, newGroup.toFirestore());
    batch.set(newMemberRef, creatorAsMember.toFirestore());

    await batch.commit();
  }

  Future<String> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    // ... existing code ...
    final userQuery = await _firebaseProvider.findUserByEmail(email);

    if (userQuery.docs.isEmpty) {
      throw 'User with email "$email" not found.';
    }

    final userDoc = userQuery.docs.first;
    final userId = userDoc.id;
    final userData = userDoc.data() as Map<String, dynamic>;
    final userName = userData['fullName'] ?? 'New Member';

    final isAlreadyMember =
    await _firebaseProvider.isUserMemberOfGroup(groupId, userId);
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

  Future<String> addPlaceholderMember({
    required String groupId,
    required String name,
  }) async {
    // ... existing code ...
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

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    // ... existing code ...
    try {
      final batch = _firebaseProvider.firestore.batch();
      final groupRef = _firebaseProvider.groupsCollection.doc(groupId);
      final memberRef =
      _firebaseProvider.membersCollection(groupId).doc(memberId);

      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([memberId])
      });
      batch.delete(memberRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove member.');
    }
  }

  Future<void> updateGroupName({
    required String groupId,
    required String newName,
  }) async {
    // ... existing code ...
    try {
      final groupRef = _firebaseProvider.groupsCollection.doc(groupId);
      await groupRef.update({'name': newName});
    } catch (e) {
      throw Exception('Failed to update group name.');
    }
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String memberId,
    required String newRole,
  }) async {
    // ... existing code ...
    try {
      final memberRef =
      _firebaseProvider.membersCollection(groupId).doc(memberId);
      await memberRef.update({'role': newRole});
    } catch (e) {
      throw Exception('Failed to update member role.');
    }
  }
}
