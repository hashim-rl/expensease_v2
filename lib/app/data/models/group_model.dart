import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  String name;
  final String? coverPhotoUrl;
  final String type;
  final List<String> memberIds;
  final Map<String, double>? incomeSplitRatio;
  final Timestamp createdAt;
  final bool isLocal;

  GroupModel({
    required this.id,
    required this.name,
    this.coverPhotoUrl,
    required this.type,
    required this.memberIds,
    this.incomeSplitRatio,
    required this.createdAt,
    this.isLocal = false,
  });

  /// Creates a GroupModel from a Firestore document snapshot.
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final memberIdsData = data['memberIds'];
    final List<String> memberIdsList = memberIdsData is List
        ? List<String>.from(memberIdsData.map((item) => item.toString()))
        : [];

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      coverPhotoUrl: data['coverPhotoUrl'],
      type: data['type'] ?? 'General',
      memberIds: memberIdsList, // Use the safely parsed list
      incomeSplitRatio: data['incomeSplitRatio'] != null
          ? Map<String, double>.from(data['incomeSplitRatio'])
          : null,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isLocal: false,
    );
  }

  /// Converts the GroupModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'coverPhotoUrl': coverPhotoUrl,
      'type': type,
      'memberIds': memberIds,
      'incomeSplitRatio': incomeSplitRatio,
      'createdAt': createdAt,
    };
  }
}