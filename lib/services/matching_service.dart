import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';

class MatchingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // --- 1. FIND COMPATIBLE USERS (Excluding existing matches) ---
  Future<List<UserModel>> findMatchesForUser(String currentUserId, {bool findTeachers = true}) async {
    try {
      final String myRole = findTeachers ? 'learning' : 'teaching';
      final String targetRole = findTeachers ? 'teaching' : 'learning';

      // 1. Get IDs of users I already have a Match record with
      final existingMatches1 = await _db.collection('Match')
          .where('user_1_id', isEqualTo: _db.doc('User/$currentUserId')).get();
      final existingMatches2 = await _db.collection('Match')
          .where('user_2_id', isEqualTo: _db.doc('User/$currentUserId')).get();

      Set<String> excludedUserIds = {currentUserId};
      for (var doc in existingMatches1.docs) {
        excludedUserIds.add((doc.data()['user_2_id'] as DocumentReference).id);
      }
      for (var doc in existingMatches2.docs) {
        excludedUserIds.add((doc.data()['user_1_id'] as DocumentReference).id);
      }

      // 2. Get MY skills for the specific role
      final mySkillsQuery = await _db.collection('UserSkill')
          .where('user_id', isEqualTo: _db.doc('User/$currentUserId'))
          .where('teaching_or_learning', isEqualTo: myRole).get();

      if (mySkillsQuery.docs.isEmpty) return [];

      List<dynamic> targetSkillRefs = mySkillsQuery.docs.map((doc) => doc.data()['skill_id']).toList();

      // 3. Find OTHERS with those skills
      final matchesQuery = await _db.collection('UserSkill')
          .where('skill_id', whereIn: targetSkillRefs.take(30).toList())
          .where('teaching_or_learning', isEqualTo: targetRole).get();

      // 4. Deduplicate and filter out excluded IDs
      Set<String> matchedUserIds = {};
      for (var doc in matchesQuery.docs) {
        final id = (doc.data()['user_id'] as DocumentReference).id;
        if (!excludedUserIds.contains(id)) matchedUserIds.add(id);
      }

      // 5. Fetch full UserModels
      final userFutures = matchedUserIds.map((id) => _dbService.getUserProfile(id));
      final results = await Future.wait(userFutures);
      return results.whereType<UserModel>().toList();
    } catch (e) {
      debugPrint("Error in findMatches: $e");
      return [];
    }
  }

  // --- 🟢 2. THE MISSING METHOD: FIND OVERLAPPING SKILL ---
  Future<String?> getCommonSkill(String myId, String theirId, bool lookingForTeacher) async {
    try {
      String myRole = lookingForTeacher ? 'learning' : 'teaching';
      String theirRole = lookingForTeacher ? 'teaching' : 'learning';

      // Get my relevant skills
      var mySkillsSnap = await _db.collection('UserSkill')
          .where('user_id', isEqualTo: _db.doc('User/$myId'))
          .where('teaching_or_learning', isEqualTo: myRole)
          .get();

      Set<String> mySkillIds = mySkillsSnap.docs.map((doc) {
        final ref = doc.data()['skill_id'];
        return ref is DocumentReference ? ref.id : ref.toString();
      }).toSet();

      // Get their relevant skills
      var theirSkillsSnap = await _db.collection('UserSkill')
          .where('user_id', isEqualTo: _db.doc('User/$theirId'))
          .where('teaching_or_learning', isEqualTo: theirRole)
          .get();
      
      // Return the ID of the first skill found in both sets
      for (var doc in theirSkillsSnap.docs) {
        final ref = doc.data()['skill_id'];
        String id = ref is DocumentReference ? ref.id : ref.toString();
        if (mySkillIds.contains(id)) return id;
      }
      return null;
    } catch (e) {
      debugPrint("Error in getCommonSkill: $e");
      return null;
    }
  }

  // --- 3. CREATE INITIAL MATCH REQUEST + NOTIFICATION ---
  Future<void> createMatchRequest({
    required String currentUserId,
    required String targetUserId,
    required String skillId,
  }) async {
    // Create the Match document as 'pending'
    final matchRef = await _db.collection('Match').add({
      'created_at': FieldValue.serverTimestamp(),
      'match_score': 100,
      'status': 'pending',
      'skill_id': _db.doc('Skill/$skillId'),
      'user_1_id': _db.doc('User/$currentUserId'),
      'user_2_id': _db.doc('User/$targetUserId'),
    });

    // Create the Notification for the recipient
    await _db.collection('Notification').add({
      'user_id': _db.doc('User/$targetUserId'),
      'type': 'match',
      'reference_id': matchRef, // Reference to the Match doc
      'created_at': FieldValue.serverTimestamp(),
      'read_at': null,
    });
  }

  // --- 4. FINALIZE MATCH (HANDSHAKE) ---
  Future<void> acceptExistingMatch(String matchId) async {
    // 1. Get the match details to find the two users
    final matchDoc = await _db.collection('Match').doc(matchId).get();
    final u1 = (matchDoc.data() as Map<String, dynamic>)['user_1_id'] as DocumentReference;
    final u2 = (matchDoc.data() as Map<String, dynamic>)['user_2_id'] as DocumentReference;

    // 2. Mark as matched
    await _db.collection('Match').doc(matchId).update({'status': 'matched'});

    // 3. 🟢 THE FIX: Add participant_ids array so we can filter chats
    await _db.collection('Conversation').add({
      'match_id': _db.doc('Match/$matchId'),
      'participant_ids': [u1.id, u2.id], // 🟢 Store both IDs in this array
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}