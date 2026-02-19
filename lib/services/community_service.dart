import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityService {
  CommunityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('community_posts');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPosts() {
    return _posts.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createPost({
    required String text,
    required String authorId,
    required String authorName,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    await _posts.add({
      'text': clean,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'likedBy': <String>[],
    });
  }

  Future<void> deletePost({
    required String postId,
  }) async {
    // NOTE: This deletes only the post doc. Comments remain unless you also delete them.
    // For demo, this is fine. (Production: use Cloud Functions recursive delete.)
    await _posts.doc(postId).delete();
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = _posts.doc(postId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(postRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final List likedBy = (data['likedBy'] ?? []) as List;

      final bool alreadyLiked = likedBy.contains(userId);

      if (alreadyLiked) {
        tx.update(postRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        tx.update(postRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> addComment({
    required String postId,
    required String text,
    required String authorId,
    required String authorName,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    await _posts.doc(postId).collection('comments').add({
      'text': clean,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
