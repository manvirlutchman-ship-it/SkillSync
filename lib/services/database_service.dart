import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// MODEL IMPORTS
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

  // --- 1. USER PROFILE LOGIC ---

  Future<UserModel?> getUserProfile(String userId) async {
    print("!!! REQUESTING ID: '[$userId]' !!!");
    try {
      DocumentSnapshot doc = await _db
          .collection('User')
          .doc(userId.trim())
          .get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  // Matches Register Screen Logic
  Future<void> createUserProfile(String userId, String email) async {
    try {
      // Aligned with your UserModel.toMap() keys
      await _db.collection('User').doc(userId).set({
        'username': email,
        'first_name': '',
        'last_name': '',
        'user_bio': '',
        'profile_picture_url': '',
        'profile_banner_url': '',
        'date_of_birth': Timestamp.fromDate(
          DateTime(2000, 1, 1),
        ), // Default DOB
      });
    } catch (e) {
      print("Error creating user profile: $e");
      rethrow;
    }
  }

  // --- 2. USERSKILL LOGIC (Critical for Onboarding) ---

  Future<void> saveUserSkills({
    required String userId,
    required List<String> skills,
    required String type, // "teaching" or "learning"
  }) async {
    final batch = _db.batch();

    for (var skillId in skills) {
      DocumentReference docRef = _db.collection('UserSkill').doc();

      // Aligned with your UserSkillModel.toMap() keys
      batch.set(docRef, {
        'skill_id': _db.doc('Skill/$skillId'),
        'user_id': _db.doc('User/$userId'),
        'teaching_or_learning': type,
        'user_skill_rating': 1, // Default rating for new skills
      });
    }
    return batch.commit();
  }

  Future<List<UserSkillModel>> getUserSkills(String userId) async {
    try {
      print("!!! QUERYING SKILLS FOR USER: /User/$userId !!!");

      var snapshot = await _db
          .collection('UserSkill')
          .where('user_id', isEqualTo: _db.doc('User/$userId'))
          .get();

      print("!!! SKILLS FOUND: ${snapshot.docs.length} !!!");

      return snapshot.docs
          .map((doc) => UserSkillModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("!!! ERROR FETCHING SKILLS: $e !!!");
      return [];
    }
  }
  // --- 3. SOCIAL & MESSAGING (Model Integrated) ---

  Future<void> createPost(Post post) {
    return _db.collection('Post').add(post.toMap());
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db
        .collection('Message')
        .where(
          'conversation_id',
          isEqualTo: _db.doc('Conversation/$conversationId'),
        )
        .orderBy('sent_at', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => MessageModel.fromFirestore(doc)).toList(),
        );
  }

  // Add more methods as needed using the same .toMap() pattern
}
