import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String id;          // The document ID from Firestore
  final DateTime createdAt; // Converted from Timestamp
  final String postId;     // Extracted ID from the Reference /Post/1
  final String userId;     // Extracted ID from the Reference /User/2

  LikeModel({
    required this.id,
    required this.createdAt,
    required this.postId,
    required this.userId,
  });

  /// Factory to create a LikeModel from a Firestore DocumentSnapshot
  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LikeModel(
      id: doc.id,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      // Extracting IDs from the References
      postId: (data['post_id'] as DocumentReference).id,
      userId: (data['user_id'] as DocumentReference).id,
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      // Re-constructing the References for the database
      'post_id': FirebaseFirestore.instance.doc('Post/$postId'),
      'user_id': FirebaseFirestore.instance.doc('User/$userId'),
    };
  }
}