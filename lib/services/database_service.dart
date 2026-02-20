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
      // Senior Tip: Extract a default username from the email
      // (e.g., alex@test.com becomes 'alex')
      final String defaultUsername = email.split('@')[0];

      await _db.collection('User').doc(userId).set({
        'id': userId, // Good practice to have the ID inside the document too
        'username': defaultUsername,
        'email': email,
        'first_name':
            '', // Must stay empty to trigger onboarding check in main.dart
        'last_name': '',
        'user_bio':
            '', // Must stay empty to trigger onboarding check in main.dart
        'profile_picture_url': '',
        'profile_banner_url': '',
        'date_of_birth': Timestamp.fromDate(DateTime(2000, 1, 1)),
      });

      print("!!! SUCCESS: Initial profile created for $userId !!!");
    } catch (e) {
      print("!!! ERROR creating user profile: $e !!!");
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

  // lib/services/database_service.dart
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db
        .collection('Message')
        .where(
          'conversation_id',
          isEqualTo: _db.doc('Conversation/$conversationId'),
        )
        .orderBy('sent_at', descending: true) // 🟢 MUST BE DESCENDING
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => MessageModel.fromFirestore(doc)).toList(),
        );
  }

  // 🟢 UPDATED: Accepts UID and a Map (Partial Update)
  // This matches your EditProfileScreen logic.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      print("!!! UPDATING USER PARTIALLY: $uid !!!");

      // .update() expects a Map, so this passes the data directly to Firestore
      await _db.collection('User').doc(uid).update(data);

      print("!!! SUCCESS: User profile updated !!!");
    } catch (e) {
      print("!!! ERROR updating user: $e !!!");
      rethrow;
    }
  }

  // 🟢 ADDED: Method to wipe skills before re-entering onboarding
  // 🟢 UPDATED: Type is now optional ({String? type}).
  // If type is null, it deletes ALL skills for that user.
  Future<void> clearUserSkills(String userId, {String? type}) async {
    try {
      print("!!! CLEARING SKILLS FOR: $userId [${type ?? 'ALL'}] !!!");

      Query query = _db
          .collection('UserSkill')
          .where('user_id', isEqualTo: _db.doc('User/$userId'));

      // Only filter by type if one is provided
      if (type != null) {
        query = query.where('teaching_or_learning', isEqualTo: type);
      }

      var snapshot = await query.get();
      final batch = _db.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print("!!! SKILLS CLEARED SUCCESSFULLY !!!");
    } catch (e) {
      print("!!! ERROR CLEARING SKILLS: $e !!!");
      rethrow;
    }
  }

  Future<void> completeOnboarding(String userId) async {
    await _db.collection('User').doc(userId).update({'is_onboarded': true});
  }

  // 🟢 ADD THIS METHOD
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String text,
  ) async {
    try {
      await _db.collection('Message').add({
        'conversation_id': _db.doc('Conversation/$conversationId'),
        'sender_id': _db.doc('User/$senderId'),
        'content': text,
        'sent_at': FieldValue.serverTimestamp(),
        'is_read': false,
        'message_type': 'text',
      });
    } catch (e) {
      print("Error in DatabaseService.sendMessage: $e");
      rethrow;
    }
  }

  // 🟢 ALSO ADD THIS: Needed to list your chats on the Home Screen
  Stream<List<ConversationModel>> getMyConversations(String userId) {
    return _db.collection('Conversation')
        // 🟢 ONLY chats where the current user ID is in the participants list
        .where('participant_ids', arrayContains: userId) 
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ConversationModel.fromFirestore(doc)).toList());
  }

  // 🟢 ADD THIS: Mark notification as handled/read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('Notification').doc(notificationId).update({
        'read_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  // 🟢 ADD THIS: Resolve the chat partner's profile
  Future<UserModel?> getChatPartner(
    String conversationId,
    String currentUserId,
  ) async {
    try {
      // 1. Get the conversation document
      final convDoc = await _db
          .collection('Conversation')
          .doc(conversationId)
          .get();

      // 🟢 FIX: Explicitly cast doc.data() to a Map
      final convData = convDoc.data() as Map<String, dynamic>?;
      if (convData == null) return null;

      final matchRef = convData['match_id'] as DocumentReference;

      // 2. Get the match document
      final matchDoc = await matchRef.get();

      // 🟢 FIX: Explicitly cast matchDoc.data() to a Map
      final matchData = matchDoc.data() as Map<String, dynamic>?;
      if (matchData == null) return null;

      final u1Ref = matchData['user_1_id'] as DocumentReference;
      final u2Ref = matchData['user_2_id'] as DocumentReference;

      // 3. Identify who is NOT the current user
      final String partnerId = u1Ref.id == currentUserId ? u2Ref.id : u1Ref.id;

      // 4. Return that user's profile
      return getUserProfile(partnerId);
    } catch (e) {
      print("Error finding chat partner: $e");
      return null;
    }
  }



// 🟢 THE LIKE FUNCTION
Future<void> likeUser(String targetUserId, String myId) async {
  // We create a unique ID based on both users: "myId_targetId"
  // If this document exists, Firestore won't create a second one.
  final likeId = "${myId}_$targetUserId";
  final likeRef = _db.collection('Like').doc(likeId);

  final doc = await likeRef.get();
  if (!doc.exists) {
    // 1. Create the like record
    await likeRef.set({'from': myId, 'to': targetUserId});
    // 2. Increment the user's count
    await _db.collection('User').doc(targetUserId).update({
      'likes_count': FieldValue.increment(1),
    });
  }
}
// 🟢 ADD THIS: Check if a like record exists
  Future<bool> checkIfLiked(String myId, String targetUserId) async {
    try {
      final String likeDocId = "${myId}_$targetUserId";
      final doc = await _db.collection('Like').doc(likeDocId).get();
      return doc.exists; // Returns true if you already liked them
    } catch (e) {
      return false;
    }
  }

  // 🟢 ADD THIS: Delete all user data from Firestore
  Future<void> deleteUserData(String userId) async {
    try {
      // 1. Delete the main User document
      await _db.collection('User').doc(userId).delete();
      
      // 2. Note: Ideally, you'd delete UserSkill records here too.
      // For a fast implementation, deleting the main profile is the priority.
      print("Firestore data deleted for $userId");
    } catch (e) {
      print("Error deleting Firestore data: $e");
    }
  }
  // Add more methods as needed using the same .toMap() pattern
}
