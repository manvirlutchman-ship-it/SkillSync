import 'package:cloud_firestore/cloud_firestore.dart';

class UserSkillModel {
  final String id;                 // The document ID from Firestore
  final String skillId;            // Extracted ID from the Reference /Skill/1
  final String teachingOrLearning; // "learning" or "teaching"
  final String userId;             // Extracted ID from the Reference /User/1
  final int userSkillRating;       // 5

  UserSkillModel({
    required this.id,
    required this.skillId,
    required this.teachingOrLearning,
    required this.userId,
    required this.userSkillRating,
  });

  /// Factory to create a UserSkillModel from a Firestore DocumentSnapshot
  factory UserSkillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Smarter ID extraction
    String extractedSkillId = 'Unknown Skill';
    if (data['skill_id'] is DocumentReference) {
      extractedSkillId = (data['skill_id'] as DocumentReference).id;
    } else if (data['skill_id'] is String) {
      extractedSkillId = data['skill_id'];
    }

    return UserSkillModel(
      id: doc.id,
      skillId: extractedSkillId,
      teachingOrLearning: data['teaching_or_learning'] ?? 'learning',
      userId: data['user_id'] is DocumentReference 
          ? (data['user_id'] as DocumentReference).id 
          : '',
      userSkillRating: (data['user_skill_rating'] ?? 0).toInt(),
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'skill_id': FirebaseFirestore.instance.doc('Skill/$skillId'),
      'teaching_or_learning': teachingOrLearning,
      'user_id': FirebaseFirestore.instance.doc('User/$userId'),
      'user_skill_rating': userSkillRating,
    };
  }
}