import 'package:cloud_firestore/cloud_firestore.dart';

/*class PostModel {
  final String id;           // The document ID from Firestore
  final String content;      // "Sara is a great teacher..."
  final DateTime createdAt;  // Converted from Timestamp
  final String userId;       // Extracted ID from the Reference /User/1
  final String visibility;   // "public", "private", etc.

  PostModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.visibility,
  });

  /// Factory to create a PostModel from a Firestore DocumentSnapshot
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      // Extracting the User ID from the Reference /User/1
      userId: (data['user_id'] as DocumentReference).id,
      visibility: data['visibility'] ?? 'public',
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'created_at': Timestamp.fromDate(createdAt),
      // Re-constructing the User Reference
      'user_id': FirebaseFirestore.instance.doc('User/$userId'),
      'visibility': visibility,
    };
  }
}*/

class Post {
  final String username;
  final String title;
  final String content;
  final Timestamp timestamp;

  Post({
    required this.username,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      username: doc['username'],
      title: doc['title'],
      content: doc['content'],
      timestamp: doc['timestamp'],
    );
  }
}
