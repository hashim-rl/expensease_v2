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
      debugPrint(
          "--- REPO TRACE: No user logged in for getGroupsStream. Returning empty stream.");
      // --- FIX 1: Explicit Type Cast ---
      return Stream.value(<GroupModel>[]);
    }
    return _firebaseProvider.getGroupsForUser(_uid!).map((snapshot) {
      debugPrint(
          "--- REPO TRACE: Fetched ${snapshot.docs.length} groups for user $_uid.");
      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    });
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      debugPrint("--- REPO TRACE: Attempting to fetch group with ID: $groupId");
      final docSnapshot =
      await _firebaseProvider.groupsCollection.doc(groupId).get();
      if (docSnapshot.exists) {
        debugPrint("--- REPO TRACE: Found group with ID: $groupId");
        return GroupModel.fromFirestore(docSnapshot);
      }
      debugPrint("--- REPO TRACE: Group with ID: $groupId not found.");
      return null;
    } catch (e) {
      debugPrint("!!!! ERROR fetching group by ID: $e");
      return null;
    }
  }

  // --- FIX 2: Added getGroupStream with correct type ---
  Stream<GroupModel?> getGroupStream(String groupId) {
    if (groupId.isEmpty) {
      return Stream<GroupModel?>.value(null);
    }
    debugPrint("--- REPO TRACE: Subscribing to group stream for: $groupId");
    return _firebaseProvider.groupsCollection
        .doc(groupId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      debugPrint("--- REPO TRACE: Group $groupId not found in stream.");
      return null;
    });
  }

  Stream<List<MemberModel>> getMembersStream(String groupId) {
    debugPrint("--- REPO TRACE: Getting member stream for group: $groupId");
    return _firebaseProvider.getMembersStream(groupId).map((snapshot) {
      debugPrint(
          "--- REPO TRACE: Stream snapshot for members received: ${snapshot.docs.length} docs.");
      return snapshot.docs
          .map((doc) => MemberModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<UserModel>> getMembersDetails(List<String> memberIds) async {
    debugPrint("--- REPO TRACE: Inside getMembersDetails ---");
    debugPrint(
        "--- REPO TRACE: Attempting to fetch details for these IDs: $memberIds");

    if (memberIds.isEmpty) {
      debugPrint(
          "--- REPO TRACE: Provided memberIds list is empty. Returning empty list.");
      return [];
    }

    try {
      final List<UserModel> memberDetails = [];
      for (final memberId in memberIds) {
        if (memberId.trim().isEmpty) {
          debugPrint("--- REPO TRACE: Skipping empty memberId in list.");
          continue;
        }
        final docSnapshot = await _firebaseProvider.firestore
            .collection('users')
            .doc(memberId)
            .get();
        if (docSnapshot.exists) {
          memberDetails.add(UserModel.fromFirestore(docSnapshot));
          debugPrint(
              "--- REPO TRACE: Added user: ${memberDetails.last.nickname} (ID: $memberId)");
        } else {
          debugPrint(
              "--- REPO TRACE: WARNING! No user document found for ID: $memberId. This indicates data inconsistency.");
          memberDetails.add(UserModel(
              uid: memberId,
              email: 'missing@example.com',
              fullName: 'Missing User Data',
              nickname: 'Missing User'));
        }
      }
      debugPrint(
          "--- REPO TRACE: Successfully processed details for ${memberDetails.length} members.");
      final names =
      memberDetails.map((m) => '${m.nickname} (${m.uid})').toList();
      debugPrint("--- REPO TRACE: Final list of members and their IDs: $names");
      return memberDetails;
    } catch (e) {
      debugPrint("!!!! FATAL ERROR in getMembersDetails: $e");
      return [];
    }
  }

  // --- UPDATED METHOD: FIXES GROUP CREATION BUG ---
  Future<void> createGroup(String groupName, String groupType,
      {String currency = 'USD'}) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
          "--- REPO TRACE: User not logged in when trying to create group.");
      throw Exception("User not logged in");
    }

    // 1. Prepare references
    final newGroupRef = _firebaseProvider.groupsCollection.doc();

    // 2. Create the Group Model
    final newGroup = GroupModel(
      id: newGroupRef.id,
      name: groupName,
      type: groupType,
      currency: currency,
      memberIds: [user.uid], // This is what the app uses to find the group
      createdAt: Timestamp.now(),
    );

    // 3. Prepare the Admin Member object
    // Using a safe fallback for the name
    final creatorName =
        user.displayName ?? user.email?.split('@')[0] ?? 'Admin';
    final creatorAsMember = MemberModel(
      id: user.uid,
      name: creatorName,
      email: user.email,
      role: 'Admin',
    );

    // 4. Execute Batch (Atomic Operation)
    final batch = _firebaseProvider.firestore.batch();

    // Set Group Data
    batch.set(newGroupRef, newGroup.toFirestore());

    // Set Member Data (in subcollection)
    final newMemberRef =
    _firebaseProvider.membersCollection(newGroupRef.id).doc(user.uid);
    batch.set(newMemberRef, creatorAsMember.toFirestore());

    // --- REMOVED: The risky batch.update on userDocRef ---
    // We removed the line that tried to update 'users/{uid}' because it was
    // causing crashes if the 'groups' map didn't exist, and is not needed
    // for your current read strategy (arrayContains).

    await batch.commit();
    debugPrint(
        "--- REPO TRACE: Group '$groupName' created successfully with ID: ${newGroupRef.id} and Currency: $currency");
  }

  Future<void> updateGroupSettings(
      String groupId, Map<String, dynamic> settings) async {
    try {
      debugPrint(
          "--- REPO TRACE: Updating settings for group ID: $groupId with fields: ${settings.keys}");
      await _firebaseProvider.groupsCollection.doc(groupId).update(settings);
      debugPrint("--- REPO TRACE: Group settings updated successfully.");
    } catch (e) {
      debugPrint("!!!! ERROR updating group settings for '$groupId': $e");
      throw Exception('Failed to update group settings.');
    }
  }

  Future<String> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    debugPrint(
        "--- REPO TRACE: Adding member by email '$email' to group '$groupId'");
    final userQuery = await _firebaseProvider.findUserByEmail(email);
    if (userQuery.docs.isEmpty) {
      debugPrint("--- REPO TRACE: User with email '$email' not found.");
      throw 'User with email "$email" not found.';
    }

    final userDoc = userQuery.docs.first;
    final userId = userDoc.id;
    final userData = userDoc.data();
    final userName =
        userData['nickname'] ?? userData['fullName'] ?? 'New Member';

    final isAlreadyMember =
    await _firebaseProvider.isUserMemberOfGroup(groupId, userId);
    if (isAlreadyMember) {
      debugPrint(
          "--- REPO TRACE: '$userName' is already a member of group '$groupId'.");
      throw '"$userName" is already in this group.';
    }

    final newMember = MemberModel(id: userId, name: userName, email: email);

    final batch = _firebaseProvider.firestore.batch();
    final newMemberRef =
    _firebaseProvider.membersCollection(groupId).doc(userId);
    final groupRef = _firebaseProvider.groupsCollection.doc(groupId);

    batch.set(newMemberRef, newMember.toFirestore());
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([userId])
    });

    await batch.commit();
    debugPrint(
        "--- REPO TRACE: '$userName' (ID: $userId) successfully added to group '$groupId' by email.");
    return '"$userName" was successfully added to the group!';
  }

  Future<String> addPlaceholderMember({
    required String groupId,
    required String name,
  }) async {
    debugPrint(
        "--- REPO TRACE: Adding placeholder member '$name' to group '$groupId'");
    final newMemberRef = _firebaseProvider.membersCollection(groupId).doc();
    final newMember =
    MemberModel(id: newMemberRef.id, name: name, isPlaceholder: true);

    final batch = _firebaseProvider.firestore.batch();
    final groupRef = _firebaseProvider.groupsCollection.doc(groupId);

    batch.set(newMemberRef, newMember.toFirestore());
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([newMember.id])
    });

    await batch.commit();
    debugPrint(
        "--- REPO TRACE: Placeholder member '$name' (ID: ${newMember.id}) successfully added to group '$groupId'.");
    return '"$name" was successfully added as a placeholder!';
  }

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
    bool isGuest = false,
  }) async {
    try {
      debugPrint(
          "--- REPO TRACE: Removing member '$memberId' from group '$groupId'");
      final batch = _firebaseProvider.firestore.batch();
      final groupRef = _firebaseProvider.groupsCollection.doc(groupId);
      final memberRef =
      _firebaseProvider.membersCollection(groupId).doc(memberId);
      final userRef =
      _firebaseProvider.firestore.collection('users').doc(memberId);

      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([memberId])
      });
      batch.delete(memberRef);

      if (!isGuest) {
        final userSnapshot = await userRef.get();
        if (userSnapshot.exists) {
          batch.update(userRef, {'groups.$groupId': FieldValue.delete()});
        } else {
          debugPrint(
              "--- REPO TRACE: User document for member '$memberId' not found, skipping groups update.");
        }
      }

      await batch.commit();
      debugPrint(
          "--- REPO TRACE: Member '$memberId' successfully removed from group '$groupId'.");
    } catch (e) {
      debugPrint(
          "!!!! ERROR removing member '$memberId' from group '$groupId': $e");
      throw Exception('Failed to remove member.');
    }
  }

  Future<void> updateGroupName({
    required String groupId,
    required String newName,
  }) async {
    try {
      debugPrint(
          "--- REPO TRACE: Updating group name for '$groupId' to '$newName'.");
      await _firebaseProvider.groupsCollection
          .doc(groupId)
          .update({'name': newName});
      debugPrint("--- REPO TRACE: Group name updated successfully.");
    } catch (e) {
      debugPrint("!!!! ERROR updating group name for '$groupId': $e");
      throw Exception('Failed to update group name.');
    }
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String memberId,
    required String newRole,
  }) async {
    try {
      debugPrint(
          "--- REPO TRACE: Updating role for member '$memberId' in group '$groupId' to '$newRole'.");
      await _firebaseProvider
          .membersCollection(groupId)
          .doc(memberId)
          .update({'role': newRole});
      debugPrint("--- REPO TRACE: Member role updated successfully.");
    } catch (e) {
      debugPrint("!!!! ERROR updating member role for '$memberId': $e");
      throw Exception('Failed to update member role.');
    }
  }
}