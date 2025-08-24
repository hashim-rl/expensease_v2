import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  String name; // Made this non-final to allow editing
  final String? coverPhotoUrl;
  final String type; // FIX 1: Renamed from groupType
  final List<String> memberIds;
  final Map<String, double>? incomeSplitRatio;
  final Timestamp createdAt; // FIX 2: Added createdAt field

  GroupModel({
    required this.id,
    required this.name,
    this.coverPhotoUrl,
    required this.type,
    required this.memberIds,
    this.incomeSplitRatio,
    required this.createdAt,
  });

  /// Creates a GroupModel from a Firestore document snapshot.
  factory GroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) { // FIX 3: Renamed
    final data = doc.data()!;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      coverPhotoUrl: data['coverPhotoUrl'],
      type: data['type'] ?? 'Flatmates', // Updated to 'type'
      memberIds: List<String>.from(data['memberIds'] ?? []),
      incomeSplitRatio: data['incomeSplitRatio'] != null
          ? Map<String, double>.from(data['incomeSplitRatio'])
          : null,
      createdAt: data['createdAt'] ?? Timestamp.now(), // Added createdAt
    );
  }

  /// Converts the GroupModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() { // FIX 3: Renamed
    return {
      'name': name,
      'coverPhotoUrl': coverPhotoUrl,
      'type': type, // Updated to 'type'
      'memberIds': memberIds,
      'incomeSplitRatio': incomeSplitRatio,
      'createdAt': createdAt, // Added createdAt
    };
  }
}