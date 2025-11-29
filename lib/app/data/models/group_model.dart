import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  String name;
  final String? coverPhotoUrl;
  final String type;
  final String? currency;
  final List<String> memberIds;
  late final Map<String, double>? incomeSplitRatio;
  final Timestamp createdAt;
  final bool isLocal;

  GroupModel({
    required this.id,
    required this.name,
    this.coverPhotoUrl,
    required this.type,
    this.currency,
    required this.memberIds,
    this.incomeSplitRatio,
    required this.createdAt,
    this.isLocal = false,
  });
  /// Creates a GroupModel from a Firestore document snapshot.
  /// UPDATED: "Bulletproof" parsing to prevent 'subtype' crashes.
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    // 1. Safely cast the data to a Map, providing an empty map fallback.
    // This fixes the specific "subtype of Map<String, dynamic>" error.
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 2. Safely parse the member list
    final memberIdsData = data['memberIds'];
    final List<String> memberIdsList = memberIdsData is List
        ? List<String>.from(memberIdsData.map((item) => item.toString()))
        : [];

    // 3. Safely parse the split ratio, ensuring values are doubles
    Map<String, double>? safeSplitRatio;
    if (data['incomeSplitRatio'] is Map) {
      safeSplitRatio = (data['incomeSplitRatio'] as Map).map((key, value) {
        // Handle cases where the number might be stored as an int (e.g. 50) instead of double (50.0)
        final doubleVal = (value is num) ? value.toDouble() : 0.0;
        return MapEntry(key.toString(), doubleVal);
      });
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      coverPhotoUrl: data['coverPhotoUrl'],
      type: data['type'] ?? 'General',
      // --- Safe parsing with default fallback ---
      currency: data['currency'] ?? 'USD',
      // ---------------------------------------------
      memberIds: memberIdsList,
      incomeSplitRatio: safeSplitRatio,
      // Ensure createdAt is actually a Timestamp, otherwise fallback to now()
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
      isLocal: false,
    );
  }

  /// Converts the GroupModel to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id, // ✅ REQUIRED
      'name': name,
      'coverPhotoUrl': coverPhotoUrl,
      'type': type,
      'currency': currency,
      'memberIds': memberIds,
      'incomeSplitRatio': incomeSplitRatio,
      'createdAt': createdAt,
    };
  }
}