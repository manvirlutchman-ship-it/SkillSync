import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final String postId;
  final String userId;

  CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.postId,
    required this.userId,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      postId: (data['post_id'] as DocumentReference).id,
      userId: (data['user_id'] as DocumentReference).id,
    );
  }

  // CHANGED THIS NAME TO toMap to match your DatabaseService
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'created_at': Timestamp.fromDate(createdAt),
      'post_id': FirebaseFirestore.instance.doc('Post/$postId'),
      'user_id': FirebaseFirestore.instance.doc('User/$userId'),
    };
  }
}