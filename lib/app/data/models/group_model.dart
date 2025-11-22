import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  String name;
  final String? coverPhotoUrl;
  final String type;
  final String? currency; // --- NEW: Essential for Multi-Currency/Travel Mode ---
  final List<String> memberIds;
  late final Map<String, double>? incomeSplitRatio;
  final Timestamp createdAt;
  final bool isLocal;

  GroupModel({
    required this.id,
    required this.name,
    this.coverPhotoUrl,
    required this.type,
    this.currency, // --- Add to Constructor ---
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
      // --- NEW: Safe parsing with default fallback ---
      currency: data['currency'] ?? 'USD',
      // ---------------------------------------------
      memberIds: memberIdsList,
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
      'currency': currency, // --- Add to Map ---
      'memberIds': memberIds,
      'incomeSplitRatio': incomeSplitRatio,
      'createdAt': createdAt,
    };
  }
}