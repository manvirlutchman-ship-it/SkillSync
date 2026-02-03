import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final DateTime createdAt;
  final DateTime? readAt;      // Nullable because a new notification hasn't been read yet
  final String referenceId;   // Extracted ID (e.g., "1" from /Post/1)
  final String referencePath; // The collection name (e.g., "Post" from /Post/1)
  final String type;          // "comment", "match", etc.
  final String userId;        // Extracted ID from /User/1

  NotificationModel({
    required this.id,
    required this.createdAt,
    this.readAt,
    required this.referenceId,
    required this.referencePath,
    required this.type,
    required this.userId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ref = data['reference_id'] as DocumentReference;

    return NotificationModel(
      id: doc.id,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      // Handle read_at safely in case it's null in the future
      readAt: data['read_at'] != null ? (data['read_at'] as Timestamp).toDate() : null,
      // Extracting both the ID and the collection name from the reference
      referenceId: ref.id,
      referencePath: ref.path.split('/').first, 
      type: data['type'] ?? '',
      userId: (data['user_id'] as DocumentReference).id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      'read_at': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'type': type,
      // Re-build the reference using the stored path and ID
      'reference_id': FirebaseFirestore.instance.doc('$referencePath/$referenceId'),
      'user_id': FirebaseFirestore.instance.doc('User/$userId'),
    };
  }
}