import 'package:cloud_firestore/cloud_firestore.dart'; 
//MODEL IMPORTS
import 'package:skillsync/models/comment_model.dart';
import 'package:skillsync/models/conversation_model.dart';
import 'package:skillsync/models/like_model.dart';
import 'package:skillsync/models/message_model.dart';
import 'package:skillsync/models/notification_model.dart';
import 'package:skillsync/models/post_model.dart';
import 'package:skillsync/models/skill_model.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/models/userskill_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. USER PROFILE LOGIC
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('User').doc(userId).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) {
    return _db.collection('User').doc(userId).update(data);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    var snapshot = await _db.collection('User')
        .where('username', isGreaterThanOrEqualTo: query)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // 2. SOCIAL LOGIC (POSTS, LIKES, COMMENTS)
  Future<void> createPost(PostModel post) {
    return _db.collection('Post').add(post.toMap());
  }

  Future<void> likePost(String userId, String postId) {
    final like = LikeModel(
      id: '', 
      createdAt: DateTime.now(),
      postId: postId,
      userId: userId,
    );
    return _db.collection('Like').add(like.toMap());
  }

  Future<bool> hasUserLikedPost(String userId, String postId) async {
    var snapshot = await _db.collection('Like')
        .where('user_id', isEqualTo: _db.doc('User/$userId'))
        .where('post_id', isEqualTo: _db.doc('Post/$postId'))
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> addComment(CommentModel comment) {
    return _db.collection('Comment').add(comment.toMap());
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _db
        .collection('Comment')
        .where('post_id', isEqualTo: _db.doc('Post/$postId'))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  // 3. MESSAGING AND MATCHES [REAL-TIME]
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db.collection('Message') 
        .where('conversation_id', isEqualTo: _db.doc('Conversation/$conversationId'))
        .orderBy('sent_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db.collection('Notification')
        .where('user_id', isEqualTo: _db.doc('User/$userId'))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // 4. USERSKILL LOGIC
  Future<void> addUserSkill(UserSkillModel userSkill) {
    return _db.collection('UserSkill').add(userSkill.toMap());
  }

  Future<List<UserSkillModel>> getUserSkills(String userId) async {
    var snapshot = await _db.collection('UserSkill')
        .where('user_id', isEqualTo: _db.doc('User/$userId'))
        .get();
    return snapshot.docs.map((doc) => UserSkillModel.fromFirestore(doc)).toList();
  }

} 