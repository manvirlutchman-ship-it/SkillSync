import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;          // The document ID from Firestore
  final DateTime createdAt; // Converted from Timestamp
  final String matchId;     // Extracted ID from the Reference /Match/1

  ConversationModel({
    required this.id,
    required this.createdAt,
    required this.matchId,
  });

  /// Factory to create a ConversationModel from a Firestore DocumentSnapshot
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConversationModel(
      id: doc.id,
      // Handling the Timestamp type
      createdAt: (data['created_at'] as Timestamp).toDate(),
      // Handling the Reference: We extract just the ID string "1" from "/Match/1"
      matchId: (data['match_id'] as DocumentReference).id,
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      // Converting the ID string back into an official Firestore Reference
      'match_id': FirebaseFirestore.instance.doc('Match/$matchId'),
    };
  }
}