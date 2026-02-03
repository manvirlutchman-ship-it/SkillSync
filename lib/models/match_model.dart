import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;           // The document ID from Firestore
  final DateTime createdAt;  // Converted from Timestamp
  final int matchScore;      // 100
  final String skillId;      // Extracted ID from the Reference /Skill/1
  final String status;       // "pending"
  final String user1Id;      // Extracted ID from the Reference /User/1
  final String user2Id;      // Extracted ID from the Reference /User/2

  MatchModel({
    required this.id,
    required this.createdAt,
    required this.matchScore,
    required this.skillId,
    required this.status,
    required this.user1Id,
    required this.user2Id,
  });

  /// Factory to create a MatchModel from a Firestore DocumentSnapshot
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      id: doc.id,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      // We use .toInt() to ensure it's an integer even if Firestore stores it as a double
      matchScore: (data['match_score'] ?? 0).toInt(),
      status: data['status'] ?? 'pending',
      // Extracting IDs from all the various References
      skillId: (data['skill_id'] as DocumentReference).id,
      user1Id: (data['user_1_id'] as DocumentReference).id,
      user2Id: (data['user_2_id'] as DocumentReference).id,
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      'match_score': matchScore,
      'status': status,
      // Re-constructing the References for the three different linked collections
      'skill_id': FirebaseFirestore.instance.doc('Skill/$skillId'),
      'user_1_id': FirebaseFirestore.instance.doc('User/$user1Id'),
      'user_2_id': FirebaseFirestore.instance.doc('User/$user2Id'),
    };
  }
}